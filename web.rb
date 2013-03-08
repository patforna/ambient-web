require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'mongo'

configure :development do
  set :db, Mongo::Connection.new.db('ambient-web').collection('signups')
end

configure :production do
    db_uri = URI.parse(ENV['MONGOHQ_URL'])
    db_name = db_uri.path.gsub(/^\//, '')
    db_connection = Mongo::Connection.new(db_uri.host, db_uri.port).db(db_name)
    db_connection.authenticate(db_uri.user, db_uri.password) unless (db_uri.user.nil?)
    set :db, db_connection.collection('signups')
end

get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end
