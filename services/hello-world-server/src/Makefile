CC = gcc

all:
	$(CC) hello-world-server.c -o hello-world-server

install: all
	install -d -m755 $(PREFIX)/bin
	install -m755 hello-world-server $(PREFIX)/bin

clean:
	rm -f *.o
	rm -f hello-world-server
