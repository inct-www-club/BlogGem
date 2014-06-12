#!/home/sandabu/local/bin/ruby
ENV['GEM_HOME'] = '/home/sandabu/local/lib/ruby/gems'
ENV['RACK_ENV'] = 'production'
load './main.rb'

set :run => false
Rack::Handler::CGI.run(BlogGem)
