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

  def create_tab()
    tabs = Array.new
    tabs << Tabs.new('Home', nil, to('/'))
    tabs << Tabs.new('Blog', nil, to('/blog/'))
    products = Tabs.new('Products', 'dropdown', to('/products/'))
    products.dropdown = Array.new
    products.dropdown << Tabs.new('Coming soon!', nil, nil)
    tabs << products
    tabs << Tabs.new('Contact', nil, to('/contact/'))
    return tabs
  end

  def nil_or_blank?(target)
    return target == nil || target == ''
  end

  #Linux only
  def send_mail(body)
    title = 'Contact from Sinji\'s view'
    to = 'contact@sinjis-view'
    puts `echo "#{body}" | "#{title}" "#{from}"`
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

end