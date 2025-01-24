#!/bin/bash

old=`ls /usr/share/tomcat/webapps/ROOT/WEB-INF/lib | grep  "mail-1.5.0-b01.jar"`
new=`ls /usr/share/tomcat/webapps/ROOT/WEB-INF/lib | grep  "jakarta.mail-1.6.3.jar"`
#

  if [[ ! -f "$new"  &&  -f "$old" ]]
  then
      echo "moving the mail-1.5.0-b01.jar and placing jakarta.mail-1.6.3.jar "
      sudo mv /usr/share/tomcat/webapps/ROOT/WEB-INF/lib/mail-1.5.0-b01.jar /home/ec2-user/mail-1.5.0-b01.jar
      sudo curl -Lo /usr/share/tomcat/webapps/ROOT/WEB-INF/lib/jakarta.mail-1.6.3.jar https://repo1.maven.org/maven2/com/sun/mail/jakarta.mail/1.6.3/jakarta.mail-1.6.3.jar
      sudo chown tomcat:tomcat /usr/share/tomcat/webapps/ROOT/WEB-INF/lib/jakarta.mail-1.6.3.jar
      sudo systemctl restart tomcat

  elif [[ ! -f "$new"  &&  ! -f "$old" ]]
  then
      echo "downloading the jakarta.mail-1.6.3.jar"
      sudo curl -Lo /usr/share/tomcat/webapps/ROOT/WEB-INF/lib/jakarta.mail-1.6.3.jar https://repo1.maven.org/maven2/com/sun/mail/jakarta.mail/1.6.3/jakarta.mail-1.6.3.jar
      sudo chown tomcat:tomcat /usr/share/tomcat/webapps/ROOT/WEB-INF/lib/jakarta.mail-1.6.3.jar
      sudo systemctl restart tomcat

  elif [[  -f "$new"  &&  ! -f "$old" ]]
  then
      echo "looking good and restarting the tomcat"
      sudo systemctl restart tomcat

  else
       echo "this is above 6.1.2.2"
       exit 0
  fi
