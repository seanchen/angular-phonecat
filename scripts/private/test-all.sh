#!/bin/sh

set -ex

cleanUp () {
  kill $WEBSERVER_PID
  git checkout -f $BRANCH
}

trap cleanUp EXIT

# Define reasonable set of browsers in case we are running manually from commandline
if [[ -z "$BROWSERS" ]]
then
  BROWSERS="Chrome"
fi

if [[ -z "$BROWSERS_E2E" ]]
then
  BROWSERS_E2E="Chrome"
fi

ROOT_DIR=`dirname $0`/../..

cd $ROOT_DIR
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Ensure that all the dependencies are there
npm install

# Ensure that the chromeDriver is installed
npm run update-webdriver

# Start up the web server
node_modules/.bin/http-server -p 8000 &
WEBSERVER_PID=$!

# Run the unit and e2e tests
for i in $(seq 12)
do
  git checkout -f step-$i

  node_modules/karma/bin/karma start test/karma.conf.js --single-run --browsers=$BROWSERS
  node_modules/.bin/protractor test/protractor-conf.js --browser=$BROWSERS_E2E

done
