require './main'
BlogGem.set :public_folder, './'

if ARGV[0] == "init" then
  BlogGem.init
else
  BlogGem.run!
end
