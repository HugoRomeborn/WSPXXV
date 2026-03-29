require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

before '/*' do
  user = session[:user_id]
  if user == nil
    @user = false
  else
    @user = user
  end
end

post '/logout' do
    session.clear
    redirect('/')
end

post '/recipe/create' do 
  add_recipe(params)
  redirect('/')
end

post '/recipe/:id/delete' do
  id = params[:id]
  delete_recipe(id)
  redirect('/')
end

post '/recipe/:id/update' do
  id = params[:id]

  update_recipe(params)

  redirect("/recipe/#{id}")
end

post '/user/add' do
  user = params["user"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]


  db = db()
  result = db.execute("SELECT user_id FROM users WHERE username=?", user)

  if result.empty?
    if pwd == pwd_confirm
      pwd_digest = BCrypt::Password.create(pwd)
      db.execute("INSERT INTO users(username, pwd_digest) VALUES(?,?)", [user, pwd_digest])
      redirect('/login')
    else
      redirect('/error')
    end
  else
    redirect('/login')
  end
end

post '/login' do
    
  user = params["user"]
  pwd = params["pwd"]

  db = db()
  result = db.execute("SELECT * FROM users WHERE username =?", user)

  if result.empty?
    redirect('/login')
  end
  user_id = result.first["user_id"]
  pwd_digest = result.first["pwd_digest"]
  
  if BCrypt::Password.new(pwd_digest)==pwd
    session[:user_id] = user_id
    redirect('/')
  else
    redirect('/login')
  end

end





get '/login' do
  if @user
    redirect('/')
  else
    slim(:login)
  end
end

get '/recipe/:id' do 
  recipe_id = params[:id]
  
  @recipe = fetch_recipe(recipe_id)
  @recipe["description"] = fix_linebreaks(@recipe["description"])
  @recipe["instructions"] = fix_linebreaks(@recipe["instructions"])
  slim(:recipe)
end

get '/' do
  @recipes = all_recipes()

  slim(:index)

end

get '/create/recipe' do
  if  @user
    slim(:create_recipe)
  else
    redirect('/login')
  end
end 

get '/recipe/:id/edit' do
  id = params[:id]
  @recipe = fetch_recipe(id)
  slim(:update_recipe)
end

get '/register' do
  if @user
    redirect('/')
  else
    slim(:register_user)
  end
end