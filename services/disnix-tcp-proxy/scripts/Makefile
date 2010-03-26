all:
	sed -e "s|@PREFIX@|$(PREFIX)|g" \
	    -e "s|@srcPort@|$(srcPort)|g" \
	    -e "s|@destHostname@|$(destHostname)|g" \
	    -e "s|@destPort@|$(destPort)|g" \
	wrapper.in > wrapper

clean:
	rm -f wrapper

install:
	install -d -m755 $(PREFIX)/bin
	install -m755 wrapper $(PREFIX)/bin
