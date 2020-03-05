#include "dtp.h"

static void die(char *message) {
  fprintf(stderr, "%s", message);
  exit(EXIT_FAILURE);
}

static void usage(char *argv0) {
  printf("Example: \n\t%s -i kernel_dtb\n", argv0);
  exit(EXIT_FAILURE);
}

static void check_arg(int argc, char *argv[], char *dtb_file) {
  char optstring[] = "i:";
  int c, index = 0;
  int input_exist = 0;
  struct option options[] = {
      {"input", 1, NULL, 'i'},
      {0, 0, 0, 0},
  };
  while ((c = getopt_long(argc, argv, optstring, options, &index)) != -1) {
    switch (c) {
      case 'i':
        strcpy(dtb_file, optarg);
        input_exist = 1;
        break;
      default:
        usage(argv[0]);
        break;
    }
  }
  if (input_exist != 1) {
    usage(argv[0]);
  }
}

static void *memcpy_(void *dest, void *src, size_t size) {
  uint8_t *d = (uint8_t *)dest;
  uint8_t *s = (uint8_t *)src;
  int i = 0;
  while (size-- > 0) {
    d[size] = s[i];
    i++;
  }
  return dest;
}

int main(int argc, char *argv[]) {
  char *file_ = malloc(sizeof(char) * 100);
  char *filename = malloc(sizeof(char) * 100);
  check_arg(argc, argv, file_);

  struct stat filebuff;
  stat(file_, &filebuff);
  long filesize = filebuff.st_size;

  uint8_t buff[4];  // read 4 hex 1 time
  uint8_t head[4] = {0xD0, 0x0D, 0xFE, 0xED};
  uint8_t buff_c;
  FILE *fp = fopen(file_, "rb");
  if (fp == NULL) {
    fclose(fp);
    die("open dtb file failed\n");
  }

  dtb info;
  int new_dtb_count = 0;
  long cur_pos = 0;
  int ret;

  while (1) {
    for (int i = 0; i != 4; i++) {
      buff[i] = fgetc(fp);  // compare with head
    }
    ret = memcmp(&buff, &head, sizeof(buff));
    if (ret != 0) {
      break;
    }

    for (int i = 0; i != 4; i++) {
      buff[i] = fgetc(fp);
    }
    memcpy_(&info.total_size, &buff, 4);  // dtb file big endian, wtf
    info.addr_start = cur_pos;
    info.addr_stop = info.addr_start + info.total_size;

    fseek(fp, info.addr_start, SEEK_SET);
    sprintf(filename, "%s-%d", file_, new_dtb_count);
    printf("dtb block: %d, block size:%d -> %s\n", new_dtb_count,
           info.total_size, filename);
    FILE *new_dtb = fopen(filename, "wb");
    for (uint32_t i = 0; i < info.total_size; i++) {
      buff_c = fgetc(fp);
      fputc(buff_c, new_dtb);
    }
    fclose(new_dtb);

    // fseek(fp, info.addr_stop + 4, SEEK_SET);  // move fp to next dtb block size

    cur_pos = ftell(fp);
    if (cur_pos == filesize) {
      break;
    }
    new_dtb_count++;
  }

  fclose(fp);
  return 0;
}