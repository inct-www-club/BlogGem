require 'rubygems'
require 'sinatra'
require 'active_record'
require 'haml'
require 'json'
require 'bcrypt'
require "sqlite3"
require 'sinatra/reloader'
register Sinatra::Reloader

class BlogGem < Sinatra::Base
  def initialize(app = nil)
    super(app)
    @setting = BlogGem.load_json("settings.json")
    theme_path = File.join("views", @setting["theme"])
    @theme = BlogGem.load_json( File.join(theme_path, "scheme.json") )

    BlogGem.set_theme!(@setting["theme"])
    BlogGem.set_static_dirs!("views/Console")
    BlogGem.enable :sessions
    BlogGem.set :session_secret, "My session secret"

    Encoding.default_external = 'utf-8'
    ActiveRecord::Base.default_timezone = :local
    ActiveRecord::Base.establish_connection(
      "adapter" => "sqlite3",
      "database" => "./page.db"
      )
  end

  class << self
    def init()
      require 'io/console'

      print "make database..."
      SQLite3::Database.new('page.db') do |database|
        Dir::foreach("./sql") do |sql_file|
          next if sql_file == "." || sql_file == ".."
          database.execute(open("./sql/#{sql_file}").read)
        end
      end
      print "OK\n"

      print "make directories..."
      dirs = ["public", "public/uploads"]
      dirs.each do |dir|
        Dir::mkdir(dir) unless File.directory?(dir)
      end
      print "OK\n"

      #sign up first user
      ActiveRecord::Base.establish_connection(
        "adapter" => "sqlite3",
        "database" => "./page.db"
        )
      print "user id?:"
      id = STDIN.gets().chomp
      print "user name?:"
      name = STDIN.gets().chomp
      begin
        print "password?:"
        password = STDIN.noecho(&:gets).chomp
        print "\nconform pasword:"
      end while password != STDIN.noecho(&:gets).chomp

      user = User.new(:id => id, :name => name)
      user.encrypt_password(password)
      raise "Sing up error" unless user.save
    end

    def load_json(filename)
      File.open(filename, "r") do |f|
        JSON.load(f)
      end
    end

    def set_theme!(theme)
      theme_path = File.join("views", theme)
      BlogGem.set(:views, theme_path)
      BlogGem.set_static_dirs!(theme_path)
    end

    def set_static_dirs!(theme_path)
      static_url = Array.new
      Dir.open(theme_path).each do |dir|
        next if dir == "."
        next if dir == ".."
        static_url << "/#{dir}"  if File.directory?( File.join(theme_path, dir) )
      end
      BlogGem.use(Rack::Static, :urls => static_url, :root => theme_path)
    end
  end


  helpers do
    def do_template(template, options = {}, locals = {}, &block)
      public_send(@theme["template"], template, options, locals, &block)
    end

    def console_haml(template, options = {}, locals = {}, &block)
      options[:views] = "views/Console"
      haml(template, options, locals, &block)
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
      @entry = Entry.order('id desc').limit(6).offset((pagination - 1) * 5)
      raise Sinatra::NotFound if @entry.size == 0

      set_prev_and_next_link!(@entry, pagination, "/page/")
      @pre_active = false
      @entry.each do |entry|
        @pre_active = @pre_active || entry.include_pre?
        p entry.include_pre?
      end

      do_template :blogPages
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
        #e, pre = Entry.find(s.entry_id).format()
        @entry << Entry.find(s.entry_id)
        @pre_active ||= @entry.last.include_pre?
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
    @category      = Category.order(number: :asc)
    @newerComment  = Comment.order("id desc").where(:allow => 1).limit(5)
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

      #@entry, @pre_active = Entry.find(id).format(false)
      @entry = Entry.find(id)
      @entry.text(false)
      @pre_active = @entry.include_pre?
      @page_title = "#{@entry.title} - #{@setting["blog title"]}"

      do_template :blog_entry
    rescue
      raise Sinatra::NotFound
    end
  end

  post '/entry/:id/send-comment' do |i|
    id   = i.to_i
    name = params[:name]
    body = params[:body]
    allow = 0
    allow = 1 if @setting["comment approval"]
    if Entry.find(id) && ! nil_or_blank?(name) && ! nil_or_blank?(body) then
      Comment.create(:entry_id => id, :name => name, :body => body, :allow => allow)
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

  #Sign in
  get "/sign_in" do
    redirect to '/console/'  if session[:user_id]

    @sidebar = :hidden
    console_haml :sign_in
  end

  post "/sign_in" do
    redirect to '/console/'  if session[:user_id]

    user = User.authenticate(params[:id], params[:password])
    if user
      session[:user_id] = user.id
      redirect to '/console/'
    else
      redirect to "/sign_in?status=error"
    end
  end

  get "/sign_out" do
    session[:user_id] = nil
    redirect to "/sign_in"
  end


  # console
  before /^\/console\// do
    unless session[:user_id]
      redirect to "/sign_in"
    end
    @user = User.find(session[:user_id])
    @wait_comment_num = Comment.where(:allow => 0).count
  end

  #home
  get '/console/' do
    console_haml :blog_console
  end

  post "/console/upload" do
    File.open('public/uploads/' + params[:file][:filename], "w") do |f|
      f.write(params[:file][:tempfile].read)
    end
    return "Complete upload to <strong>/uploads/" + params[:file][:filename] + "</strong>"
  end


  #settings
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

  #entry
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
        Searcher.create(:entry_id => entry.id, :category_id => c)
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

  #categoty
  get '/console/category/' do
    @category = Category.order(number: :asc)
    console_haml :category_edit
  end

  post '/console/category/save' do
    @category = Category.where(nil)
    params[:category].size.times do |number|
      category = Category.find(params[:id].shift.to_i)
      edited = params[:category].shift
      if edited == "" then
        category.destroy
      else
        category.name = edited
        category.number = number
        category.save
      end
    end
    redirect to '/console/category/'
  end

  post '/console/category/new' do
    number = Category.count()
    category = Category.create(:name => params[:category], :number => number)
    redirect to '/console/category/'
  end

  #comment
  get '/console/comment/' do
    @comment = Comment.order("id desc")
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

  get '/console/comment/delete' do
    begin
      comment = Comment.find(params[:id].to_i)
      comment.destroy
    end
  end

  get "/console/membars/" do
    @membars = User.where(nil)
    console_haml :membars
  end

  post "/console/membars/add" do
    if params[:password] != params[:confirm_password]
      redirect to "/console/membars/?status=password"
    end

    user = User.new(:id => params[:id], :name => params[:name])
    user.encrypt_password(params[:password])
    if user.save
      redirect to "/console/membars/?status=success"
    else
      redirect to "/console/membars/?status=error"
    end
  end

  post "/console/membars/leave" do
    redirect to "/console/membars/" if params[:id] == session[:use_id]

    begin
      User.find(params[:id]).destroy
    end
    redirect to "/console/membars/?status=leave"
  end
end


class Entry < ActiveRecord::Base
  def categories()
    return @categories if @categories

    @categories = Array.new
    category.split(',').each do |c|
      begin
        _category =  Category.find(c.to_i)
        @categories[_category.number] = _category.name
      end
    end
    return @categories
  end

  def date()
    fdate = DateTime.parse("#{created_at}")
    return fdate.strftime("%Y/%m/%d %H:%M")
  end

  def include_pre?()
    text() unless @text
    return @text =~ /<pre(?:.|\n)*?pre>/
  end

  def read_more()
    return @read_more
  end

  def text(split_readmore=true)
    return @text if @text

    #read more
    @read_more = split_readmore && body.include?("[read_more]")

    if split_readmore then
      delete_pattarn = /\[read_more\].*$/
    else
      delete_pattarn = /\[read_more\]/
    end
    @text = body.gsub(/(\r\n|\r|\n)/,"<br />").gsub(delete_pattarn, "")

    #escape html inside the pre tag
    pre_pattarn = /<pre(?:.|\n)*?pre>/

    texts_without_pre = @text.split(pre_pattarn, -1)
    pre_tags = @text.scan(pre_pattarn)

    @text = texts_without_pre.shift
    texts_without_pre.length.times do
      pre_tag = pre_tags.shift
      pre_tag.gsub!("<br />", "\n")

      inside_tag = pre_tag[/>(?:.|\n)+</] || ""
      inside_tag = inside_tag[1, inside_tag.length - 2]

      pre_tag.gsub!(/>(?:.|\n)+</, ">#{Rack::Utils.escape_html(inside_tag)}<")
      @text = @text + pre_tag + texts_without_pre.shift
    end

    return @text
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

class User < ActiveRecord::Base
  attr_readonly :password_hash, :password_salt

  def encrypt_password(password)
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end

  def self.authenticate(user_id, password)
    user = User.find(user_id)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end
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
