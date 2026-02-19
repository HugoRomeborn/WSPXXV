require 'sqlite3'


def db()
  db = SQLite3::Database.new("db/recepies.db")
  db.results_as_hash = true
  return db
end

def fetch_recepie(id)
  db = db()
  recepie = db.execute("SELECT * FROM recepies WHERE id=?", id)
  ingriedients = db.execute("SELECT * FROM rel_recepie_ingriedients INNER JOIN ingriedients ON rel_recepie_ingriedients.ingriedient_id = ingriedients.id WHERE recepie_id=?", id)

  ingriedients_arr = []
  ingriedients.each do |ingriedient|
    ingriedients_arr << (ingriedient["Amount"] + " " + ingriedient["ingriedient"])
  end
  recepie = recepie[0]
  recepie["ingriedients"] = ingriedients_arr

  return recepie
end