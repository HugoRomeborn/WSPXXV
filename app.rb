require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'


get '/recepie/:id' do 
  recepie_id = params[:id]
  
  fetch_recepie()
end