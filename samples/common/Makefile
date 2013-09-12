DATA_LOCATION := http://files.thehyve.net/sample_data/


%/clinical: %/%_clinical.tar.xz
	tar -C $* -xJf $(subst %,$*,$<)

%/annotation: %/%_annotation.tar.xz
	tar -C $* -xJf $(subst %,$*,$<)

%/expression: %/%_expression.tar.xz
	tar -C $* -xJf $(subst %,$*,$<)

%/analysis: %/%_analysis.tar.xz
	tar -C $* -xJf $(subst %,$*,$<)

%/acgh: %/%_acgh.tar.xz
	tar -C $* -xJf $(subst %,$*,$<)

%/study_metadata: %/%_study_metadata.tar.xz
	tar -C $* -xJf $(subst %,$*,$<)

## {{{ SNP annotation
%/snp_annotation: %/%_snp_annotation.tar.xz
	tar -C $* -xJf $(subst %,$*,$<)
	touch $@

%/snp_annotation/conf/log4j.properties: %/snp_annotation
	mkdir -p $(dir $@)
	cp transmart-loader/conf/log4j.properties $@

%/snp_annotation/conf/Annotation.properties: %/snp_annotation.params %/snp_annotation transmart-loader/conf/Annotation.properties.php
	mkdir -p $(dir $@)
	php transmart-loader/conf/Annotation.properties.php $*/snp_annotation.params > $@

#Common.properties is db specific and must be create by ../postgres' Makefile
SNP_ANNOTATION_CONF_FILES = log4j.properties Common.properties Annotation.properties
load_snp_annotation_%: %/snp_annotation $(foreach f,$(SNP_ANNOTATION_CONF_FILES),%/snp_annotation/conf/$f)
	@mkdir -p $*/snp_annotation/out
	cd $*/snp_annotation && ../../transmart-loader/loader.sh annotation

## }}}

PATTERNS_TARBALL = %/%_clinical.tar.xz \
				   %/%_annotation.tar.xz \
				   %/%_expression.tar.xz \
				   %/%_analysis.tar.xz \
				   %/%_acgh.tar.xz \
				   %/%_study_metadata.tar.xz \
				   %/%_snp_annotation.tar.xz

$(PATTERNS_TARBALL):
	curl -f $(DATA_LOCATION)$(notdir $(subst %,$*,$@)) > $(subst %,$*,$@)


.DELETE_ON_ERROR:
