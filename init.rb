require 'open3'
require 'rubygems'
require 'sqlite3'
include SQLite3

Open3.capture3('gem update -system')

#install gem packages
packages = ['sinatra', 'sqlite3', 'activerecord']
packages.each do |package|
  print "[install] #{package}\n"
  out, err, status = Open3.capture3("gem install --no-ri --no-rdoc #{package}")
  if status.success? then
    print "#{out}\n"
  else
    print "#{err}\nInitialization of BlogGem is not complete.\nPlease solve the problem."
    raise "gem error"
  end
end

#set up database
print "[set up] database\n"
sql_file = ['entry.sql', 'element.sql', 'comment.sql', 'category.sql']
Database.new('page.db') do |database|
  sql_file.each do |sql|
    database.execute(open(sql).read)
  end
end
print "[complete] database\n"
