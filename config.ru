require './main'

if ARGV[0] == "init" then
  BlogGem.init
else
  BlogGem.run!
end
