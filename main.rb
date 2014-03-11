require 'rubygems'
require 'sinatra'
require 'active_record'
require 'haml'
require 'json'

class BlogGem < Sinatra::Base
  def initialize(app = nil)
    super(app)
    @setting = BlogGem.load_json("settings.json")
    @theme = BlogGem.set_theme!(@setting["theme"])

    Encoding.default_external = 'utf-8'
    ActiveRecord::Base.default_timezone = :local
    ActiveRecord::Base.establish_connection(
      "adapter" => "sqlite3",
      "database" => "./page.db"
      )
  end

  class << self
    def load_json(filename)
      File.open(filename, "r") do |f|
        JSON.load(f)
      end
    end

    def set_theme!(theme_path)
      theme_path = File.join("views", theme_path)

      BlogGem.set(:views, theme_path)

      static_url = Array.new
      Dir.open(theme_path).each do |dir|
        next if dir == "."
        next if dir == ".."
        static_url << "/#{dir}"  if File.directory?( File.join(theme_path, dir) )
      end
      BlogGem.use(Rack::Static, :urls => static_url, :root => theme_path)

      return load_json( File.join(theme_path, "scheme.json") )
    end
  end


  helpers do
    def do_template(template, options = {}, locals = {}, &block)
      begin
        public_send(@theme["template"], template, options, locals, &block)
      rescue
        raise "template error"
      end
    end

    def console_haml(template, options = {}, locals = {}, &block)
      haml_template    = :"/views/Console/#{template.to_s}"
      options[:layout] = :"/views/Console/layout"
      render(:haml, haml_template, options, locals, &block)
    end

    def format_elements(array)
      formated = Array.new
      array.each do |element|
        f, pre = element.format()
        @pre_active = @pre_active || pre
        formated << f
      end
      return formated
    end

    def link_to(href, name)
      "<a href='#{href}'>#{name}</a>"
    end

    def set_prev_and_next_link!(elements, pagination, standard_link)
      if pagination == 1 then
        @previousClass = 'disabled'
      else
        @previousLink = to("#{standard_link}#{pagination-1}/")
      end

      if elements.size <= 5 then
        @nextClass = 'disabled'
      else
        @nextLink = to("#{standard_link}#{pagination+1}/")
        elements.delete_at(5)
      end
    end

    def show_page(pagination)
      entries = Entry.order('id desc').limit(6).offset((pagination - 1) * 5)
      if entries.size > 0 then
        set_prev_and_next_link!(entries, pagination, "/page/")
        @entry = format_elements(entries)
        do_template :blogPages
      else
        raise Sinatra::NotFound
      end
    end

    def show_category_page(category, pagination)
      category_info = Category.where(:name => category)
      raise Sinatra::NotFound  unless category_info.size == 1

      of = (pagination-1)*5
      wh = {:category_id => category_info[0].id}
      searcher = Searcher.order("id desc").limit(6).offset(of).where(wh)
      raise Sinatra::NotFound  unless searcher.size > 0

      set_prev_and_next_link!(searcher, pagination, "/category/#{category}/")

      @entry = Array.new
      searcher.each do |s|
        e, pre = Entry.find(s.entry_id).format()
        @entry << e
        @pre_active = @pre_active || pre
      end

      @head_title = "<small>カテゴリ</small> #{category}"
      do_template :blogPages
    end

    def nil_or_blank?(target)
      return target == nil || target == ''
    end

    #Linux only
    def send_mail(body)
      title = 'Contact from Sinji\'s view'
      to = 'contact@sinjis-view.mydns.jp'
      system("echo \"#{body}\" | mail -s \"#{title}\" #{to}")
    end

    def create_form_buttons()
      buttons = Array.new
      buttons << {:type  => 'submit',
                  :value => 'post',
                  :class => 'btn btn-primary',
                  :target => '',
                  :onClick => "post_preview(this.form, './post', '')",
                  :name => 'Post'}
      buttons << {:type  => 'submit',
                  :value => 'save',
                  :class => 'btn btn-default',
                  :target => '',
                  :onClick => "grand_parent(this).action = './post'",
                  :name => 'Save'}
      buttons << {:type  => 'submit',
                  :value => 'preview',
                  :class => 'btn btn-default',
                  :target => '_blank',
                  :onClick => "post_preview(this.form, './preview', '_blank')",
                  :name => 'Preview'}
      buttons << {:type  => 'submit',
                  :value => 'delete',
                  :submit => 'delete',
                  :class => 'btn btn-danger',
                  :target => '',
                  :onClick => "post_preview(this.form, './delete', '')",
                  :style => 'float: right;',
                  :name => 'Delete'}
      return buttons
    end
  end

  before do
    @year          = Time.now.year
    @since         = @setting["since"]
    @copyright     = @setting["copyright"]
    @blog_title    = @setting["blog title"]
    @sub_title     = @setting["sub title"]
    @newerEntry    = Entry.order("id desc").limit(5)
    @category      = Category.where(nil)
    @newerComment  = Comment.order("id desc").where(:allow => 1).limit(5)
  end

  before /^\/console\// do
    @wait_comment_num = Comment.where(:allow => 0).count
  end

  get '/' do
    @page_title = 'Blog - Sinji\'s View'
    show_page 1
  end

  get '/page/:page/' do |p|
    @page_title  = 'Blog - Sinji\'s View'
    pagination   = p.to_i

    redirect to '/' if pagination < 2

    show_page pagination
  end

  get '/entry/:id/' do |i|
    id = i.to_i
    redirect to '/' if id <= 0

    begin
      @status = params[:status]
      @comment = format_elements(Comment.where(:entry_id => id, :allow => 1))
      @commentNum = @comment.size

      @entry, @pre_active = Entry.find(id).format(false)
      @page_title = @entry.title + ' - Sinji\'s View'

      do_template :blog_entry
    rescue
      raise Sinatra::NotFound
    end
  end

  post '/entry/:id/send-comment' do |i|
    id   = i.to_i
    name = params[:name]
    body = params[:body]
    if Entry.find(id) && ! nil_or_blank?(name) && ! nil_or_blank?(body) then
      Comment.create(:entry_id => id, :name => name, :body => body)
      redirect to ("/entry/#{id}/?status=success") unless @theme["use Ajax"]
    else
      redirect to ("/entry/#{id}/?status=error") unless @theme["use Ajax"]
    end
  end

  get '/category/:category/' do |category|
    @page_title = 'カテゴリ:' + category + ' - Sinji\'s View'
    show_category_page(category, 1)
  end

  get '/category/:category/:pagination/' do |category, p|
    @page_title = 'カテゴリ:' + category + ' - Sinji\'s View'
    pagination = p.to_i

    redirect to "/category/#{category}" if pagination < 2

    show_category_page(category, pagination)
  end

  get '/contact/' do
    @status = params[:status]
    @page_title = 'Contact - Sinji\'s View'
    do_template :contact
  end

  post '/contact/send-mail' do
    begin
      name    = escape_html(params[:name])
      address = escape_html(params[:address])
      body    = escape_html(params[:body])
      send_mail("#{name}\n#{address}\n\n#{body}")
      redirect to ('/contact/?status=success') unless @theme["use Ajax"]
    rescue
      redirect to ('/contact/?status=error') unless @theme["use Ajax"]
    end
  end

  # console
  get '/console/' do
    console_haml :blog_console
  end

  get '/console/settings/' do
    console_haml :setting
  end

  post "/console/settings/save" do
    ary = [ params[:item], params[:value] ].transpose
    @setting = Hash[*ary.flatten]

    bloggem.set_theme!(@setting['theme'])
  end

  post '/console/settings/new' do
    @setting.store(params[:item], params[:value])
    redirect to '/console/settings/'
  end

  get '/console/entry/' do
    @entry = Entry.order("id desc").where(nil)
    console_haml :element_list
  end

  get '/console/entry/:id/' do |id|
    key = id.to_i
    if key > 0 then
      entry = Entry.find(key)
      @title = entry.title
      @body = entry.body
      @entryCategory = entry.category.split(",")
    elsif id == 'new' then
      @entryCategory = Array.new
    else
      redirect to '/console/'
    end
    @category = Category.where(nil)
    console_haml :edit
  end

  post '/console/entry/:id/post' do |id|
    key = id.to_i
    if key > 0 then
      entry = Entry.find(key)
    elsif id == 'new' then
      entry = Entry.new
    else
      redirect to '/console/entry/'
    end
    entry.title = params[:title]
    entry.body  = params[:entry]
    entry.category = ''
    if params[:category] != nil then
      params[:category].each do |c|
        Searcher.creare(:entry_id => entry.id, :category_id => c)
      end
      entry.category = params[:category].join(", ")
    end
    entry.save
    redirect to '/console/entry/'
  end

  post '/console/entry/:id/delete' do |id|
    if id.to_i > 0 then
      entry = Entry.find(key)
      Comment.where(:entry_id => entry.id).each do |comment|
        comment.destroy
      end
      entry.destroy
    end
    redirect to '/console/entry/'
  end

  post '/console/entry/:id/preview' do |id|
    entry = Entry.new
    entry.title = params[:title]
    entry.body  = params[:entry]
    entry.category = params[:category].join(",")
    entry.created_at = Time.now
    @entry, @pre_active = entry.format(false)
    @comment = Array.new
    do_template :blog_entry
  end

  get '/console/category/' do
    @category = Category.where(nil)
    console_haml :category_edit
  end

  post '/console/category/save' do
    @category = Category.where(nil)
    @category.each do |c|
      edited = params[:category].shift
      if edited == "" then
        c.destroy
      else
        c.name = edited
        c.save
      end
    end
    redirect to '/console/category/'
  end

  post '/console/category/new' do
    category = Category.create(:name => params[:category])
    redirect to '/console/category/'
  end

  get '/console/comment/' do
    @comment = Comment.where(nil)
    console_haml :console_comment
  end

  get '/console/comment/allow' do
    begin
      comment = Comment.find(params[:id].to_i)
      entry = Entry.find(comment.entry_id)
      comment.allow = 1
      comment.save
      entry.comment_num += 1
      entry.save
    end
  end

  get '/console/comment/deny' do
    begin
      comment = Comment.find(params[:id].to_i)
      entry = Entry.find(comment.entry_id)
      comment.allow = 0
      comment.save
      if entry.comment_num > 0 then
        entry.comment_num -= 1
        entry.save
      end
    end
  end
end


class Entry < ActiveRecord::Base
  def date()
    fdate = DateTime.parse("#{created_at}")
    return fdate.strftime("%Y/%m/%d %H:%M")
  end

  def format(split_body=true)
    formated = FormatedEntry.new
    use_pre = false

    formated.id = id

    formated.title = title

    if split_body == true then
      _body = body.split('[read_more]')
      formated.body = "#{_body[0]}".gsub(/(\r\n|\r|\n)/, '<br />')
      formated.read_more = _body.size >= 2
    else
      enter = /(\r\n|\r|\n)/
      formated.body = body.gsub('[read_more]', '').gsub(enter, '<br />')
    end

    #escape html inside the pre tag
    pre_pattarn = /<pre(?:.|\n)*?pre>/
    body_without_pre = formated.body.split(pre_pattarn, -1)
    pre_tag = formated.body.scan(pre_pattarn)
    use_pre = true if pre_tag.size > 0
    formated.body = body_without_pre.shift
    body_without_pre.length.times do
      pre = pre_tag.shift
      pre.gsub!("<br />", "\n")
      inside_tag = pre[/>(?:.|\n)+</]
      if inside_tag == nil then
        inside_tag = ""
      end
      inside_tag = inside_tag[1, inside_tag.length - 2]
      pre.gsub!(/>(?:.|\n)+</, ">#{Rack::Utils.escape_html(inside_tag)}<")
      formated.body = formated.body + pre + body_without_pre.shift
    end

    _category_num = category.split(',')
    _category_num.each do |c|
      begin
        _category =  Category.find(c.to_i)
        formated.category << _category.name
      end
    end

    formated.comment_num = comment_num

    formated.created_at = date()

    return [formated, use_pre]
  end
end

class Comment < ActiveRecord::Base
  def date()
    fdate = DateTime.parse("#{created_at}")
    return fdate.strftime("%Y/%m/%d %H:%M")
  end

  def format()
    formated = FormatedComment.new(
      id,
      entry_id,
      Rack::Utils.escape_html(name),
      Rack::Utils.escape_html(body).gsub(/(\r\n|\r|\n)/,'<br />'),
      date()
      )
    return formated
  end
end

class Category < ActiveRecord::Base
end

class Searcher < ActiveRecord::Base
end

class FormatedEntry
  def initialize()
    @id
    @title
    @body
    @read_more = false
    @category = Array.new
    @comment_num
    @created_at
  end
  attr_accessor(
    :id,
    :title,
    :body,
    :read_more,
    :category,
    :comment_num,
    :created_at
    )
end

class FormatedComment
  def initialize(id, entry_id, name, body, created_at)
    @id = id
    @entry_id = entry_id
    @name = name
    @body = body
    @created_at = created_at
  end
  attr_accessor :id, :entry_id, :name, :body, :created_at
end
