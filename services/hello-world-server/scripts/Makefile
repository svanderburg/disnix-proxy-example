all:
	sed -e "s|@PREFIX@|$(PREFIX)|" \
	    -e "s|@port@|$(port)|" \
	process.in > process

clean:
	rm -f process

install:
	install -d -m755 $(PREFIX)/bin
	install -m755 process $(PREFIX)/bin
