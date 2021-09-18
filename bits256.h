#include "int.h"

#define get(var, idx) \
    var##idx

#define create_var_16(name) \
    int name##0; int name##1; int name##2; int name##3; \
    int name##4; int name##5; int name##6; int name##7; \
    int name##8; int name##9; int name##10; int name##11; \
    int name##12; int name##13; int name##14; int name##15

#define create_var_16_copy(dest, src) \
    int dest##0  = src##0;  int dest##1  = src##1;  int dest##2  = src##2;  int dest##3  = src##3; \
    int dest##4  = src##4;  int dest##5  = src##5;  int dest##6  = src##6;  int dest##7  = src##7; \
    int dest##8  = src##8;  int dest##9  = src##9;  int dest##10 = src##10; int dest##11 = src##11; \
    int dest##12 = src##12; int dest##13 = src##13; int dest##14 = src##14; int dest##15 = src##15

#define create_var_16_set(dest, v0) \
    int dest##0  = v0; int dest##1  = 0; int dest##2  = 0; int dest##3  = 0; \
    int dest##4  =  0; int dest##5  = 0; int dest##6  = 0; int dest##7  = 0; \
    int dest##8  =  0; int dest##9  = 0; int dest##10 = 0; int dest##11 = 0; \
    int dest##12 =  0; int dest##13 = 0; int dest##14 = 0; int dest##15 = 0

#define var16_to_list(name) \
    [name##0, name##1, name##2, name##3, name##4, name##5, name##6, name##7, \
     name##8, name##9, name##10, name##11, name##12, name##13, name##14, name##15]

#define set16(dest, v0) \
    dest##0  = v0; dest##1  = 0; dest##2  = 0; dest##3  = 0; \
    dest##4  =  0; dest##5  = 0; dest##6  = 0; dest##7  = 0; \
    dest##8  =  0; dest##9  = 0; dest##10 = 0; dest##11 = 0; \
    dest##12 =  0; dest##13 = 0; dest##14 = 0; dest##15 = 0

#define set16_2(dest, v0, v1) \
    dest##0  = v0; dest##1  = v1; dest##2  = 0; dest##3  = 0; \
    dest##4  =  0; dest##5  =  0; dest##6  = 0; dest##7  = 0; \
    dest##8  =  0; dest##9  =  0; dest##10 = 0; dest##11 = 0; \
    dest##12 =  0; dest##13 =  0; dest##14 = 0; dest##15 = 0

#define copy16(dest, src) \
    dest##0  = src##0;  dest##1  = src##1;  dest##2  = src##2;  dest##3  = src##3; \
    dest##4  = src##4;  dest##5  = src##5;  dest##6  = src##6;  dest##7  = src##7; \
    dest##8  = src##8;  dest##9  = src##9;  dest##10 = src##10; dest##11 = src##11; \
    dest##12 = src##12; dest##13 = src##13; dest##14 = src##14; dest##15 = src##15
