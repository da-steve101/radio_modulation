C_FLAGS=-Wall -I$(MODEL_DIR) -g
C_SRCS=tw_vgg10.c $(MODEL_DIR)/*.c
H_SRCS=$(MODEL_DIR)/*.h

tw_vgg10: $(C_SRCS) $(H_SRCS) Makefile
	$(CC) $(C_FLAGS) -o tw_vgg10 $(C_SRCS)
