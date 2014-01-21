# This file is managed through Puppet; changes made manually will be lost

DATE=`date +%Y%m%d%H%M%S`
WWWROOT='/var/www'
REPOFOLDER='/var/www/repo'
GITPULL=$1
WORKER=$2
DEPLOYMENTENVIRONMENT=$3
NEWRELICKEY=$4
NEWRELICAPPNAME=$5

# Pull if it's a manually run, and not puppet controller
if [ "$1" = 1 ]; then
    cd $REPOFOLDER
    git checkout -- .
    git pull
fi;

# Prepare the build
mkdir $WWWROOT/deployments/$DATE
cp -r $REPOFOLDER/vendor/ $WWWROOT/deployments/$DATE/vendor/
cp -r $REPOFOLDER/src/ $WWWROOT/deployments/$DATE/src/

if [ "$WORKER" = 0 ]; then

    # Backup the db
    php $WWWROOT/deployments/$DATE/src/private/console backup:database

    ## Phinx
    php $REPOFOLDER/bin/phinx migrate -c $REPOFOLDER/phinx.yml -e $DEPLOYMENTENVIRONMENT
fi

# Make live
unlink $WWWROOT/deployment/vendor
unlink $WWWROOT/deployment/src

ln -s $WWWROOT/deployments/$DATE/vendor/ $WWWROOT/deployment/vendor
ln -s $WWWROOT/deployments/$DATE/src/ $WWWROOT/deployment/src

# Tell NewRelic about the deployment
if [ -z "$NEWRELICKEY" ]; then
    curl -H "x-api-key:$NEWRELICKEY" -d "deployment[app_name]=$NEWRELICAPPNAME" https://api.newrelic.com/deployments.xml
fi
