require 'rubygems'
require 'sinatra'
require 'active_record'
require 'haml'
require 'sinatra/reloader'
require 'json'

register Sinatra::Reloader
Encoding.default_external = 'utf-8'
ActiveRecord::Base.default_timezone = :local

set :views, File.dirname(__FILE__) + '/views/Default'
open("settings.json") do |io|
  $setting = JSON.load(io)
end

load 'class.rb'

ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" => "./page.db"
  )

helpers do

  def format_elements(array)
    formated = Array.new
    array.each do |element|
      formated << element.format()
    end
    return formated
  end

  def link_to(href, name)
    "<a href='#{href}'>#{name}</a>"
  end

  def show_page(pagination)
    entries = Entry.order('id desc').limit(5).offset((pagination - 1) * 5)
    @entry = format_elements(entries)

    if @entry.size > 0 then
      if pagination == 1 then
        @previousClass = 'disabled'
      elsif pagination == 2 then
        @previousLink = to('/')
      else
        @previousLink = to("/page/#{pagination-1}/")
      end

      if Entry.count > 5*pagination then
        @nextLink = to("/page/#{pagination+1}/")
      else
        @nextClass = 'disabled'
      end

      haml :blogPages
    else
      haml :not_found
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
        if pagination == 1 then
          @previousClass = 'disabled'
        elsif pagination == 2 then
          @previousLink = to("/blog/category/#{category}/")
        else
          @previousLink = to("/blog/category/#{category}/#{pagination-1}/")
        end

        if searcher.size <= 5 then
          @nextClass = 'disabled'
        else
          @nextLink = to("/blog/category/#{category}/#{pagination+1}/")
          searcher.delete_at(5)
        end

        @entry = Array.new
        searcher.each do |s|
          @entry << Entry.find(s.entry_id).format_entry(true)
        end

        haml :blogPages
      else
        haml :not_found
      end
    else
      haml :not_found
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
  @blog_title = $setting["blog title"]
  @newerEntry = Entry.order("id desc").limit(5)
  @category = Category.where(nil)
  @newerComment = Comment.order("id desc").where(:allow => 1).limit(5)
end

get '/' do
  @page_title = 'Blog - Sinji\'s View'
  show_page 1
end

get '/page/:page/' do |p|
  @page_title = 'Blog - Sinji\'s View'
  pagination = p.to_i
  if pagination < 2 then
    redirect to '/'
  end
  show_page pagination
end

get '/entry/:id/' do |i|
  id = i.to_i
  if id <= 0 then
    redirect to '/'
  end
  begin
    @entry = Entry.find(id).format_entry(false)
    @commentNum = 0
    @comment = format_elements(Comment.where(:entry_id => id, :allow => 1))
    @page_title = @entry.title + ' - Sinji\'s View'
    haml :blog_entry
  rescue ActiveRecord::RecordNotFound
    haml :not_found
  end
end

post '/entry/:id/send-comment' do |i|
  id = i.to_i
  if Entry.find(id) != nil then
    if ! nil_or_blank?(params[:name]) then
      if ! nil_or_blank?(params[:body]) then
        comment = Comment.new
        comment.entry_id = id
        comment.name = params[:name]
        comment.body = params[:body]
        comment.save
      end
    end
  end
end

get '/category/:category/' do |category|
  @page_title = 'カテゴリ:' + category + ' - Sinji\'s View'
  show_category_page(category, 1)
end

get '/category/:category/:pagination/' do |category, p|
  @page_title = 'カテゴリ:' + category + ' - Sinji\'s View'
  pagination = p.to_i
  if pagination < 2 then
    redirect to '/'
  end
  show_category_page(category, pagination)
end

get '/contact/' do
  @page_title = 'Contact - Sinji\'s View'
  set_active_tab('Contact')
  haml :contact
end

post '/contact/send-mail' do
  name    = escape_html(params[:name])
  address = escape_html(params[:address])
  body    = escape_html(params[:body])
  send_mail("#{name}\n#{address}\n\n#{body}")
end

# console
get '/console/' do
  @wait_comment_num = Comment.where(:allow => 0).count
  haml :blog_console
end

get '/console/settings/' do
  @setting = $setting
  haml :setting
end

post '/console/settings/new' do
  Setting.create(:item => params[:item], :value => params[:value])
  redirect to '/console/settings/'
end

get '/console/entry/' do
  @element = Entry.order("id desc").where(nil)
  @list_title = 'Entry List'
  @add_button = 'Add Entry'
  haml :element_list
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
  @entryEdit = 'active'
  @category = Category.where(nil)
  haml :edit
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
      searcher = Searcher.new
      searcher.entry_id = entry.id
      searcher.category_id = c
      searcher.save
    end
    entry.category = params[:category].join(", ")
  end
  entry.save
  redirect to '/console/entry/'
end

post '/console/entry/:id/delete' do |id|
  key = id.to_i
  if key > 0 then
    entry = Entry.find(key)
  elsif id == 'new' then
    entry = Entry.new
  else
    redirect to '/console/entry/'
  end
  Comment.where(:entry_id => entry.id).each do |comment|
    comment.destroy
  end
  entry.destroy
  redirect to '/console/entry/'
end

post '/console/entry/:id/preview' do |id|
  entry = Entry.new
  entry.title = params[:title]
  entry.body  = params[:entry]
  entry.category = ""
  if params[:category] != nil then
    params[:category].each do |c|
      entry.category = "#{entry.category}#{c},"
    end
  end
  entry.created_at = Time.now
  @entry = entry.format_entry(false)
  @comment = Array.new
  haml :blog_entry
end

get '/console/category/' do
  @category = Category.where(nil)
  haml :category_edit
end

post '/console/category/save' do
  @category = Category.where(nil)
  i = 0
  @category.each do |c|
    if params[:category][i] == '' then
      c.destroy
    else
      c.name = params[:category][i]
      c.save
    end
    i = i+1
  end
  redirect to '/console/category/'
end

post '/console/category/new' do
  category = Category.new
  category.name = params[:category]
  category.save
  redirect to '/console/category/'
end

get '/console/comment/' do
  @comment = Comment.where(nil)
  haml :console_comment
end

get '/console/comment/allow' do
  id = params[:id].to_i
  begin
    comment = Comment.find(id)
    entry = Entry.find(comment.entry_id)
    comment.allow = 1
    comment.save
    entry.comment_num += 1
    entry.save
  end
end

get '/console/comment/deny' do
  id = params[:id].to_i
  begin
    comment = Comment.find(id)
    entry = Entry.find(comment.entry_id)
    comment.allow = 0
    comment.save
    if entry.comment_num > 0 then
      entry.comment_num -= 1
      entry.save
    end
  end
end
