const sqlite3 = require('sqlite3').verbose();

let db = new sqlite3.Database('./users.db', sqlite3.OPEN_READWRITE | sqlite3.OPEN_CREATE, (err) => {
    if (err) {
        console.error(err.message);
    }
    console.log('Connected to the users database.');
});

db.serialize(() => {
  // Создание таблицы пользователей, если она ещё не существует
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password TEXT,
    email TEXT NOT NULL UNIQUE,
    google_id TEXT,
    is_google_account BOOLEAN DEFAULT 0,
    role TEXT NOT NULL
  )`, (err) => {
    if (err) {
        console.error(err.message);
    } else {
        console.log("Table users created or already exists.");
    }
  });

  // Создание таблицы userCities для хранения информации о городах, выбранных пользователями
  db.run(`CREATE TABLE IF NOT EXISTS userCities (
    user_id INTEGER NOT NULL,
    city_id INTEGER NOT NULL,
    city_name TEXT NOT NULL,
    isSelected TEXT NOT NULL,
    FOREIGN KEY(user_id) REFERENCES users(id)
  )`, (err) => {
    if (err) {
        console.error("Error creating table userCities: " + err.message);
    } else {
        console.log("Table userCities created or already exists.");
    }
  });
});

module.exports = db;
