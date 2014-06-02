R_MIRROR = http://cran-mirror.cs.uu.nl
R_REPO = http://cran-mirror.cs.uu.nl/bin/linux/ubuntu

MICHAEL_RUTTER_KEY=E084DAB9

install_R:
	. /etc/lsb-release; \
	test $$DISTRIB_RELEASE != '12.04' || \
	grep $(R_REPO) /etc/apt/sources.list || \
	( gpg --recv-keys --keyserver keyserver.ubuntu.com $(MICHAEL_RUTTER_KEY) && \
	  ( gpg -a --export $(MICHAEL_RUTTER_KEY) | apt-key add -) && \
	  echo 'deb $(R_REPO) precise/' >> /etc/apt/sources.list && \
	  apt-get update \
	)
	apt-get install r-base libcairo-dev

cran_packages: cran_pkg.R 
	CRAN_MIRROR=$(R_MIRROR) R -f $<

other_packages: other_pkg.R cran_packages 
	R -f $<

install_packages: cran_packages other_packages

start_Rserve start_Rserve.dbg:
	R CMD $(patsubst start_%,%,$@)

install: install_R install_packages

# must be run as root
install_rserve_init:
	TRANSMART_USER=$(TRANSMART_USER) php -d variables_order=E -d open_basedir=/ \
		rserve.php > /etc/init.d/rserve
	chmod +x /etc/init.d/rserve
	sudo update-rc.d rserve defaults


install_rserve_unit:
	TRANSMART_USER=$(TRANSMART_USER) php -d variables_order=E -d open_basedir=/ \
		rserve.service.php > /etc/systemd/system/rserve.service
	systemctl daemon-reload

clean:
	rm -rf build $(R_SOURCE) root

.PHONY: install_packages cran_packages other_packages clean \
		start_Rserve start_Rserve.dbg install_init

.DELETE_ON_ERROR:
