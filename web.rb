require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'mongo'

configure :development do
  set :db, Mongo::Connection.new.db('ambient-web').collection('signups')
end

configure :production do
    require 'newrelic_rpm'
    db_uri = URI.parse(ENV['MONGOHQ_URL'])
    db_name = db_uri.path.gsub(/^\//, '')
    db_connection = Mongo::Connection.new(db_uri.host, db_uri.port).db(db_name)
    db_connection.authenticate(db_uri.user, db_uri.password) unless (db_uri.user.nil?)
    set :db, db_connection.collection('signups')
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
  settings.db.insert({ :email => params[:email] })
  redirect to('/thanks')
end

get '/internal/signups' do
  @signups = settings.db.find.sort({:_id => 1})
  erb :signups
end

