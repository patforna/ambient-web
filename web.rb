require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'mongo'
require 'dalli'
require 'rack-cache'

configure :development do
  $cache = Dalli::Client.new
  use Rack::Cache, :verbose => true, :metastore => $cache, :entitystore => $cache, :allow_reload => false  
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

get '/internal/signups' do
  @signups = settings.signups.find.sort({:_id => 1})
  erb :signups
end

post '/messages' do
  settings.messages.insert({ :email => params[:email], :message => params[:message] })
  redirect to('/')
end

get '/internal/messages' do
  @messages = settings.messages.find.sort({:_id => 1})
  erb :messages
end

