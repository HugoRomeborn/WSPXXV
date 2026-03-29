require 'sqlite3'

db = SQLite3::Database.new("recipes.db")


def seed!(db)
  puts "Using db file: db/todos.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS recipes')
  db.execute('DROP TABLE IF EXISTS ingredients')
  db.execute('DROP TABLE IF EXISTS rel_recipe_ingredients')
  db.execute('DROP TABLE IF EXISTS users')
  db.execute('DROP TABLE IF EXISTS following')
end

def create_tables(db)
  db.execute('CREATE TABLE recipes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL, 
              description TEXT,
              instructions TEXT,
              user_id INTEGER NOT NULL)')
  db.execute('CREATE TABLE ingredients (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ingredient TEXT NOT NULL)')
  db.execute('CREATE TABLE rel_recipe_ingredients (
              recipe_id INTEGER NOT NULL,
              ingredient_id INTEGER NOT NULL,
              amount TEXT)')
  db.execute('CREATE TABLE users (
              user_id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL,
              pwd_digest TEXT NOT NULL)')
  db.execute('CREATE TABLE following (
              user_id INTEGER NOT NULL,
              followed_id INTEGER NOT NULL)')
end

def populate_tables(db)
  db.execute('INSERT INTO recipes (title, description, instructions, user_id) VALUES ("Pannkakor", "En klassisk svensk maträtt. Kan serveras med grädde och sylt", "Blanda mjöl och salt i en bunke. Vispa i hälften av mjölken och vispa till en slät smet. Vispa i resten av mjölken och äggen. \r\nLåt smeten vila ca 10 minuter. Stek tunna pannkakor med lite smör för varje pannkaka i en stek- eller pannkakspanna.", 1)')

  db.execute('INSERT INTO ingredients (ingredient) VALUES ("mjöl")')
  db.execute('INSERT INTO ingredients (ingredient) VALUES ("mjölk")')
  db.execute('INSERT INTO ingredients (ingredient) VALUES ("ägg")')
  db.execute('INSERT INTO ingredients (ingredient) VALUES ("salt")')

  db.execute('INSERT INTO rel_recipe_ingredients (recipe_id, ingredient_id, amount) VALUES (1, 1, "3 dl")')
  db.execute('INSERT INTO rel_recipe_ingredients (recipe_id, ingredient_id, amount) VALUES (1, 2, "6 dl")')
  db.execute('INSERT INTO rel_recipe_ingredients (recipe_id, ingredient_id, amount) VALUES (1, 3, "3 st")')
  db.execute('INSERT INTO rel_recipe_ingredients (recipe_id, ingredient_id, amount) VALUES (1, 4, "1 nypa")')
end


seed!(db)