#include "int.h"

#define getBottom(x) \
    ((x) & mask16)

#define getTop(x) \
    getBottom((x) >> sixteen)

#define create_top_bottom(var) \
    int var##_b = getBottom(var); \
    int var##_t = getTop(var)

#define setTopBottom(dest, src) \
    dest##_b = getBottom(src); \
    dest##_t = getTop(src)
