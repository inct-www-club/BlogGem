helpers do
=begin
  def format_date(date)
    fdate = DateTime.parse("#{date}")
    return fdate.strftime("%Y/%m/%d %H:%M")
  end
=end

=begin
  def format_entry(entry, split_body)
    formated = FormatedEntry.new

    formated.id = entry.id

    formated.title = entry.title

    if split_body == true then
      body = entry.body.split('[read_more]')
      formated.body = "#{body[0]}".gsub(/(\r\n|\r|\n)/, '<br />')
      formated.read_more = (body.size >= 2)
    else
      body = entry.body.gsub(/(\r\n|\r|\n)/, '<br />')
      formated.body = body.gsub('[read_more]', '')
    end

    category_num = entry.category.split(',')
    category_num.each do |c|
      begin
        category =  Category.find(c.to_i)
        formated.category << category.name
      end
    end

    formated.comment_num = entry.comment_num

    formated.created_at = format_date(entry.created_at)

    return formated
  end
=end

  def format_entries(entry_array, split_body)
    formated = Array.new

    entry_array.each do |e|
      formated << e.format_entry(split_body)
    end

    return formated
  end

=begin
  def format_comment(comment)
    formated = FormatedComment.new

    formated.id = comment.id

    formated.entry_id = comment.entryId

    formated.name = escape_html(comment.name)

    formated.body = escape_html(comment.body).gsub(/(\r\n|\r|\n)/, '<br />')

    formated.created_at = comment.date()

    return formated
  end
=end

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
      erb :notFound
    end
  end

  def show_category_page(category, pagination)
    @head_title = "<small>カテゴリ</small> #{category}"
    category_info = Category.where(:name => category)
    if category_info.size == 1 then
      of = (pagination-1)*5
      wh = {:categoryId => category_info[0].id}
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
          @entry << Entry.find(s.entryId).format_entry(true)
        end

        haml :blogPages
      else
        erb :notFound
      end
    else
      erb :notFound
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
    puts `echo "#{body}" | "Contact from Sinji's view" "contact@sinjis-view.mydns.jp"`
  end

=begin
  def set_active_tab(tab_name)
    @tab.each do |tab|
      if tab.name == tab_name then
        tab.style = 'active'
        return
      end
    end
  end
=end

end