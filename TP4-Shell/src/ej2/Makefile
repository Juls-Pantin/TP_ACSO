CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -g

TARGET = shell
SRC = shell.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)
