CC = gcc

ifeq ($(SYSTEMD_SOCKET_ACTIVATION),1)
    EXTRA_BUILDFLAGS=-DSYSTEMD_SOCKET_ACTIVATION=1 -DSELF_TERMINATION=1 $(shell pkg-config --cflags --libs libsystemd)
endif

all:
	$(CC) $(EXTRA_BUILDFLAGS) hello-world-server.c -o hello-world-server

install: all
	install -d -m755 $(PREFIX)/bin
	install -m755 hello-world-server $(PREFIX)/bin

clean:
	rm -f *.o
	rm -f hello-world-server
