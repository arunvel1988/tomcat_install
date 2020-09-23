#!/bin/bash
#set -x
#install tomcat on ubuntu, shell script by arun
echo "which version of tomcat do you want to install"
read vs

echo $vs

echo "enter minor version"
read version
#version = 9.0.38
TOMCAT_URL="https://mirrors.estointernet.in/apache/tomcat/tomcat-${vs}/v${version}/bin/apache-tomcat-${version}.tar.gz"

#https://mirrors.estointernet.in/apache/tomcat/tomcat-9/v9.0.38/bin/apache-tomcat-9.0.38.tar.gz

#https://mirrors.estointernet.in/apache/tomcat/tomcat-9/9.0.38/bin/apache-tomcat-9.0.38.tar.gz


echo $JAVA_HOME


check_java () {
    if [ -z ${JAVA_HOME} ]
    then
        echo 'Could not find JAVA_HOME. Please install Java and set JAVA_HOME'        
        exit
    else 
        echo 'JAVA_HOME found: '$JAVA_HOME 
             
    fi
}
check_java


echo $TOMCAT_URL

echo 'Installing tomcat server...'



echo 'Downloading tomcat-${vs}...'
if [ ! -f /etc/apache-tomcat-${version}.tar.gz ]
then
    curl -O $TOMCAT_URL
fi
echo 'Finished downloading...'

echo 'Creating install directories...'

echo $vs
sudo mkdir -p "/opt/tomcat/9"

if [ -d "/opt/tomcat/${vs}" ]
then
    echo 'Extracting binaries to install directory...'
    sudo tar xzf apache-tomcat-${version}.tar.gz -C "/opt/tomcat/${vs}" --strip-components=1
    echo 'Creating tomcat user group...'
    sudo groupadd tomcat
    sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
    
    echo 'Setting file permissions...'
    cd "/opt/tomcat/9"
    sudo chgrp -R tomcat "/opt/tomcat/${vs}"
    sudo chmod -R g+r conf
    sudo chmod -R g+x conf

    # This should be commented out on a production server
    sudo chmod -R g+w conf

    sudo chown -R tomcat webapps/ work/ temp/ logs/

    echo 'Setting up tomcat service...'
    sudo touch tomcat.service
    sudo chmod 777 tomcat.service 
    echo "[Unit]" > tomcat.service
    echo "Description=Apache Tomcat Web Application Container" >> tomcat.service
    echo "After=network.target" >> tomcat.service

    echo "[Service]" >> tomcat.service
    echo "Type=forking" >> tomcat.service

    echo "Environment=JAVA_HOME=$JAVA_HOME" >> tomcat.service
    echo "Environment=CATALINA_PID=/opt/tomcat/${vs}/temp/tomcat.pid" >> tomcat.service
    echo "Environment=CATALINA_HOME=/opt/tomcat/${vs}" >> tomcat.service
    echo "Environment=CATALINA_BASE=/opt/tomcat/${vs}" >> tomcat.service
    echo "Environment=CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC" >> tomcat.service
    echo "Environment=JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom" >> tomcat.service

    echo "ExecStart=/opt/tomcat/${vs}/bin/startup.sh" >> tomcat.service
    echo "ExecStop=/opt/tomcat/${vs}/bin/shutdown.sh" >> tomcat.service

    echo "User=tomcat" >> tomcat.service
    echo "Group=tomcat" >> tomcat.service
    echo "UMask=0007" >> tomcat.service
    echo "RestartSec=10" >> tomcat.service
    echo "Restart=always" >> tomcat.service

    echo "[Install]" >> tomcat.service
    echo "WantedBy=multi-user.target" >> tomcat.service

    sudo mv tomcat.service /etc/systemd/system/tomcat.service
    sudo chmod 755 /etc/systemd/system/tomcat.service
    sudo systemctl daemon-reload
    
    echo 'Starting tomcat server....'
    sudo systemctl start tomcat
    exit
else
    echo 'Could not locate installation directory..exiting..'
    exit
fi
