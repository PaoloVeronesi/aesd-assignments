CC ?= gcc
CFLAGS ?= -Wall -Werror
CROSS_COMPILE ?=

TARGET = aesdsocket

all: $(TARGET)

default: $(TARGET)

$(TARGET): aesdsocket.c
	$(CROSS_COMPILE)$(CC) $(CFLAGS) -o $(TARGET) aesdsocket.c

clean:
	rm -f $(TARGET)