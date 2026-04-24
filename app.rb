require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

include Model

enable :sessions

# Hämtar användar_id från sessions och om någon är inloggad hämtas inforation från db
before '/*' do
  user = session[:user_id]
  if user == nil
    @user = false
  else
    @user = fetch_user(user)
  end
end


# Loggar utt
post '/logout' do
  session.clear
  redirect('/')
end

# Sparar nytt recept med hjälp av hjälpfunktion
post '/recipe/create' do 
  if @user
    add_recipe(params, @user)
  end
  redirect('/')
end

# raderar  recept med hjälp av hjälpfunktion, kontrollerar att det är rätt användare eller admin innan
post '/recipe/:id/delete' do
  id = params[:id]
  recipe = fetch_recipe(id)
  if @user["user_id"] == recipe["user_id"] || @user["user_id"] == 1
    delete_recipe(id)
  end
  redirect('/')
end

# uppdaterar information hos recept med hjälp av hjälpfunktion, kontrollerar att det är rätt användare eller admin innan
post '/recipe/:id/update' do
  id = params[:id]
  recipe = fetch_recipe(id)
  if @user["user_id"] == recipe["user_id"] || @user["user_id"] == 1
    update_recipe(params)
  end
  
  redirect("/recipe/#{id}")
end

# Lägger till användare med hjälp av admin och redirectar sedan till olika ställen
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

# Loggar in användaren och sparar id i sessions, använder hjälpfunktion
post '/login' do
  inlogg = login(params)
  if inlogg
    session[:user_id] = inlogg
    redirect('/')
  else
    redirect('/login')
  end
end

# Med hjälp av hjälpfunktion följs annan användare
post '/follow/:id' do
  id = params[:id].to_i
  if @user
    follow(@user["user_id"], id)
  end

  redirect("/user/#{id}")
end

# Med hjälp av hjälpfunktion avföljs annan användare
post '/unfollow/:id' do
  id = params[:id]
  unfollow(id, @user["user_id"])
  redirect("/user/#{id}")
end



# Visar inlogningssidan om användaren inte är inloggad
get '/login' do
  if @user
    redirect('/')
  else
    slim(:login)
  end
end

# Hämtar information om ett specifikt recept och visar sidan för denna i slim
get '/recipe/:id' do 
  recipe_id = params[:id]
  
  @recipe = fetch_recipe(recipe_id)
  @recipe["description"] = fix_linebreaks(@recipe["description"])
  @recipe["instructions"] = fix_linebreaks(@recipe["instructions"])
  slim(:recipe)
end

# Visar index sidan med lite information om alla recept som finns
get '/' do
  @recipes = all_recipes()

  slim(:index)

end

# Visar sidan med formulär som används för att skapa nya recept
get '/create/recipe' do
  if @user
    slim(:create_recipe)
  else
    redirect('/login')
  end
end 

# Visar sidan med formulär som används för att ändra recept om man har tillåtelse
get '/recipe/:id/edit' do
  id = params[:id]
  @recipe = fetch_recipe(id)
  if @user["user_id"] == @recipe["user_id"] || @user["user_id"] == 1
    slim(:update_recipe)
  else
    redirect("/recipe/#{id}")
  end
end

# Visar formuläret för att registrera en ny användare
get '/register' do
  if @user
    redirect('/')
  else
    slim(:register_user)
  end
end

# Visar information om en specifik användare, samt alla personens recept
get '/user/:id' do
  id = params[:id].to_i
  @followers = followers(id)
  @follows = follows(id)
  @viewed_user = fetch_user(id)
  @recipes = users_recipes(id)

  slim(:user)
end

# Visar alla en användares följare
get '/followers/:id' do
  id = params[:id]
  @type = "Followers"
  @follow = followers(id)
  @viewed_user = fetch_user(id)
  slim(:follow_stuff)
end

#Visar alla panvändare en användare följer
get '/follows/:id' do
  id = params[:id]
  @type = "Following"
  @follow = follows(id)
  @viewed_user = fetch_user(id)
  
  slim(:follow_stuff)
end