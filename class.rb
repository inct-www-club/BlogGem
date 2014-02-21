class Element < ActiveRecord::Base
end

class Entry < ActiveRecord::Base
  def date()
    fdate = DateTime.parse("#{created_at}")
    return fdate.strftime("%Y/%m/%d %H:%M")
  end

  def format_entry(split_body)
    formated = FormatedEntry.new

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

    return formated
  end
end

class Comment < ActiveRecord::Base
  def date()
    fdate = DateTime.parse("#{created_at}")
    return fdate.strftime("%Y/%m/%d %H:%M")
  end

  def format_comment()
    formated = FormatedComment.new

    formated.id = id

    formated.entry_id = entry_id

    formated.name = Rack::Utils.escape_html(name)

    formated.body =
      Rack::Utils.escape_html(body).gsub(/(\r\n|\r|\n)/,'<br />')

    formated.created_at = date()

    return formated
  end
end

class Category < ActiveRecord::Base
end

class Searcher < ActiveRecord::Base
end

class Tabs
  def initialize(name, css_class, href)
    @name = name
    @css_class = css_class
    @style
    @href = href
    @dropdown = Array.new
  end
  attr_accessor :name, :href, :dropdown, :css_class, :style
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
  def initialize()
    @id
    @entry_id
    @name
    @body
    @created_at
  end
  attr_accessor :id, :entry_id, :name, :body, :created_at
end