CC=cc
CFLAGS = -target x86_64-apple-macos11 -Wall -Wextra -pedantic -O0 -g -Wno-unused-variable -Wno-unused-parameter
NASM=nasm
NASMFLAGS=-f macho64 -g

all: main tester

OBJS := ej1_c.o ej1_asm.o
tester: tester.c $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

main: main.c $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

ej1_c.o: ej1.c ej1.h
	$(CC) $(CFLAGS) -c $< -o $@

ej1_asm.o: ej1.asm ej1.h
		$(NASM) $(NASMFLAGS) $< -o $@

clean:
	rm -f *.o
	rm -f main tester
	rm -f salida.caso.*
