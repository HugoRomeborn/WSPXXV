require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'
 
include Model
 
enable :sessions
 
# Fetches the user_id from the session and loads the user from the database if logged in
before '/*' do
  user = session[:user_id]
  if user == nil
    @user = false
  else
    @user = fetch_user(user)
  end
end
 
 
# @!group Routes
 
# Logs out the current user and clears the session
#
# @return [void] redirects to /
post '/logout' do
  session.clear
  redirect('/')
end
 
# Creates a new recipe if the user is logged in
#
# @return [void] redirects to /
post '/recipe' do 
  if @user
    add_recipe(params, @user)
  end
  redirect('/')
end
 
# Deletes a recipe if the current user owns it or is admin
#
# @param [Integer] id the recipe id
#
# @return [void] redirects to /
post '/recipe/:id/delete' do
  id = params[:id]
  recipe = fetch_recipe(id)
  if @user["user_id"] == recipe["user_id"] || @user["user_id"] == 1
    delete_recipe(id)
  end
  redirect('/')
end
 
# Updates a recipe if the current user owns it or is admin
#
# @param [Integer] id the recipe id
#
# @return [void] redirects to /recipe/:id
post '/recipe/:id/update' do
  id = params[:id]
  recipe = fetch_recipe(id)
  if @user["user_id"] == recipe["user_id"] || @user["user_id"] == 1
    update_recipe(params)
  end
  
  redirect("/recipe/#{id}")
end
 
# Registers a new user and redirects based on the result
#
# @return [void] redirects to /login, /register, or /login on failure
post '/user/add' do
  case add_user(params)
  when true
    redirect('/login')
  when "/register"
    redirect('/register')
  when "/login"
    redirect('/login')
  end
end
 
# Authenticates the user and stores their id in the session
#
# @return [void] redirects to / on success or /login on failure
post '/login' do
  inlogg = login(params)
  if inlogg
    session[:user_id] = inlogg
    redirect('/')
  else
    redirect('/login')
  end
end
 
# Follows another user
#
# @param [Integer] id the id of the user to follow
#
# @return [void] redirects to /user/:id
post '/follow/:id' do
  id = params[:id].to_i
  if @user
    follow(@user["user_id"], id)
  end
 
  redirect("/user/#{id}")
end
 
# Unfollows another user
#
# @param [Integer] id the id of the user to unfollow
#
# @return [void] redirects to /user/:id
post '/unfollow/:id' do
  id = params[:id]
  unfollow(id, @user["user_id"])
  redirect("/user/#{id}")
end
 
 
 
# Shows the login page, or redirects to / if already logged in
#
# @return [String] renders the login view
get '/login' do
  if @user
    redirect('/')
  else
    slim(:login)
  end
end
 
# Shows a single recipe
#
# @param [Integer] id the recipe id
#
# @return [String] renders the recipe view
get '/recipe/:id' do 
  recipe_id = params[:id]
  
  @recipe = fetch_recipe(recipe_id)
  @recipe["description"] = fix_linebreaks(@recipe["description"])
  @recipe["instructions"] = fix_linebreaks(@recipe["instructions"])
  slim(:recipe)
end
 
# Shows the index page with all recipes
#
# @return [String] renders the index view
get '/' do
  @recipes = all_recipes()
 
  slim(:index)
 
end
 
# Shows the create recipe form, or redirects to /login if not logged in
#
# @return [String] renders the create_recipe view
get '/recipe/new' do
  if @user
    slim(:new)
  else
    redirect('/login')
  end
end 
 
# Shows the edit recipe form if the user has permission
#
# @param [Integer] id the recipe id
#
# @return [String] renders the update_recipe view
get '/recipe/:id/edit' do
  id = params[:id]
  @recipe = fetch_recipe(id)
  if @user["user_id"] == @recipe["user_id"] || @user["user_id"] == 1
    slim(:edit)
  else
    redirect("/recipe/#{id}")
  end
end
 
# Shows the registration form, or redirects to / if already logged in
#
# @return [String] renders the register_user view
get '/register' do
  if @user
    redirect('/')
  else
    slim(:register_user)
  end
end
 
# Shows a user's profile and all their recipes
#
# @param [Integer] id the user's id
#
# @return [String] renders the user view
get '/user/:id' do
  id = params[:id].to_i
  @followers = followers(id)
  @follows = follows(id)
  @viewed_user = fetch_user(id)
  @recipes = users_recipes(id)
 
  slim(:user)
end
 
# Shows all followers of a user
#
# @param [Integer] id the user's id
#
# @return [String] renders the follow_stuff view
get '/followers/:id' do
  id = params[:id]
  @type = "Followers"
  @follow = followers(id)
  @viewed_user = fetch_user(id)
  slim(:follow_stuff)
end
 
# Shows all users that a user follows
#
# @param [Integer] id the user's id
#
# @return [String] renders the follow_stuff view
get '/follows/:id' do
  id = params[:id]
  @type = "Following"
  @follow = follows(id)
  @viewed_user = fetch_user(id)
  
  slim(:follow_stuff)
end