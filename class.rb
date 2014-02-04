class Element < ActiveRecord::Base
end

class Entry < ActiveRecord::Base
end

class Comment < ActiveRecord::Base
  def date()
    return format_date(@created_at)
  end
end

class Category < ActiveRecord::Base
end

class Searcher < ActiveRecord::Base
end

class Tabs
  def initialize(name, style, href)
    @name = name
    @style = style
    @href = href
    @dropdown
  end
  attr_accessor :name, :style, :href, :dropdown
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