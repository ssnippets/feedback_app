./node_modules/.bin/vue-cli-service build --mode prod
rm -rf ../../api/dist/
mv dist ../../api/dist/
