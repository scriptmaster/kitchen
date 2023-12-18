all: build install

build:
	time v .

release:
	time v -prod .
	@ls -lah kitchen
	@echo "	"

install:
	cp -f kitchen /usr/local/bin/
	@ls -lah /usr/local/bin/kitchen
	@echo "	"
