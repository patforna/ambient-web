require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'mongo'

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
end

get '/' do
  erb :index
end

get '/4yc3Xf' do
  redirect to('/')
end

get '/thanks' do
  @thanks = true
  erb :index
end

post '/signups' do
  settings.signups.insert({ :email => params[:email] })
  redirect to('/thanks')
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

