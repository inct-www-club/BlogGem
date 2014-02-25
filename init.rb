require 'open3'
require 'rubygems'

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
require 'sqlite3'
include SQLite3

print "[set up] database\n"
Database.new('page.db') do |database|
  Dir::foreach("./sql") do |sql_file|
    next if sql_file == "." || sql_file == ".."
    database.execute(open("./sql/#{sql_file}").read)
  end
end
print "[complete] database\n"
