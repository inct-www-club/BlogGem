require 'open3'

Open3.capture3(gem update -system)

packages = ['sinatra', 'sqlite3', 'activerecord']
packages.each do |package|
  print "[install] #{package}\n"
  out, err, status = Open3.capture3("gem install #{package}")
  if status.success? then
    print "#{out}\n"
  else
    print "#{err}\nInitialization of BlogGem is not complete.\nPlease solve the problem."
    break
  end
  
end
