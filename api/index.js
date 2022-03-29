// INIT the database:
// index.js
// const Sequelize = require('sequelize').Sequelize;
// import { createRequire } from "module";
// const require = createRequire(import.meta.url);

// import {Umzug, SequelizeStorage} from 'umzug';

const u = require('umzug');
const Umzug = u.Umzug;
const SequelizeStorage = u.SequelizeStorage;

const sequelize = require('./src/models').sequelize;

// const sequelize = s.sequelize;
const umzug = new Umzug({
  migrations: { glob: './src/database/migrations/*.js' },
  context: sequelize.getQueryInterface(),
  storage: new SequelizeStorage({ sequelize }),
  logger: console,
});

// this isn't running on lambda
(async () => {
  // Checks migrations and run them if they are not already applied. To keep
  // track of the executed migrations, a table (and sequelize model) called SequelizeMeta
  // will be automatically created (if it doesn't exist already) and parsed.
  await umzug.up();
})();


import express from 'express';

const app = express();
if(process.env.NODE_ENV == "development") {
    console.log("Using development environment, CORS enabled");
    const cors = require('cors');
    app.use(cors({
        origin: '*'
    }
    ));
}

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

import MessageController from './src/controllers/MessageController';

// post up a message:
app.post('/add_msg', MessageController.newMessage);
app.get('/messages', MessageController.getMessages);
// Create a catch-all route for testing the installation.
// app.get('*', (req, res) => res.status(200).send({
//   message: 'Hello World!',
// }));

app.use('/static/', express.static(__dirname + '/dist'))
app.use('/js/', express.static(__dirname + '/dist/js'))

const port = 3000;

if(process.env.NODE_ENV == "development") {
  app.listen(port, () => {
    console.log('App is now running at port ', port)
  })
} else if(process.env.NODE_ENV == "production") {
  const serverless = require('serverless-http');
  module.exports.handler = serverless(app);

}