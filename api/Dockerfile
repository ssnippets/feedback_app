FROM node:alpine
COPY . /app

WORKDIR /app

RUN npm install -g nodemon && npm install

EXPOSE 3000

CMD ["nodemon", "--exec", "babel-node", "index.js"]