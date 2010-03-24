PREFIX = /usr/local

SUBDIRS=src \
	scripts

all:
	for subdir in $(SUBDIRS); do \
	    (cd $$subdir; $(MAKE) $@) || exit 1; \
	done

clean:
	for subdir in $(SUBDIRS); do \
	    (cd $$subdir; $(MAKE) $@) || exit 1; \
	done

install:
	for subdir in $(SUBDIRS); do \
	    (cd $$subdir; $(MAKE) $@) || exit 1; \
	done
