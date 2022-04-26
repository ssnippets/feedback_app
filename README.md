**Development Environment**

The easiest way to get started with a local environment is to spin up the docker stack using:
 
 `docker compose -f stack.yml up`

 This will launch:
 * A postgresql container
 * A built container using the Dockerfile in the `api` folder
    * NOTE: This container relies on the dist folder to serve up a static version of the frontend

To launch the frontend for development, use:

`cd frontend/feedback_app && npm run serve`

The frontend should now be available at http://localhost:8080

***Deployment***

Prerequisites:
* Terraform
* aws keys set up in ~/.aws/credentials
* node and npm 
* npm install on both the `api` and `frontend/feedback_app` folders
* Terraform Variables need to be set
* An SMTP service needs to be set up for email
* sequelize-cli installed (`npm install -g sequelize-cli`)

To set up the terraform variables (this needs to be done before the first deployment):
1. `cd tf`
2. `cp variables.tf.template variables.tf`
3. populate variables appropriately, specifically, desired credentials for the database as well as the smtp service. The default messages can also be configured in this file.

The steps are:
1. building the app
2. deploying it
3. running migrations (this is currently not automated)

To `Build`, go to the root folder and run `bash build.sh`.

To `Deploy`, from the root folder: `cd tf && terraform apply`. Terraform will then start its process of checking the state in aws and deploying. 

To `Run Migrations`, from the root:

* `cd api` 
* run something similar to:
`NODE_ENV=remote DB_PASS='PASSWORD_SET_IN_VARIABLE_TF_FOR_DB_PASS' DB_HOST='HOST_FROM_TERRAFORM_OUTPUT' sequelize-cli db:migrate --config ./src/config/config.js`

***Architecture***
The deployed environment consists of two "major" moving parts:
1. the database
2. the lambda function

To ease deployment and maintenance, the frontend is statically built and served in the same lambda function that the rest of the API is served from. 