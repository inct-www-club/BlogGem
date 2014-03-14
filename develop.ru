require './main.rb'

require 'sinatra/reloader'
register Sinatra::Reloader

BlogGem.run!
