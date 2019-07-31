C_FLAGS=-Wall -I$(MODEL_DIR) -O2
L_FLAGS=-lm
C_SRCS=$(shell find $(MODEL_DIR) -name '*.c')
H_SRCS=$(shell find $(MODEL_DIR) -name '*.h')
BUILDDIR=build
OBJECTS := $(addprefix $(BUILDDIR)/,$(notdir $(C_SRCS:%.c=%.o)))

all: tw_vgg10

$(BUILDDIR):
	mkdir -p $@

$(BUILDDIR)/%.o: $(MODEL_DIR)/%.c
	$(CC) -c -o $@ $< $(CFLAGS)

tw_vgg10: $(BUILDDIR) $(OBJECTS) tw_vgg10.c
	$(CC) $(C_FLAGS) -o tw_vgg10 tw_vgg10.c $(OBJECTS) $(L_FLAGS)

.PHONY: clean

clean:
	rm -rf tw_vgg10 *.o $(BUILDDIR)

