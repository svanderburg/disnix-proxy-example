CC = gcc

all:
	$(CC) disnix-tcp-proxy.c -o disnix-tcp-proxy
	$(CC) disnix-tcp-proxy-client.c -o disnix-tcp-proxy-client

install: all
	install -d -m755 $(PREFIX)/bin
	install -m755 disnix-tcp-proxy $(PREFIX)/bin
	install -m755 disnix-tcp-proxy-client $(PREFIX)/bin

clean:
	rm -f *.o
	rm -f disnix-tcp-proxy disnix-tcp-proxy-client
