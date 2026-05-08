require 'sqlite3'
require 'bcrypt'
module Model
 
  # Creates a connection with the database
  #
  # @return [SQLite3::Database] the database connection
  def db()
    db = S  QLite3::Database.new("db/recipes.db")
    db.results_as_hash = true
    return db
  end
 
 
  # Fetches a recipe and its ingredients from the database
  #
  # @param [Integer] id the recipe id
  #
  # @return [Hash] the recipe data including ingredients
  def fetch_recipe(id)
    db = db()
    recipe = db.execute("SELECT * FROM recipes INNER JOIN users ON recipes.user_id = users.user_id WHERE id=?", id)
    ingredients = db.execute("SELECT * FROM rel_recipe_ingredients INNER JOIN ingredients ON rel_recipe_ingredients.ingredient_id = ingredients.id WHERE recipe_id=?", id)
 
    ingredients_arr = []
    ingredients.each do |ingredient|
      ingredients_arr << {"amount" => ingredient["amount"], "ingredient" => ingredient["ingredient"]}
    end
    recipe = recipe[0]
    recipe["ingredients"] = ingredients_arr
    return recipe
  end
 
  
  # Updates a recipe's title, description, instructions and ingredients
  #
  # @param [Hash] recipe the form data for the recipe
  # @option recipe [Integer] id the recipe id
  # @option recipe [String] title the recipe title
  # @option recipe [String] description the recipe description
  # @option recipe [String] instructions the recipe instructions
  # @option recipe [Array<Hash>] ingredients list of ingredient hashes with name and amount
  #
  # @return [void]
  def update_recipe(recipe)
    db = db()
 
    db.execute("UPDATE recipes SET title=?, description=?, instructions=? WHERE id=?", [recipe["title"], recipe["description"], recipe["instructions"]])
 
 
    db.execute("DELETE FROM rel_recipe_ingredients WHERE recipe_id LIKE ?", recipe["id"])
    ingredients = recipe["ingredients"]
    ingredients.each do |ingredient|
      earlier_ingredients = db.execute('SELECT id FROM ingredients WHERE ingredient=?', ingredient["name"])
      if earlier_ingredients.length > 0
 
        ingredient_id = earlier_ingredients.first["id"]
        db.execute('INSERT INTO rel_recipe_ingredients (recipe_id, ingredient_id, amount) VALUES (?, ?, ?)', [recipe["id"], ingredient_id, ingredient["amount"]])
 
      else
        db.execute('INSERT INTO ingredients (ingredient) VALUES (?)', ingredient["name"])
        earlier_ingredients = db.execute('SELECT id FROM ingredients WHERE ingredient=?', ingredient["name"])
        ingredient_id = earlier_ingredients.first["id"]
        db.execute('INSERT INTO rel_recipe_ingredients (recipe_id, ingredient_id, amount) VALUES (?, ?, ?)', [recipe["id"], ingredient_id, ingredient["amount"]])
      end
    end
 
  end
 
  # Splits a text string on literal \r\n to restore line breaks after DB storage
  #
  # @param [String] text the text to split
  #
  # @return [Array<String>] the lines of text
  def fix_linebreaks(text)
    text.split('\r\n')
  end
 
  # Deletes a recipe, its image file, and its ingredient relations
  #
  # @param [Integer] id the recipe id
  #
  # @return [void]
  def delete_recipe(id) 
    db = db()
    image = db.execute('SELECT image_link FROM recipes WHERE id LIKE ?', id)
    db.execute("DELETE FROM recipes WHERE id LIKE ?", id)
    db.execute("DELETE FROM rel_recipe_ingredients WHERE recipe_id LIKE ?", id)
    File.delete("public#{image[0]["image_link"]}")
  end
 
  # Fetches all recipes without ingredients
  #
  # @return [Array<Hash>] all recipes
  def all_recipes()
    db = db()
    db.execute("SELECT * FROM recipes")
  end
 
  # Creates a new recipe, saves its image and links its ingredients
  #
  # @param [Hash] recipe the form data for the recipe
  # @option recipe [String] title the recipe title
  # @option recipe [String] description the recipe description
  # @option recipe [String] instructions the recipe instructions
  # @option recipe [Array<Hash>] ingredients list of ingredient hashes with name and amount
  # @param [Hash] user the logged-in user
  # @option user [Integer] user_id the user's id
  # @option user [String] username the user's username
  # @option user [String] pwd_digest the user's hashed password
  #
  # @return [void]
  def add_recipe(recipe, user)
    db = db()
 
    if params[:image] && params[:image][:filename]
      filename = params[:image][:filename].split(".")
      file = params[:image][:tempfile]
      i = 0
      # Index images so the filename is always unique even if two files share the same name
      while File.exist?("./public/IMG/user_images/#{filename[0] + i.to_s + "." + filename[1]}")
        i +=1
      end
      # Save the image in the directory 'IMG/user_images'
      File.open("./public/IMG/user_images/#{filename[0] + i.to_s + "." + filename[1]}", 'wb') do |f|
        f.write(file.read)
      end  
    end
 
    db.execute('INSERT INTO recipes (title, description, instructions, user_id, image_link) VALUES (?, ?, ?, ?, ?)', [recipe["title"], recipe["description"], recipe["instructions"], user["user_id"], "/IMG/user_images/#{filename[0] + i.to_s + "." + filename[1]}"])
 
    id = db.execute('SELECT id FROM recipes WHERE title=? AND user_id=?', [recipe["title"], user["user_id"]])
    id = id.first["id"]
 
    # Add ingredients
    ingredients = recipe["ingredients"]
    ingredients.each do |ingredient|
      earlier_ingredients = db.execute('SELECT id FROM ingredients WHERE ingredient=?', ingredient["name"])
      if earlier_ingredients.length > 0
 
        ingredient_id = earlier_ingredients.first["id"]
        db.execute('INSERT INTO rel_recipe_ingredients (recipe_id, ingredient_id, amount) VALUES (?, ?, ?)', [id, ingredient_id, ingredient["amount"]])
 
      else
        db.execute('INSERT INTO ingredients (ingredient) VALUES (?)', ingredient["name"])
        earlier_ingredients = db.execute('SELECT id FROM ingredients WHERE ingredient=?', ingredient["name"])
        ingredient_id = earlier_ingredients.first["id"]
        db.execute('INSERT INTO rel_recipe_ingredients (recipe_id, ingredient_id, amount) VALUES (?, ?, ?)', [id, ingredient_id, ingredient["amount"]])
      end
    end 
  end
 
  # Fetches all users who follow a given user
  #
  # @param [Integer] user the user id to look up followers for
  #
  # @return [Array<Hash>] the users following this user
  def followers(user)
    db = db()
    db.execute('SELECT * FROM following INNER JOIN users ON following.user_id = users.user_id WHERE followed_id=?', user)
  end
 
  # Fetches all users that a given user follows
  #
  # @param [Integer] user the user id
  #
  # @return [Array<Hash>] the users this user follows
  def follows(user)
    db = db()
    db.execute('SELECT * FROM following INNER JOIN users ON following.followed_id = users.user_id WHERE following.user_id=?', user)
  end
 
  # Fetches all data for a single user
  #
  # @param [Integer] user_id the user's id
  #
  # @return [Hash] the user data
  def fetch_user(user_id)
    db = db() 
    db.execute('SELECT * FROM users WHERE user_id=?', user_id).first
  end
 
  # Fetches all recipes published by a specific user
  #
  # @param [Integer] id the user's id
  #
  # @return [Array<Hash>] the user's recipes
  def users_recipes(id)
    db = db()
    db.execute("SELECT * FROM recipes WHERE user_id=?", id)
  end
 
  # Records that one user follows another
  #
  # @param [Integer] user_id the id of the user who is following
  # @param [Integer] follow_id the id of the user being followed
  #
  # @return [void]
  def follow(user_id, follow_id)
    db = db()
    db.execute('INSERT INTO following (user_id, followed_id) VALUES (?, ?)', [user_id, follow_id])
 
  end
 
  # Removes a follow relationship between two users
  #
  # @param [Integer] id the id of the user being unfollowed
  # @param [Integer] user_id the id of the user who is unfollowing
  #
  # @return [void]
  def unfollow(id, user_id)
    db = db()
    db.execute('DELETE FROM following WHERE user_id LIKE ? AND followed_id LIKE ?', [user_id, id])
  end
 
  # Registers a new user with a hashed password
  #
  # @param [Hash] params the form data
  # @option params [String] user the desired username
  # @option params [String] pwd the password
  # @option params [String] pwd_confirm the password confirmation
  #
  # @return [Boolean] true if registration succeeded
  # @return [String] a redirect path if registration failed
  def add_user(params)
    user = params["user"]
    pwd = params["pwd"]
    pwd_confirm = params["pwd_confirm"]
 
    db = db()
    result = db.execute("SELECT user_id FROM users WHERE username=?", user)
 
    if result.empty?
      if pwd == pwd_confirm
        pwd_digest = BCrypt::Password.create(pwd)
        db.execute("INSERT INTO users(username, pwd_digest) VALUES(?,?)", [user, pwd_digest])
        true
      else
        "/redirect"
      end
    else
      "/login"
    end
  end
 
  # Authenticates a user by username and password
  #
  # @param [Hash] params the form data
  # @option params [String] user the username
  # @option params [String] pwd the password
  #
  # @return [Integer] the user's id if login succeeded
  # @return [Boolean] false if the password was incorrect
  def login(params)
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
      user_id
    else
      false
    end
  end
end