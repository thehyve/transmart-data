TOMCAT_PACKAGES=openjdk-7-jdk tomcat7
WAR_FILE=https://ci.ctmmtrait.nl//browse/TM-TM-500/artifact/shared/transmartApp-WAR/transmart.war

install_tomcat:
	apt-get install -y $(TOMCAT_PACKAGES)

add_tomcat_alias:
	grep /transmart/images/analysisFiles /etc/tomcat7/server.xml >/dev/null || \
	sed -i '/autoDeploy=/ a\ \t<Context path="/transmart/images/analysisFiles" docBase="/var/tmp/jobs/" />' /etc/tomcat7/server.xml

add_tomcat_heapsize:
	sed -i s/Xmx128m/Xmx1528m/ /etc/default/tomcat7

conf_tomcat: add_tomcat_alias add_tomcat_heapsize
	service tomcat7 restart

install_warfile: install_tomcat
	
tomcat: install_tomcat conf_tomcat


transmart.war:
	curl -L -f $(WAR_FILE) > $@
	cp $@ /var/lib/tomcat7/webapps



.PHONY:

.DELETE_ON_ERROR:

# vim: ai ts=4 sw=4 noet:
