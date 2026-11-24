AS = as
LD = ld

TARGET = overclocked
SRC = main.s
OBJ = main.o

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJ)
	$(LD) -o $(TARGET) $(OBJ)

$(OBJ): $(SRC)
	$(AS) -o $(OBJ) $(SRC)

clean:
	rm -f $(OBJ) $(TARGET)
