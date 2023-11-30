#include <stdlib.h>
#include <stdio.h>
#include <getopt.h>
#include "template.h"

int main(int argc, char* argv[static argc]) {
	extern char* optarg;
	int index = 0;
	int option = 0;
	int flag = 0;
	const struct option options[] = {
	 { "input", required_argument, 0, 'i' },
	 { "flag", no_argument, &flag, 1},
	 {      0,                 0, 0,   0 }
	};
	while (option != EOF) {
		option = getopt_long(argc, argv, "", options, &index);
		switch (option) {
		case 0:
			break;
		case '?':
			printf("Error case.");
			break;
		case 'i':
			printf("input: %s\n", optarg);
		}
	}
	size_t length = 16;
	char str[] = { 82, 111, 118, 118, 121, 42, 97, 121,
								124, 118, 110, 56, 10, 10, 10, 10 };
	printf("%s\n", str);
	test(length, str);
	printf("%s\n", str);
	return EXIT_SUCCESS;
}
