#include "int.h"

#define make48(var) \
    int var##l; \
    int var##h

#define start48(var, a, b) \
    var##h = getTop(var##h) + getTop(var##l = getBottom(var##h) + a##_b * b##_b) + a##_t * b##_b + b##_t * a##_b + ((a##_t * b##_t) << sixteen); \
    var##l = getBottom(var##l)

#define mac48(var, a, b) \
    var##h += getTop(var##l += a##_b * b##_b) + a##_t * b##_b + b##_t * a##_b + ((a##_t * b##_t) << sixteen); \
    var##l = getBottom(var##l)
