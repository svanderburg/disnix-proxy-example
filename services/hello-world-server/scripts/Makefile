all:
	sed -e "s|@PREFIX@|$(PREFIX)|" \
	    -e "s|@port@|$(port)|" \
	wrapper.in > wrapper

clean:
	rm -f wrapper

install:
	install -d -m755 $(PREFIX)/bin
	install -m755 wrapper $(PREFIX)/bin
