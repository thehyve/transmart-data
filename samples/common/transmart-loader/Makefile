TARBALL  := transmart-loader.tar.xz
LOCATION := http://files.thehyve.net/$(TARBALL)

$(TARBALL):
	curl -f $(LOCATION) > $@

loader.sh: extract_tarball

extract_tarball: $(TARBALL)
	rm -rf lib/
	tar xJf $<

clean:
	rm -rf lib/ $(TARBALL) *.jar loader.sh

.PHONY: extract_tarball clean

.DELETE_ON_ERROR:
