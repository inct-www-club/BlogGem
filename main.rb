require 'rubygems'
require 'sinatra'
require 'active_record'
require 'haml'
require 'sinatra/reloader'
require 'json'

register Sinatra::Reloader
Encoding.default_external = 'utf-8'
ActiveRecord::Base.default_timezone = :local

open("settings.json") do |io|
  $setting = JSON.load(io)
end

open("./views/#{$setting["theme"]}/scheme.json") do |io|
  $theme = JSON.load(io)
end

load 'class.rb'

ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" => "./page.db"
  )

helpers do
  def haml(template, options = {}, locals = {}, &block)
    render(:haml, :"#{$setting['theme']}/#{template.to_s}", options, locals, &block)
  end

  def do_template(symbol)
    if $theme["template"] == "haml" then
      haml symbol, :layout => :"#{$setting['theme']}/layout"
    elsif $theme["template"] == "erb" then
      erb synbol
    else
      raise "theme error"
    end
  end

  def console_haml(symbol)
    render(:haml, :"Console/#{symbol.to_s}", :layout => :"Console/layout")
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
      do_template :not_found
    end
  end

  def show_category_page(category, pagination)
    @head_title = "<small>カテゴリ</small> #{category}"
    category_info = Category.where(:name => category)
    if category_info.size == 1 then
      of = (pagination-1)*5
      wh = {:category_id => category_info[0].id}
      searcher = Searcher.order("id desc").limit(6).offset(of).where(wh)
      if searcher.size > 0 then
        set_prev_and_next_link!(searcher, pagination, "/category/#{category}/")

        @entry = Array.new
        searcher.each do |s|
          e, pre = Entry.find(s.entry_id).format()
          @entry << e
          @pre_active = @pre_active || pre
        end

        do_template :blogPages
      else
        do_template :not_found
      end
    else
      do_template :not_found
    end
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
  @year = Time.now.year
  @since = $setting["since"]
  @copyright = $setting["copyright"]
  @blog_title = $setting["blog title"]
  @sub_title = $setting["sub title"]
  @newerEntry = Entry.order("id desc").limit(5)
  @category = Category.where(nil)
  @newerComment = Comment.order("id desc").where(:allow => 1).limit(5)
end

before /^\/console\// do
  @wait_comment_num = Comment.where(:allow => 0).count
end

get '/' do
  @page_title = 'Blog - Sinji\'s View'
  show_page 1
end

get '/page/:page/' do |p|
  @page_title = 'Blog - Sinji\'s View'
  pagination = p.to_i

  redirect to '/' if pagination < 2

  show_page pagination
end

get '/entry/:id/' do |i|
  id = i.to_i
  redirect to '/' if id <= 0

  begin
    @status = params[:status]
    @entry, @pre_active = Entry.find(id).format(false)
    @comment = format_elements(Comment.where(:entry_id => id, :allow => 1))
    @commentNum = @comment.size
    @page_title = @entry.title + ' - Sinji\'s View'
    do_template :blog_entry
  rescue ActiveRecord::RecordNotFound
    do_template :not_found
  end
end

post '/entry/:id/send-comment' do |i|
  id = i.to_i
  name = params[:name]
  body = params[:body]
  if Entry.find(id) && ! nil_or_blank?(name) && ! nil_or_blank?(body) then
    Comment.create(:entry_id => id, :name => name, :body => body)
    redirect to ("/entry/#{id}/?status=success") unless $theme["use Ajax"]
  else
    redirect to ("/entry/#{id}/?status=error") unless $theme["use Ajax"]
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
    redirect to ('/contact/?status=success') unless $theme["use Ajax"]
  rescue
    redirect to ('/contact/?status=error') unless $theme["use Ajax"]
  end
end

# console
get '/console/' do
  console_haml :blog_console
end

get '/console/settings/' do
  @setting = $setting
  console_haml :setting
end

post '/console/settings/new' do
  Setting.create(:item => params[:item], :value => params[:value])
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
