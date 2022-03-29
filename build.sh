#!/bin/bash
rm -rf deploy_dir
pushd api
npm run babel
mv post_babel/ ../deploy_dir
popd && pushd deploy_dir
npm install --only=prod
popd

pushd frontend/feedback_app
NODE_ENV=production ./node_modules/.bin/vue-cli-service build --mode prod
mv dist ../../deploy_dir/dist/
popd && pushd deploy_dir
zip ../tf/feedback_app.zip `find .`
