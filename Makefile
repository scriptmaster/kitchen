all: build install

build:
	time v .
	# time v -prod .

install:
	cp kitchen /usr/local/bin/
