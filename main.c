#include <stdlib.h>
#include <stdio.h>
#include <getopt.h>
#include "days/days.h"

int main(int argc, char* argv[static argc]) {
  size_t day = 0;
  size_t part = 0;
  extern char* optarg;
  int index = 0;
  int option = 0;
  int flag = 0;
  const struct option options[] = {
    { "day", required_argument,     0, 'd'},
    {"part", required_argument,     0, 'p'},
    {"flag",       no_argument, &flag,   1},
    {     0,                 0,     0,   0}
  };
  while (option != EOF) {
    option = getopt_long(argc, argv, "", options, &index);
    switch (option) {
      case 0:
        break;
      case '?':
        printf("Error case.");
        break;
      case 'd':
        day = atoi(optarg);
        break;
      case 'p':
        part = atoi(optarg);
        break;
    }
  }
  if (day == 0 || part == 0) {
    perror("Usage: --day <day number> --part <1 | 2>");
    exit(EXIT_FAILURE);
  }
  else if (day < 0 || day > 25) {
    perror("Wacky day selected!!!");
    exit(EXIT_FAILURE);
  }
  else if (part < 1 || part > 2) {
    perror("Wacky part selected!!!");
    exit(EXIT_FAILURE);
  }
  selectDay(day, part);
  return EXIT_SUCCESS;
}
