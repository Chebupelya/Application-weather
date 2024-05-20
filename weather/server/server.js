const express = require("express");
const bodyParser = require("body-parser");
const db = require("./database.js");
const bcrypt = require("bcrypt");
const app = express();
const axios = require("axios");
const PORT = 3000;
const HOST = "192.168.197.86";
const API_KEY_2_5 = "702da4137e8a351693cd39f6870d597f";

app.use(bodyParser.json());

app.get("/weatherChart", (req, res) => {
  const userId = req.query.userId;
  const userQuery = `SELECT city_id, city_name FROM userCities WHERE user_id = ? AND isSelected = 1`;

  db.get(userQuery, [userId], async (err, city) => {
    if (err) {
      return res.status(500).send("Error querying city data");
    }

    if (!city) {
      return res.status(404).send("Selected city not found");
    }

    const { city_name } = city;

    try {
      // Get city coordinates
      const response2_5 = await axios.get(
        `https://api.openweathermap.org/data/2.5/weather`,
        {
          params: {
            q: city_name,
            units: "metric",
            appid: API_KEY_2_5,
          },
        }
      );
      const { lon, lat } = response2_5.data.coord;

      // Get weather forecast data
      const forecastResponse = await axios.get(
        `https://api.openweathermap.org/data/3.0/onecall`,
        {
          params: {
            lat: lat,
            lon: lon,
            units: "metric",
            appid: API_KEY_2_5,
          },
        }
      );

      const weatherData = formatForecastData(city_name, forecastResponse.data);

      res.json(weatherData);
    } catch (error) {
      res.status(500).send("Error fetching weather data");
    }
  });
});

// Helper function to format forecast data
function formatForecastData(cityName, data) {
  return {
    cityName: cityName,
    daily: data.daily.map((day) => ({
      date: new Date(day.dt * 1000).toISOString().split("T")[0],
      temperature: {
        day: day.temp.day,
        min: day.temp.min,
        max: day.temp.max,
        night: day.temp.night,
      },
      windSpeed: day.wind_speed,
      humidity: day.humidity,
      cloudiness: day.clouds,
      pressure: day.pressure,
    })),
  };
}

app.get("/guestWeather", async (req, res) => {
  const cityName = req.query.city;
  //console.log(cityName);
  if (!cityName) {
    return res.status(400).json({ error: "City name is required" });
  }

  try {
    const response = await axios.get(
      `https://api.openweathermap.org/data/2.5/weather`,
      {
        params: {
          q: cityName,
          units: "metric",
          appid: API_KEY_2_5,
        },
      }
    );

    const weatherData = {
      name: response.data.name,
      main: response.data.main,
      weather: response.data.weather[0],
      wind: response.data.wind,
    };

    res.json(weatherData);
  } catch (error) {
    if (error.response && error.response.status === 404) {
      res.status(404).json({ error: "City not found" });
    } else {
      res
        .status(500)
        .json({ error: "An error occurred while fetching weather data" });
    }
  }
});

app.post("/googleSignIn", async (req, res) => {
  const { username, sub, email } = req.body;
  try {
    db.get("SELECT * FROM users WHERE email = ?", [email], async (err, row) => {
      if (err) {
        console.error(err.message);
      } else {
        if (row) {
          if (row.google_id) {
            res.status(200).json({
              message: "User logged in successfully",
              user: row,
            });
          } else {
            await db.run(
              "UPDATE users SET google_id = ?, is_google_account = 1 WHERE email = ?",
              [sub, email]
            );
            res.status(200).json({
              message: "User account linked to Google",
              user: row,
            });
          }
        } else {
          await db.run(
            'INSERT INTO users (username, email, google_id, is_google_account, role) VALUES (?, ?, ?, 1, "User")',
            [username, email, sub]
          );
          res.status(200).json({ message: "New user registered via Google" });
        }
      }
    });
  } catch (error) {
    res.status(401).json({ error: "Invalid token" });
  }
});

app.get("/getUserEmail", (req, res) => {
  const username = req.query.username;
  const userQuery = `SELECT email FROM users WHERE username = ?`;

  db.get(userQuery, [username], (err, row) => {
    if (err) {
      return res.status(500).send("Error querying user data");
    }

    if (!row) {
      return res.status(404).send("User not found");
    }

    res.json({ email: row.email });
  });
});

app.get("/checkPassword", (req, res) => {
  const { username, password } = req.query;

  if (!username || !password) {
    return res.status(400).json({ error: "Missing username or password" });
  }

  const query = "SELECT password FROM users WHERE username = ?";
  db.get(query, [username], (err, row) => {
    if (err) {
      console.error("Error querying the database:", err);
      return res.status(500).json({ error: err.message });
    }
    if (row) {
      if (bcrypt.compareSync(password, row.password)) {
        res.json({ message: "success", data: row });
      } else {
        res.status(401).json({ message: "Password incorrect" });
      }
    } else {
      res.status(404).json({ message: "User not found" });
    }
  });
});

app.post("/changePassword", (req, res) => {
  const { username, newPassword } = req.body;

  if (!username || !newPassword) {
    return res.status(400).json({ error: "Missing username or newPassword" });
  }

  bcrypt.hash(newPassword, 10, (err, hashedPassword) => {
    if (err) {
      console.error("Error hashing the password:", err);
      return res.status(500).json({ error: "Internal server error" });
    }

    const query = "UPDATE users SET password = ? WHERE username = ?";
    db.run(query, [hashedPassword, username], (err, results) => {
      if (err) {
        console.error("Error updating the database:", err);
        return res.status(500).json({ error: "Internal server error" });
      }

      res.json({ message: "Password updated successfully" });
    });
  });
});

app.put("/updateUser", async (req, res) => {
  const { name, email } = req.body;
  try {
    await db.run("UPDATE users SET username = ? WHERE email = ?", [
      name,
      email,
    ]);
    res.send({ message: "User updated successfully" });
  } catch (error) {
    console.error("Failed to update user:", error);
    res.status(500).send({ message: "Failed to update user" });
  }
});

app.get("/users", (req, res) => {
  const query = "SELECT id, username, email FROM users";
  db.all(query, (err, results) => {
    if (err) {
      console.error("Error querying the database:", err);
      return res.status(500).json({ error: "Internal server error" });
    }
    res.json(results);
  });
});

app.delete("/users/:id", (req, res) => {
  const userId = req.params.id;
  const query = "DELETE FROM users WHERE id = ?";
  db.get(query, [userId], (err, row) => {
    if (err) {
      console.error("Error deleting user:", err);
      return res.status(500).json({ error: "Internal server error" });
    }
    if (row) {
      if (result.affectedRows === 0) {
        return res.status(404).json({ error: "User not found" });
      }
    } else {
      res.status(404).json({ message: "User not found" });
    }
  });

  db.run(query, [userId], (err, result) => {
    if (err) {
      console.error("Error deleting user:", err);
      return res.status(500).json({ error: "Internal server error" });
    }
    console.log(result);
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "User not found" });
    }
    res.json({ message: "User deleted successfully" });
  });
});

// Маршрут для авторизации
app.post("/login", (req, res) => {
  const { username, password } = req.body;
  const sql = "SELECT * FROM users WHERE username = ?";
  db.get(sql, [username], (err, row) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    if (row && bcrypt.compareSync(password, row.password)) {
      res.json({ message: "success", data: row });
    } else {
      res.status(404).json({ message: "User not found or password incorrect" });
    }
  });
});

// Маршрут для регистрации
app.post("/register", (req, res) => {
  const { username, email, password } = req.body;
  const hashedPassword = bcrypt.hashSync(password, 10); // Хэширование пароля

  const sql = `INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, 'User')`;
  db.run(sql, [username, email, hashedPassword], function (err) {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    console.log("2");
    res.json({ message: "User registered successfully", id: this.lastID });
  });
});

app.get("/userCities", async (req, res) => {
  const { userId } = req.query;
  if (!userId) {
    return res.status(400).json({ error: "User ID is required" });
  }

  const sql = "SELECT city_name, isSelected FROM userCities WHERE user_id = ?";
  db.all(sql, [userId], async (err, rows) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    try {
      const cityDataPromises = rows.map(async (row) => {
        const cityName = row.city_name;
        const isSelected = row.isSelected;

        const response2_5 = await axios.get(
          `https://api.openweathermap.org/data/2.5/weather`,
          {
            params: {
              q: cityName,
              units: "metric",
              appid: API_KEY_2_5,
            },
          }
        );

        const { lon, lat } = response2_5.data.coord;
        const weatherData = {
          temperature: response2_5.data.main.temp,
          description: response2_5.data.weather[0].description,
          icon: response2_5.data.weather[0].icon,
        };
        const cityId = response2_5.data.id;

        return {
          isSelected: isSelected,
          cityName: cityName,
          cityId: cityId,
          coordinates: { lon, lat },
          weather: weatherData,
        };
      });

      const cityData = await Promise.all(cityDataPromises);
      res.json({
        message: "Success",
        data: cityData,
      });
    } catch (apiError) {
      res.status(500).json({ error: apiError.message });
    }
  });
});

// Маршрут для получения ID пользователя по имени
app.get("/getUserId", (req, res) => {
  const { username } = req.query;
  if (!username) {
    return res.status(400).json({ error: "Username parameter is required" });
  }

  const sql = "SELECT id FROM users WHERE username = ?";
  db.get(sql, [username], (err, row) => {
    if (err) {
      res.status(500).json({ error: err.message });
    } else if (row) {
      res.json({ message: "User found", userId: row.id });
    } else {
      res.status(404).json({ message: "User not found" });
    }
  });
});

app.post("/addCityToUser", (req, res) => {
  const { userId, cityId, cityName } = req.body;
  const sqlCheck =
    "SELECT city_id FROM userCities WHERE user_id = ? AND city_id = ?";
  const sqlInsert =
    "INSERT INTO userCities (user_id, city_id, city_name, isSelected) VALUES (?, ?, ?, 0)";

  db.get(sqlCheck, [userId, cityId], (err, row) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (row) {
      return res.status(409).json({ message: "City already added" });
    }

    db.run(sqlInsert, [userId, cityId, cityName], function (err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ message: "City added successfully", id: this.lastID });
    });
  });
});

app.post("/getAddedCities", (req, res) => {
  const userId = req.body.userId; // Получение ID пользователя из тела запроса

  console.log(userId);
  // SQL запрос для получения списка ID городов, добавленных пользователем
  const sql = "SELECT * FROM userCities WHERE user_id = ?";

  db.all(sql, [userId], (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    console.log(rows);
    // Возвращаем список ID городов
    //const cityIds = rows.map((row) => row.city_id);
    //console.log(cityIds);
    res.json({ message: "Success", cities: rows });
  });
});

app.post("/setSelectedCity", (req, res) => {
  const { userId, cityId } = req.body;
  console.log(userId);
  console.log(cityId);
  try {
    db.run("UPDATE userCities SET isSelected = 0 WHERE user_id = ?", [userId]);

    db.run(
      "UPDATE userCities SET isSelected = 1 WHERE user_id = ? AND city_id = ?",
      [userId, cityId]
    );

    res.json({ message: "Selection updated successfully" });
    console.log({ message: "Selection updated successfully" });
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error updating selection", error: error.message });
  }
});

app.get("/weather", (req, res) => {
  const userId = req.query.userId;
  const userQuery = `SELECT city_id, city_name FROM userCities WHERE user_id = ? AND isSelected = 1`;
  db.get(userQuery, [userId], async (err, city) => {
    if (err) {
      return res.status(500).send("Error querying city data");
    }

    if (!city) {
      return res.status(404).send("Selected city not found");
    }

    const { city_name } = city;
    try {
      const response2_5 = await axios.get(
        `https://api.openweathermap.org/data/2.5/weather`,
        {
          params: {
            q: city_name,
            units: "metric",
            appid: API_KEY_2_5,
          },
        }
      );
      const { lon, lat } = response2_5.data.coord;

      const weatherResponse = await axios.get(
        `https://api.openweathermap.org/data/3.0/onecall`,
        {
          params: {
            lat: lat,
            lon: lon,
            units: "metric",
            appid: API_KEY_2_5,
          },
        }
      );

      const weatherData = formatWeatherData(city_name, weatherResponse.data);

      res.json(weatherData);
    } catch (error) {
      res.status(500).send("Error fetching weather data");
    }
  });
});

app.get("/dailyWeather", (req, res) => {
  const userId = req.query.userId;
  const userQuery = `SELECT city_id, city_name FROM userCities WHERE user_id = ? AND isSelected = 1`;
  db.get(userQuery, [userId], async (err, city) => {
    if (err) {
      return res.status(500).send("Error querying city data");
    }

    if (!city) {
      return res.status(404).send("Selected city not found");
    }

    const { city_name } = city;
    try {
      const response2_5 = await axios.get(
        `https://api.openweathermap.org/data/2.5/weather`,
        {
          params: {
            q: city_name,
            units: "metric",
            appid: API_KEY_2_5,
          },
        }
      );
      const { lon, lat } = response2_5.data.coord;

      const weatherResponse = await axios.get(
        `https://api.openweathermap.org/data/3.0/onecall`,
        {
          params: {
            lat: lat,
            lon: lon,
            units: "metric",
            appid: API_KEY_2_5,
          },
        }
      );

      const weatherData = formatDailyWeatherData(weatherResponse.data);

      res.json(weatherData);
    } catch (error) {
      res.status(500).send("Error fetching weather data");
    }
  });
});

const formatDailyWeatherData = (data) => {
  const now = new Date();
  const currentHour = now.getHours();

  const hours = Array.from(
    { length: 24 },
    (_, i) => ((currentHour + i) % 24).toString().padStart(2, "0") + ":00"
  );

  const todayHourlyData = data.hourly.slice(0, 24).map((hour) => ({
    temp: `${Math.round(hour.temp)}°C`,
    img: `assets/img/${hour.weather[0].icon}.png`,
  }));

  const dailyData = data.daily.slice(0, 7).map((day) => ({
    main_temp: `${Math.round(day.temp.day)}°C`,
    main_img: `assets/img/${day.weather[0].icon}.png`,
  }));

  const formattedData = {
    day_weather: [
      {
        main_temp: `${Math.round(data.current.temp)}°C`,
        main_img: `assets/img/${data.current.weather[0].icon}.png`,
        all_time: {
          hour: hours,
          img: todayHourlyData.map((item) => item.img),
          temps: todayHourlyData.map((item) => item.temp),
        },
      },
    ],
    week_weather: [
      {
        main_temp: dailyData.map((item) => item.main_temp),
        main_img: dailyData.map((item) => item.main_img),
      },
    ],
  };

  return [formattedData];
};

const formatWeatherData = (cityName, data) => {
  const now = new Date();
  const currentHour = now.getHours();

  const hours = Array.from(
    { length: 24 },
    (_, i) => ((currentHour + i) % 24).toString().padStart(2, "0") + ":00"
  );

  const todayHourlyData = data.hourly.slice(0, 24).map((hour) => ({
    temp: `${Math.round(hour.temp)}°C`,
    wind: `${Math.round(hour.wind_speed)} km/h`,
    img: `assets/img/${hour.weather[0].icon}.png`,
  }));

  const formattedData = {
    name: cityName,
    weekly_weather: [
      {
        main_temp: `${Math.round(data.current.temp)}°C`,
        main_wind: `${Math.round(data.current.wind_speed)} km/h`,
        main_humidity: `${Math.round(data.current.humidity)}%`,
        main_img: `assets/img/${data.current.weather[0].icon}.png`,
        all_time: {
          hour: hours,
          wind: todayHourlyData.map((item) => item.wind),
          img: todayHourlyData.map((item) => item.img),
          temps: todayHourlyData.map((item) => item.temp),
        },
      },
    ],
  };

  return [formattedData];
};

app.delete("/deleteCityFromUser", (req, res) => {
  const { userId, cityId } = req.body;

  if (!userId || !cityId) {
    return res.status(400).send("User ID and City ID are required");
  }

  const deleteQuery = `DELETE FROM userCities WHERE user_id = ? AND city_id = ?`;

  db.run(deleteQuery, [userId, cityId], function (err) {
    if (err) {
      return res.status(500).send("Error deleting city from user");
    }

    if (this.changes === 0) {
      return res.status(404).send("City not found for the user");
    }

    res.status(200).send("City deleted from user successfully");
  });
});

app.listen(PORT, HOST, () => {
  console.log(`Server running on http://${HOST}:${PORT}`);
});
