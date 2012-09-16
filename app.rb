# dependencies
require "rubygems"
require "bundler"
Bundler.require
require "sinatra/reloader"
require "sprockets/sass/functions" # avoids warning
require 'pp'

module SeabassTasks
  class App < Sinatra::Base
    register Sinatra::Contrib
    register Sinatra::Reloader if development?
    
    enable :sessions
    
    use OmniAuth::Builder do
      provider :open_id, :name => 'google', :identifier => 'https://www.google.com/accounts/o8/id'
    end
    
    get "/" do
      erb :index
    end
    
    # omniauth stuff
    route :get, :post, "/auth/:provider/callback" do

      redirect "/"
    end
  end
end