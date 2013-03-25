require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'mongo'
require 'dalli'
require 'rack-cache'

configure do
  $cache = Dalli::Client.new
  use Rack::Cache, :verbose => true, :metastore => $cache, :entitystore => $cache, :allow_reload => false  
  set :fb_tracking, {:launch_page_visit => '6006195517954', :email_signup => '6006195574754'}
end

configure :development do
  set :signups, Mongo::Connection.new.db('ambient-web').collection('signups')
  set :messages, Mongo::Connection.new.db('ambient-web').collection('messages')  
end

configure :production do
  require 'newrelic_rpm'
  db_uri = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db_uri.path.gsub(/^\//, '')
  db_connection = Mongo::Connection.new(db_uri.host, db_uri.port).db(db_name)
  db_connection.authenticate(db_uri.user, db_uri.password) unless (db_uri.user.nil?)
  set :signups, db_connection.collection('signups')
  set :messages, db_connection.collection('messages')    
  set :static_cache_control, [:public, :max_age => 60]      
end

get '/' do
  cache_control :public, :max_age => 60
  @referral_token = params[:ref]
  erb :index
end

get %r{/(x.*+)} do
  redirect to("/?ref=#{params[:captures].first}")
end

get '/thanks' do
  @viral_url = "http://discoverambient.com/#{params[:ref]}"
  @thanks = true
  erb :index
end

post '/signups' do
  if (params[:email].strip.empty?)
    redirect back        
  end
  
  referral_token = "x" + rand(36**5).to_s(36)
  doc = { :email => params[:email], :referral_token => referral_token, :referrals => 0 }

  referred_by = params[:referred_by]
  if (referred_by)
    doc[:referred_by] = referred_by
    settings.signups.update({:referral_token => referred_by},{:$inc => {:referrals => 1}})
  end

  settings.signups.insert(doc)
  redirect to("/thanks?ref=#{referral_token}")
end

post '/messages' do
  settings.messages.insert({ :email => params[:email], :message => params[:message] })
  redirect to('/')
end

###########################################################################################
# Internal pages:

def isAdminUser()
  return request.cookies["isAmbientAdmin"] == "UgjgTUYFDWFnklwdwdKJHFHBFDDnDYS"
end

get '/internal/signups' do
  if isAdminUser()
    @signups = settings.signups.find.sort({:_id => 1})
    erb :signups
  else 
    redirect "/internal/login"
  end
end

get '/internal' do
  if isAdminUser()
    erb :internal_home
  else 
    redirect "/internal/login"
  end
end

get '/internal/login' do
  erb :internal_login
end

post '/internal/dologin' do
  if params['name'] == "admin" && params['password'] == "ycombinator"
    response.set_cookie("isAmbientAdmin", "UgjgTUYFDWFnklwdwdKJHFHBFDDnDYS")
  end
  redirect "/internal"
end

get '/internal/messages' do
  if isAdminUser()
    @messages = settings.messages.find.sort({:_id => 1})
    erb :messages
  else 
    redirect "/internal/login"
  end
end


