include ../../../makefile.inc

DICTIONARIES_LOCATION := http://files.thehyve.net/dictionaries/

ifndef THIS_SCHEMA
$(error THIS_SCHEMA variable is not set)
endif

OUTDIR := ../../common/$(THIS_SCHEMA)

dump_%: $(OUTDIR)
	$(PSQL_COMMAND) -c "COPY $(THIS_SCHEMA).$* TO STDOUT \
			CSV DELIMITER E'\t' FORCE QUOTE *" > $(OUTDIR)/$*.tsv

load_%: ../../common/$(THIS_SCHEMA)/%.tsv
	@if [ `$(PSQL_COMMAND) -c "SELECT EXISTS (SELECT * FROM $(THIS_SCHEMA).$* LIMIT 1)" -tA` = 't' ]; then \
		echo 'WARNING: The table $(THIS_SCHEMA).$* already has data; skipped' >&2; \
	else \
		$(PSQL_COMMAND) -c "COPY $(THIS_SCHEMA).$* FROM STDIN \
			CSV DELIMITER E'\t'" < $(OUTDIR)/$*.tsv; \
	fi

ifeq ($(THIS_SCHEMA), deapp)
#special case
../../common/deapp/de_rc_snp_info.tsv:
	curl -f $(DICTIONARIES_LOCATION)$(notdir $@).17_21.xz | xz -d --stdout > $@

load: load_de_rc_snp_info
endif

ifeq ($(THIS_SCHEMA), searchapp)
#special case
load_plugin_module: load_plugin update_plugin_module
load: load_plugin_module

update_plugin_module:
	$(MAKE) -C ../../common/searchapp/plugin_modules_params ../plugin_module.tsv

.PHONY: update_plugin_module
endif

.DELETE_ON_ERROR:

# vim: set filetype=make:
