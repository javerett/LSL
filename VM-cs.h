#include "int.h"
#include "stack.h"

// Call stack
list vm_cs;

#define cs_push(ip) \
    stack_push(vm_cs, ip)

#define cs_peek() \
    stack_peek(Int, vm_cs)

#define cs_pop() \
    stack_pop(Int, vm_cs)

#define cs_drop() \
    stack_drop(vm_cs)
