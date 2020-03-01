#ifndef _DTP_H
#define _DTP_H

#include <getopt.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

typedef struct dtb_info {
  uint32_t total_size;
  uint32_t addr_start;
  uint32_t addr_stop;
} dtb;

#endif