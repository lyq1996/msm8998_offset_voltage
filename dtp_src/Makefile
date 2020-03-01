CC = gcc
CFLAGS += -std=c11 -Wall # --static 
SRCS = dtp.c
OBJS = $(SRCS:.c=.o)
MAIN = dtp
DESTDIR = ../prebuilt/

.PHONY: all clean

all: $(MAIN)

clean:
	$(RM) *.o $(DESTDIR)$(MAIN)

$(MAIN): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -s -o $(DESTDIR)$(MAIN)

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@