require 'sqlite3'
require 'bcrypt'
module Model

  # Creates a connection with the database  
  #
  # @return [SQLite3::Database] containing Database connection
  def db()
    db = SQLite3::Database.new("db/recipes.db")
    db.results_as_hash = true
    return db
  end


  # Searches the id in the database for any matching recipe and fetches that information and related information from rel_recipe_ingredients table as well as the ingredients table
  #
  # @param [integer] id recipe id
  # @option params [String] search_terms
  #
  # @return [hash] containing the data for the matching recipe
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

  
  # Attempts to update the information in the recipe table, rel_recipe_ingredients table and ingredients table
  #
  # @param [Hash] recipe form data 
  # @option recipe [id] Recipe id
  # @option recipe [title] title
  # @option recipe [description] description of recipe
  # @option recipe [instructions] Recipe instructions
  # @option recipe [ingredients] array of ingredients (hashes)
  #
  # @return [Array] containing the data of all matching articles
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

  # Fixar radbryt efter sql och forms
  def fix_linebreaks(text)
    text.split('\r\n')
  end

  # Raderar receptet samt bild och innehållet i relationstabellen för ingredienser
  # Tar receptets id som input och ger ingen return
  def delete_recipe(id) 
    db = db()
    image = db.execute('SELECT image_link FROM recipes WHERE id LIKE ?', id)
    db.execute("DELETE FROM recipes WHERE id LIKE ?", id)
    db.execute("DELETE FROM rel_recipe_ingredients WHERE recipe_id LIKE ?", id)
    File.delete("public#{image[0]["image_link"]}")
  end

  # Funktionen hämtar alla recept utan ingredienser, de behövs inte för syftet. 
  # Tar ingen input och returnerar en array av recept
  def all_recipes()
    db = db()
    db.execute("SELECT * FROM recipes")
  end

  # Attempts to create a new recipe in the recipe table, rel_recipe_ingredients table and ingredients table
  #
  # @param [Hash] recipe form data 
  # @param [Hash] user
  # @option recipe [integer] Recipe id
  # @option recipe [string] title title
  # @option recipe [string] description description of recipe
  # @option recipe [string] instructions Recipe instructions
  # @option recipe [array] ingredients array of ingredients (hashes)
  # @option user [integer] user_id id of user 
  # @option user [string] username username 
  # @option user [string] pwd_digest encrypted password of user
  #
  # @return [Array] containing the data of all matching articles
  def add_recipe(recipe, user)
    db = db()

    if params[:image] && params[:image][:filename]
      filename = params[:image][:filename].split(".")
      file = params[:image][:tempfile]
      i = 0
      # Indexerar bilderna så att det alltid blir en unik fil oavsett om de har samma namn
      while File.exist?("./public/IMG/user_images/#{filename[0] + i.to_s + "." + filename[1]}")
        i +=1
      end
      # Sparar bilden i directory 'IMG/user_images'
      File.open("./public/IMG/user_images/#{filename[0] + i.to_s + "." + filename[1]}", 'wb') do |f|
        f.write(file.read)
      end  
    end

    db.execute('INSERT INTO recipes (title, description, instructions, user_id, image_link) VALUES (?, ?, ?, ?, ?)', [recipe["title"], recipe["description"], recipe["instructions"], user["user_id"], "/IMG/user_images/#{filename[0] + i.to_s + "." + filename[1]}"])

    id = db.execute('SELECT id FROM recipes WHERE title=? AND user_id=?', [recipe["title"], user["user_id"]])
    id = id.first["id"]

    #Lägger till ingredienser
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

  #en funktion som hämtar alla en användares följare
  # Tar användarens id som argument och returnerar en array med personer som följer användaren. 
  def followers(user)
    db = db()
    db.execute('SELECT * FROM following INNER JOIN users ON following.user_id = users.user_id WHERE followed_id=?', user)
  end

  #en funktion som hämtar alla en användare följer
  # Tar användarens id som argument och returnerar en array med personer som användaren följer. 
  def follows(user)
    db = db()
    db.execute('SELECT * FROM following INNER JOIN users ON following.followed_id = users.user_id WHERE following.user_id=?', user)
  end

  # Hämtar all information om en användare, returnerar informationen
  def fetch_user(user_id)
    db = db() 
    db.execute('SELECT * FROM users WHERE user_id=?', user_id).first
  end

  #Tar fram basal information om alla  recept en användare har publicerat
  #tar användarens id som argument och returnerar en array av recept-hashes
  def users_recipes(id)
    db = db()
    db.execute("SELECT * FROM recipes WHERE user_id=?", id)
  end

  # En funktion som lägger till informationen om att användaren följer en annan användare
  # Tar användarnas id som argument och ger ingen return
  def follow(user_id, follow_id)
    db = db()
    db.execute('INSERT INTO following (user_id, followed_id) VALUES (?, ?)', [user_id, follow_id])

  end

  # En funktion som lägger till informationen om att användaren följer en annan användare
  # Tar användarnas id som argument och ger ingen return
  def unfollow(id, user_id)
    db = db()
    db.execute('DELETE FROM following WHERE user_id LIKE ? AND followed_id LIKE ?', [user_id, id])
  end

  # Registrerar en ny användare, Kollar om personen redan finns och om pwd och pwd_confirm är samma, sparar i db med krypterat lösenord användandes BCrypt2, Returnerar true om allt gick rätt, annars returnerar den vilken sökväg som ska användas
  # Tar params innehållandes användarnamn, lösenord och lösenordskonfirmering som argument
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

  # Loggar in användaren och konrollerar först att användarnamn och lösenord är korrekt
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