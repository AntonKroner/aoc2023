#include "days.h"

void one(const size_t part);
void two(const size_t part);
void three(const size_t part);
void day04(const size_t part);
void day05(const size_t part);


extern "C" void selectDay(const size_t day, const size_t part) {
	if (day == 1) { return one(part); }
	if (day == 2) { return two(part); }
	if (day == 3) { return three(part); }
	if (day == 4) { return day04(part); }
	if (day == 5) { return day05(part); }
}
