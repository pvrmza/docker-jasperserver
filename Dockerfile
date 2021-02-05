FROM tomcat:9.0-jre8
MAINTAINER Pablo Vargas <pablo@pampa.cloud>

ENV JASPERSERVER_VERSION 7.2.0

#### Execute all in one layer so that it keeps the image as small as possible
RUN wget "https://sourceforge.net/projects/jasperserver/files/JasperServer/JasperReports%20Server%20Community%20Edition%20${JASPERSERVER_VERSION}/TIB_js-jrs-cp_${JASPERSERVER_VERSION}_bin.zip/download" \
         -O /tmp/jasperserver.zip  && \
    unzip /tmp/jasperserver.zip -d /usr/src/ && \
    rm /tmp/jasperserver.zip && \
    mv /usr/src/jasperreports-server-cp-${JASPERSERVER_VERSION}-bin /usr/src/jasperreports-server && \
    rm -rf /usr/src/jasperreports-server/samples


# Add WebServiceDataSource plugin
RUN wget https://community.jaspersoft.com/sites/default/files/releases/jaspersoft_webserviceds_v1.5.zip -O /tmp/jasper.zip && \
    unzip /tmp/jasper.zip -d /tmp/ && \
    cp -rfv /tmp/JRS/WEB-INF/* /usr/local/tomcat/webapps/ROOT/WEB-INF/ && \
    sed -i 's/queryLanguagesPro/queryLanguagesCe/g' /usr/local/tomcat/webapps/ROOT/WEB-INF/applicationContext-WebServiceDataSource.xml && \
    rm -rf /tmp/*

#
ADD files/wait-for-it.sh /
ADD  files/entrypoint.sh /

#Execute all in one layer so that it keeps the image as small as possible
RUN chmod a+x /entrypoint.sh && \
    chmod a+x /wait-for-it.sh && \
    echo "# If this file is present, then the JasperServer container will bootstrapp itself on startup." > /.do_deploy_jasperserver

# This volume allows JasperServer export zip files to be automatically imported when bootstrapping
VOLUME ["/jasperserver-import"]

# 
ADD drivers/db2jcc4-no-pdq-in-manifest.jar  /usr/src/jasperreports-server/buildomatic/conf_source/db/app-srv-jdbc-drivers/
ADD drivers/mysql-connector-java-5.1.44-bin.jar /usr/src/jasperreports-server/buildomatic/conf_source/db/app-srv-jdbc-drivers/


# Copy web.xml with cross-domain enable
ADD files/web.xml /usr/local/tomcat/conf/

# script_applicationContext-externalAuth-LDAP.xml witch AD support !! 
ADD files/sample-applicationContext-externalAuth-LDAP.xml /usr/src/sample-applicationContext-externalAuth-LDAP.xml

# Use the minimum recommended settings to start-up
# as per http://community.jaspersoft.com/documentation/jasperreports-server-install-guide/v561/setting-jvm-options-application-servers
ENV JAVA_OPTS="-Xms1024m -Xmx2048m -XX:PermSize=32m -XX:MaxPermSize=512m -Xss2m -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled"

# Wait for DB to start-up, start up JasperServer and bootstrap if required
ENTRYPOINT ["/entrypoint.sh"]
