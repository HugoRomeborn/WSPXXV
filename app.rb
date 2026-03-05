require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'


get '/recepie/:id' do 
  recepie_id = params[:id]
  
  @recepie = fetch_recepie(recepie_id)
  p @recepie
  slim(:recepie)
end

get '/' do
  @recepies = all_recepies()

  slim(:index)

end

get '/create/recepie' do
  
  slim(:create_recepie)
end 


