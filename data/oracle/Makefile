include ../common/makefile.inc
include ../../lib/makefile.inc

BIOMART_PSW ?= biomart
DEAPP_PSW ?= deapp
SEARCHAPP_PSW ?= searchapp
$(ENV_DIR)/$(TRANSMART_LOADER)/conf/Common.properties:
	echo "driver_class=oracle.jdbc.driver.OracleDriver" > $@ \
	&& echo "url=jdbc:oracle:thin:@localhost:21521:TSMWONT1" >> $@ \
	&& echo "biomart_username=biomart" >> $@ \
	&& echo "biomart_password=TMuser0!" >> $@ \
	&& echo "deapp_username=deapp" >> $@ \
	&& echo "deapp_password=TMuser0!" >> $@ \
	&& echo "searchapp_username=searchapp" >> $@ \
	&& echo "searchapp_password=TMuser0!" >> $@

.PHONY: $(ENV_DIR)/$(TRANSMART_LOADER)/conf/Common.properties

start_pool: $(NETTY_JAR_PATH) $(JDBC_DRIVER_ORA_PATH)
	NLS_DATE_FORMAT='yyyy-mm-dd hh24:mi:ss' \
		NLS_TIMESTAMP_FORMAT='yyyy-mm-dd hh24:mi:ss.ff' \
		groovy -cp '$(CP_ORA):$(NETTY_JAR_PATH)' start_conn_pool.groovy \
		-f pool-lock

.PHONY: start_pool

# vim: set filetype=make:
