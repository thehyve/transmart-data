ifndef TABLESPACES
$(error TABLESPACES variable is not set)
endif

DATABASE ?= transmart
#we could use PGOPTIONS here
PSQL_COMMAND = $(PGSQL_BIN)psql -v ON_ERROR_STOP=1 --single-transaction -X
PGDUMP_COMMAND = $(PGSQL_BIN)pg_dump
PGDUMPALL_COMMAND = $(PGSQL_BIN)pg_dumpall

.DELETE_ON_ERROR:
