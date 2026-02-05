require 'sqlite3'

db = SQLite3::Database.new("recepies.db")


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
  db.execute('DROP TABLE IF EXISTS recepies')
end

def create_tables(db)
  db.execute('CREATE TABLE recepies (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL, 
              description TEXT,
              ingriedients TEXT,
              instructions TEXT)')
end

def populate_tables(db)
  db.execute('INSERT INTO recepies (title, description, ingriedients, instructions) VALUES ("Pannkakor", "En klassisk svensk maträtt. kan serveras med grädde och sylt","2 1/2 dl mjöl \n3 st ägg \n6 dl mjölk", "Blanda mjöl och salt i en bunke. Vispa i hälften av mjölken och vispa till en slät smet. Vispa i resten av mjölken och äggen. Låt smeten vila ca 10 minuter. \nStek tunna pannkakor i lite smör, för varje pannkaka, i en stek- eller pannkakspanna.")')
  
end


seed!(db)





