all:
	sed -e "s|@PREFIX@|$(PREFIX)|" \
	    -e "s|@srcPort@|$(srcPort)|" \
	    -e "s|@destHostname@|$(destHostname)|" \
	    -e "s|@destPort@|$(destPort)|" \
	wrapper.in > wrapper

clean:
	rm -f wrapper

install:
	install -d -m755 $(PREFIX)/bin
	install -m755 wrapper $(PREFIX)/bin
