require 'rubygems'
require "sinatra"
require "sinatra/reloader"
require 'active_record'
require 'haml'

register Sinatra::Reloader

load 'helper.rb'
load 'class.rb'

ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" => "./page.db"
  )

error do |e|
  "ERROR #{e}"
end

before do
  @documentRoot = '/area'
  create_tab()
end

before %r{^/blog/(.*)} do
  @sidebar = 'active'
  @blog_active = 'active'
  @newerEntry = Entry.order("id desc").limit(5)
  @category = Category.all
  @newerComment = Comment.order("id desc").where(:allow => 1).limit(5)
  @tab[1].style = 'active'
end

get '/' do
  @tab[0].style = 'active'
  @element = Element.all
  haml :about_me
end

get '/blog/' do
  show_page 1
end

get '/blog/page/:page/' do |p|
  pagination = p.to_i
  if pagination < 2 then
    redirect to '/blog/'
  end
  show_page pagination
end

get '/blog/entry/:id/' do |i|
  id = i.to_i
  if id <= 0 then
    redirect to '/blog/'
  end
  begin
    @entry = Entry.find(id).format_entry(false)
    @commentNum = 0
    @comment = format_comments(Comment.where(:entryId => id, :allow => 1))
    haml :blog_entry
  rescue ActiveRecord::RecordNotFound
    erb :notFound
  end
end

post '/blog/entry/:id/send-comment' do |i|
  id = i.to_i
  if id <= 0 then
    return
  end

  if Entry.find(id) == nil then
    return
  end

  if nil_or_blank?(params[:name]) || nil_or_blank?(params[:body])then
    return
  end

  comment = Comment.new
  comment.entryId = id
  comment.name = params[:name]
  comment.body = params[:body]
  comment.save
end

get '/blog/category/:category/' do |category|
  show_category_page(category, 1)
end

get '/blog/category/:category/:pagination/' do |category, p|
  pagination = p.to_i
  if pagination < 2 then
    redirect to '/blog/'
  end
  show_category_page(category, pagination)
end

get '/contact/' do
  set_active_tab('Contact')
  haml :contact
end

post '/contact/send-mail' do
  name    = escape_html(params[:name])
  address = escape_html(params[:address])
  body    = escape_html(params[:body])
  send_mail("#{name}\n#{address}\n\n#{body}")
end

get '/console/aboutme/' do
  @element = Element.all
  @list_title = 'Element List'
  @add_button = 'Add Element'
  haml :element_list
end

get '/console/aboutme/:id/' do |id|
  key = id.to_i
  if key > 0 then
    element = Element.find(key)
    @title = element.title
    @body = element.body
  elsif id != 'new' then
    redirect to '/console/aboutme/'
  end
  erb :edit
end

post '/console/aboutme/:id/post' do |id|
  key = id.to_i
  if key > 0 then
    element = Element.find(key)
  elsif id == 'new' then
    element = Element.new
  else
    redirect to '/console/aboutme/'
  end
  if params[:submit] == 'delete' then
    element.destroy
    redirect to '/console/aboutme/'
  end
  element.title = params[:title]
  element.body  = params[:entry]
  element.save
  redirect to '/console/aboutme/'
end

get '/console/blog/' do
  @wait_comment_num = Comment.where(:allow => 0).count
  haml :blog_console
end

get '/console/blog/entry/' do
  @element = Entry.order("id desc").all
  @list_title = 'Entry List'
  @add_button = 'Add Entry'
  haml :element_list
end

get '/console/blog/entry/:id/' do |id|
  key = id.to_i
  if key > 0 then
    entry = Entry.find(key)
    @title = entry.title
    @body = entry.body
    @entryCategory = entry.category.split(",")
  elsif id == 'new' then
    @entryCategory = Array.new
  else
    redirect to '/console/blog/'
  end
  @entryEdit = 'active'
  @category = Category.all
  haml :edit
end

post '/console/blog/entry/:id/post' do |id|
  key = id.to_i
  if key > 0 then
    entry = Entry.find(key)
  elsif id == 'new' then
    entry = Entry.new
  else
    redirect to '/console/blog/'
  end
  if params[:submit] == 'delete' then
    entry.destroy
    redirect to '/console/blog/'
  end
  entry.title = params[:title]
  entry.body  = params[:entry]
  entry.category = ''
  entry.save
  params[:category].each do |c|
    searcher = Searcher.new
    searcher.entryId = entry.id
    searcher.categoryId = c
    searcher.save
    entry.category = "#{entry.category}#{c},"
  end
  entry.save
  redirect to '/console/blog/'
end

get '/console/blog/category/' do
  @category = Category.all
  erb :categoryEdit
end

post '/console/blog/category/save' do
  @category = Category.all
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
  redirect to '/console/blog/category/'
end

post '/console/blog/category/new' do
  category = Category.new
  category.name = params[:category]
  category.save
  redirect to '/console/blog/category/'
end

get '/console/blog/comment/' do
  @comment = Comment.all
  haml :console_comment
end

get '/console/blog/comment/allow' do
  id = params[:id].to_i
  begin
    comment = Comment.find(id)
    entry = Entry.find(comment.entryId)
    comment.allow = 1
    comment.save
    entry.comment_num += 1
    entry.save
  end
end

get '/console/blog/comment/deny' do
  id = params[:id].to_i
  begin
    comment = Comment.find(id)
    entry = Entry.find(comment.entryId)
    comment.allow = 0
    comment.save
    if entry.comment_num > 0 then
      entry.comment_num -= 1
      entry.save
    end
  end
end