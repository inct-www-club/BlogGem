require 'rubygems'
require "sinatra"
require 'active_record'
require 'haml'

Encoding.default_external = 'utf-8'
ActiveRecord::Base.default_timezone = :local

load 'class.rb'

ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" => "./page.db"
  )

helpers do

  def format_entries(entry_array, split_body)
    formated = Array.new

    entry_array.each do |e|
      formated << e.format_entry(split_body)
    end

    return formated
  end

  def format_comments(comment_array)
    formated = Array.new

    comment_array.each do |c|
      formated << c.format_comment()
    end

    return formated
  end

  def link_to(href, name)
    "<a href='#{href}'>#{name}</a>"
  end

  def show_page(pagination)
    e = Entry.order('id desc').limit(5).offset((pagination - 1) * 5)
    @entry = format_entries(e, true)

    if @entry.size > 0 then
      if pagination == 1 then
        @previousClass = 'disabled'
      elsif pagination == 2 then
        @previousLink = to('/blog/')
      else
        @previousLink = to("/blog/page/#{pagination-1}/")
      end

      if Entry.count > 5*pagination then
        @nextLink = to("/blog/page/#{pagination+1}/")
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

=begin
  def create_tab()
    tabs = Array.new
    tabs << Tabs.new('Home', nil, to('/'))
    tabs << Tabs.new('Blog', nil, to('/blog/'))
    products = Tabs.new('Products', 'dropdown', to('/products/'))
    products.dropdown << Tabs.new('Coming soon!', nil, nil)
    tabs << products
    tabs << Tabs.new('Contact', nil, to('/contact/'))
    return tabs
  end

  def create_tab()
    return Array.new
=end

  def create_tab()
    formated_tabs = Array.new
    tabs = Tab.where(nil)
    tabs.each do |tab|
      if tab.parent_id == nil then
        formated_tabs << tab.format()
      else
        parent_tab = formated_tabs.find_from_field("@id", tab.parent_id)
        parent_tab.css_class = "dropdown"
        parent_tab.dropdown << tab.format()
      end
    end
    return formated_tabs
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

  def set_active_tab(tab_name)
    @tab.each do |tab|
      if tab.name == tab_name then
        if tab.css_class == nil then
          tab.css_class = 'active'
        else
          tab.css_class = "#{tab.css_class} active"
        end
        return
      end
    end
  end

  def redirect_from_old(get_param_p)
    if get_param_p != nil then
      old_id = [66, 77, 91, 107, 161]
      entry_id = old_id.index(get_param_p.to_i)
      print entry_id
      if entry_id != nil then
        redirect to "/blog/entry/#{entry_id+1}/"
      end
    end
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
  @tab = create_tab()
end

before %r{(^/blog/|/preview$)} do
  @sidebar = 'active'
  @blog_active = 'active'
  @newerEntry = Entry.order("id desc").limit(5)
  @category = Category.all
  @newerComment = Comment.order("id desc").where(:allow => 1).limit(5)
  set_active_tab('Blog')
end

before %r{^/console/} do
=begin
  @tab << Tabs.new('Console', nil, to('/console/'))
  @tab.last.style = 'float:right;'
  set_active_tab('Console')
=end
end

get '/' do
  @page_title = 'Sinji\'s View 酒田　シンジの目線'
  set_active_tab('Home')
  @element = Element.all
  haml :about_me
end

get '/blog/' do
  @page_title = 'Blog - Sinji\'s View'
  redirect_from_old(params[:p])
  show_page 1
end

get '/blog/page/:page/' do |p|
  @page_title = 'Blog - Sinji\'s View'
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
    @comment = format_comments(Comment.where(:entry_id => id, :allow => 1))
    @page_title = @entry.title + ' - Sinji\'s View'
    haml :blog_entry
  rescue ActiveRecord::RecordNotFound
    haml :not_found
  end
end

post '/blog/entry/:id/send-comment' do |i|
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

get '/blog/category/:category/' do |category|
  @page_title = 'カテゴリ:' + category + ' - Sinji\'s View'
  show_category_page(category, 1)
end

get '/blog/category/:category/:pagination/' do |category, p|
  @page_title = 'カテゴリ:' + category + ' - Sinji\'s View'
  pagination = p.to_i
  if pagination < 2 then
    redirect to '/blog/'
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
  haml :edit
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

get '/console/tab/' do 
  haml :tab_edit
end

post '/console/tab/new' do
  unless nil_or_blank?(params[:label]) || nil_or_blank?(params[:address]) then
    tab = Tab.new
    tab.label = params[:label]
    tab.address = params[:address]
    tab.save
  end
  redirect to "/console/tab/"
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
    redirect to '/console/blog/entry/'
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
  redirect to '/console/blog/entry/'
end

post '/console/blog/entry/:id/delete' do |id|
  key = id.to_i
  if key > 0 then
    entry = Entry.find(key)
  elsif id == 'new' then
    entry = Entry.new
  else
    redirect to '/console/blog/entry/'
  end
  Comment.where(:entry_id => entry.id).each do |comment|
    comment.destroy
  end
  entry.destroy
  redirect to '/console/blog/entry/'
end

post '/console/blog/entry/:id/preview' do |id|
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

get '/console/blog/category/' do
  @category = Category.all
  haml :category_edit
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
    entry = Entry.find(comment.entry_id)
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
    entry = Entry.find(comment.entry_id)
    comment.allow = 0
    comment.save
    if entry.comment_num > 0 then
      entry.comment_num -= 1
      entry.save
    end
  end
end