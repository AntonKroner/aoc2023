#include "days.h"

void one(const size_t part);
void two(const size_t part);

extern "C" void selectDay(const size_t day, const size_t part) {
	if (day == 1) { return one(part); }
	if (day == 2) { return two(part); }
}
