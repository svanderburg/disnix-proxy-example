all:
	sed -e "s|@PREFIX@|$(PREFIX)|g" \
	    -e "s|@DYSNOMIA_MODULE@|$(DYSNOMIA_MODULE)|g" \
	    -e "s|@srcPort@|$(srcPort)|g" \
	wrapper.in > wrapper

clean:
	rm -f wrapper

install:
	install -d -m755 $(PREFIX)/bin
	install -m755 wrapper $(PREFIX)/bin
