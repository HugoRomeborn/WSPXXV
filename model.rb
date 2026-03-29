require 'sqlite3'


def db()
  db = SQLite3::Database.new("db/recipes.db")
  db.results_as_hash = true
  return db
end

def fetch_recipe(id)
  db = db()
  recipe = db.execute("SELECT * FROM recipes WHERE id=?", id)
  ingredients = db.execute("SELECT * FROM rel_recipe_ingredients INNER JOIN ingredients ON rel_recipe_ingredients.ingredient_id = ingredients.id WHERE recipe_id=?", id)

  ingredients_arr = []
  ingredients.each do |ingredient|
    ingredients_arr << {"amount" => ingredient["amount"], "ingredient" => ingredient["ingredient"]}
  end
  recipe = recipe[0]
  recipe["ingredients"] = ingredients_arr
  return recipe
end

def update_recipe(recipe)
  db = db()

  db.execute("UPDATE recipes SET title=?, description=?, instructions=? WHERE id=?", [recipe["title"], recipe["description"], recipe["instructions"]])


  db.execute("DELETE FROM rel_recipe_ingredients WHERE recipe_id LIKE ?", recipe["id"])
  p recipe
  ingredients = recipe["ingredients"]
  p ingredients
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

def fix_linebreaks(text)
  p text
  new_str = text.split('\r\n')
  p new_str
  new_str
end

def delete_recipe(id) 
  db = db()
  db.execute("DELETE FROM recipes WHERE id LIKE ?", id)
  db.execute("DELETE FROM rel_recipe_ingredients WHERE recipe_id LIKE ?", id)
end

def all_recipes()
  db = db()
  db.execute("SELECT * FROM recipes")
end

def add_recipe(recipe)
  db = db()

  db.execute('INSERT INTO recipes (title, description, instructions) VALUES (?, ?,  ?)', [recipe["title"], recipe["description"], recipe["instructions"]])

  id = db.execute('SELECT id FROM recipes WHERE title=?', recipe["title"])
  id = id.first["id"]

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