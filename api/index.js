const express = require('express');

const app = express();

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

const port = 3000;

app.listen(port, () => {
  console.log('App is now running at port ', port)
})