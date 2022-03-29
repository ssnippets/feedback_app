require('dotenv').config(); // this is important!
module.exports = 
  {
    "development": {
      "username": "exampleuser",
      "password": "examplepass",
      "database": "exampledb",
      "port": "5432",
      "host": "db",
      "dialect": "postgres"

    },
    "remote": {
      "username": "lambdauser",
      "password": process.env.DBPASS,
      "database": "database_production",
      "port": "5432",
      "host": "18.191.2.47",
      "dialect": "postgres"
    },
    "production": {
      "username": process.env.POSTGRES_USER,
      "password": process.env.POSTGRES_PASSWORD,
      "database": process.env.POSTGRES_DB,
      "host": process.env.POSTGRES_HOST,
      "port": process.env.POSTGRES_PORT,
      "dialect": "postgres"
    }
  }