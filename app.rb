# dependencies
require "rubygems"
require "bundler"
Bundler.require
require "sinatra/reloader"
require "securerandom"
require "json"
require 'pp'

module SeabassTasks
  class App < Sinatra::Base
    register Sinatra::Contrib
    register Sinatra::Reloader if development?
    
    enable :sessions
    set :json_encoder, :to_json
    
    use OmniAuth::Builder do
      provider :open_id, :name => 'google', :identifier => 'https://www.google.com/accounts/o8/id'
    end
    
    $redis = Redis::Namespace.new(:seabass_tasks, :redis => Redis.new(
      :url => ENV['REDISTOGO_URL'], 
      :logger => Logger.new(STDOUT)
    )) 
    
    helpers do
      def authorized?
        !! session[:email]
      end

      def authorize!
        redirect "/" unless authorized?
      end
    end
    
    get "/" do
      erb authorized? ? :index : :login
    end
    
    namespace "/api" do
      
      # list all tasks for authenticated user
      get "/tasks" do
        # get the set of all tasks assigned to the current user
        task_ids = $redis.smembers "users:#{session[:email]}:tasks"
        
        # get the attributes hash for each of these tasks
        # TODO: should be batched and combined with the operation above
        json task_ids.map { |task_id| $redis.hgetall "tasks:#{task_id}" }
      end
      
      # create a new task
      post "/tasks" do
        # generate a random ID for the new task
        id = SecureRandom.hex
        
        # build the list of relevant users
        recipients = Set.new(Mail::AddressList.new(params[:recipients]).addresses.map(&:address).compact)
        recipients << session[:email] # include the current user
        pp recipients
        # attributes for the task, based on parameters passed and current user
        task = {
          :id           => id,
          :subject      => params[:subject],
          :body         => params[:body],
          :creator      => session[:email],
          :status       => "open",
          :created_at   => Time.now,
        }
        # create a hash of the task attributes
        $redis.hmset "tasks:#{id}", *task.to_a.flatten
        
        # create a recipient list for the task
        $redis.sadd "tasks:#{id}:recipients", recipients
        
        # add the task id to each recipient's task list
        # TODO: batch this
        recipients.each { |email| $redis.sadd "users:#{session[:email]}:tasks", id }
        
        # merge in recipient list and render
        json task.merge(:recipients => recipients.to_a)
      end
      
      # update task
      put "/tasks/:id" do
        # check the user is in the recipient list
        # grab hash, pluck params, merge, set, return
      end
    end
    
    # authorization stuff
    route :get, :post, "/auth/:provider/callback" do
      session[:email] = request.env['omniauth.auth']["info"]["email"]
      redirect "/"
    end
  end
end