#include "int.h"
#include "stack.h"

// Data stack
list ds;
int ds_added;
int ds_removed;

#define ds_push(x) \
    ds_push_list([x], 1)

#define ds_push2(x, y) \
    ds_push_list(([x, y]), 2)

#define ds_push_list(lst, size) \
    ds_push_list_noarg(lst, size); \
    ds_added = size

#define ds_push_noarg(x) \
    ds_push_list_noarg([x], 1)

#define ds_push_list_noarg(lst, size) \
    stack_push_list(ds, lst)

#define ds_arg_count(n) \
    ds_removed = n

#define ds_arg0(type) \
    stack_peek(type, ds)

#define ds_arg(type, idx) \
    stack_peekn(type, ds, idx)

#define ds_update() \
    if(ds_removed) { \
        ds = llDeleteSubList(ds, ds_added, ds_added + ds_removed - 1); \
        ds_removed = 0; \
    } \
    ds_added = 0
