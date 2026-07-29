CFLAGS = $(shell pkg-config --cflags --libs ncursesw)
CC = gcc
FILES = src/*.c
BIN = cfm

all: clean build

install: build
	chmod 777 $(BIN)
	sudo mv $(BIN) /usr/local/bin/

build:
	$(CC) -o $(BIN) $(FILES) $(CFLAGS)

clean:
	rm -rf $(BIN) 2>/dev/null
