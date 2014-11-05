# Production

Run:

    foreman s -f Procfile

# Testing

Run:

    rake test:all

# Performance Testing

Run:

    foreman s -f Procfile.performance

## Setting up Greenmail

1. Download Tomcat 8.0 and unzip. http://tomcat.apache.org/download-80.cgi
2. Download the Greenmail Webapp SAR, place it in TOMCAT_HOME/webapps (http://www.icegreen.com/greenmail/download.html)
3. Run: chmod 755 bin/*
4. Run: bin/catalina.sh run
5. Stop the server.
6. Move config/tomcat/web.xml into TOMCAT_HOME/webapps/greenmail-webapp-1.4.0/WEB-INF
7. Run: export JAVA_HOME=`/usr/libexec/java_home`
8. Run: bin/catalina.sh run
