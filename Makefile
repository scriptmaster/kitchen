all: build install help

build: pclear
	time v .

pclear:
	killall kitchen &2>/dev/null

release:
	time v -prod -cc gcc -cflags "-s -Os" .
	@ls -lah kitchen
	@echo "	"

install:
	cp -f kitchen /usr/local/bin/
	@ls -lah /usr/local/bin/kitchen
	@echo "	"

help: usage
usage:
	kitchen help
