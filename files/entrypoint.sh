#!/bin/bash
set -e

# wait upto 30 seconds for the database to start before connecting
/wait-for-it.sh $JSR_DB_HOST:$JSR_DB_PORT -t 30

# check if we need to bootstrap the JasperServer
if [ -f "/.do_deploy_jasperserver" ]; then
    pushd /usr/src/jasperreports-server/buildomatic
    
    # Use provided configuration templates
    # Note: only works for Postgres or MySQL
    cp sample_conf/${JSR_DB_TYPE}_master.properties default_master.properties
    
    # tell the bootstrap script where to deploy the war file to
    sed -i -e "s|^appServerDir.*$|appServerDir = $CATALINA_HOME|g" default_master.properties
    
    # set all the database settings
    sed -i -e "s|^dbHost.*$|dbHost=$JSR_DB_HOST|g; s|^dbPort.*$|dbPort=$JSR_DB_PORT|g; s|^dbUsername.*$|dbUsername=$JSR_DB_USER|g; s|^dbPassword.*$|dbPassword=$JSR_DB_PASSWORD|g" default_master.properties
    
    # rename the application war so that it can be served as the default tomcat web application
    sed -i -e "s|^# webAppNameCE.*$|webAppNameCE = ROOT|g" default_master.properties

    if test ! -z $JSR_AD_URL; then 
        sed -i -e "s|^# external.ldapUrl.*$|external.ldapUrl=$JSR_AD_URL|g; s|^# external.ldapDn.*$|external.ldapDn=$JSR_AD_BIND_DN|g; s|^# external.ldapPassword.*$|external.ldapPassword=$JSR_AD_BIND_PASS|g" default_master.properties
    fi

    # run the minimum bootstrap script to initial the JasperServer
    ./js-ant create-js-db || true #create database and skip it if database already exists
    ./js-ant init-js-db-ce 
    ./js-ant import-minimal-ce 
    ./js-ant deploy-webapp-ce

    # bootstrap was successful, delete file so we don't bootstrap on subsequent restarts
    rm /.do_deploy_jasperserver
    
    # FIX Error Closing Context 
    echo "tbeller.usejndi=false" >> /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/resfactory.properties

    # ExternalAuth LDAP
    if test ! -z $JSR_AD_URL; then 
        cp /usr/src/sample-applicationContext-externalAuth-LDAP.xml /usr/local/tomcat/webapps/ROOT/WEB-INF/applicationContext-externalAuth-LDAP.xml
    fi

    # import any export zip files from another JasperServer

    shopt -s nullglob # handle case if no zip files found

    IMPORT_FILES=/jasperserver-import/*.zip
    for f in $IMPORT_FILES
    do
      echo "Importing $f..."
      ./js-import.sh --input-zip $f
    done

    popd
fi

# run Tomcat to start JasperServer webapp
catalina.sh run
