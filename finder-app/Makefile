# Variables
TARGET = writer
SRC = writer.c
OBJ = $(SRC:.c=.o)

# Cross-compilation support
# If CROSS_COMPILE is defined (e.g., CROSS_COMPILE=aarch64-none-linux-gnu-),
# CC becomes aarch64-none-linux-gnu-gcc. Otherwise, it defaults to native gcc.
CROSS_COMPILE ?=
CC ?= $(CROSS_COMPILE)gcc
CFLAGS = -Wall -Werror -g

# Default target
.PHONY: all
all: $(TARGET)

# Link the object files to create the executable
$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJ)

# Compile C source files into object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean target
.PHONY: clean
clean:
	rm -f $(TARGET) *.o *.txt
