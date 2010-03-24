PREFIX = /usr/local

all:
	sed -e "s|@helloWorldHostname@|$(helloWorldHostname)|" \
	    -e "s|@helloWorldPort@|$(helloWorldPort)|" \
	    -e "s|@inetutils@|$(inetutils)|" \
	hello-world-client.in > hello-world-client

install:
	install -d -m755 $(PREFIX)/bin
	install -m755 hello-world-client $(PREFIX)/bin

clean:
	rm -f hello-world-client
