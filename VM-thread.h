#include "int.h"

// Instruction pointer, constant pointer, constant count, data stack(as string)
#define create_thread_header(ip, cp, cc) \
    ((ip) | ((cp) << 12) | ((cc) << 24))

#define create_thread_entry(ip, cp, cc, ds) \
    vm_active += [create_thread_header(ip, cp, cc), ds]

#define thread_switch() \
    if(vm_const_base = llList2Int(vm_active, 0)) { \
        fetch_request(OP_SIZE_BITS); \
        fetch_jump(vm_code_base = (vm_const_base & 0xFFF)); \
        \
        vm_const_count = (vm_const_base >> 24) & 0xFF; \
        vm_const_base = vm_code_base + ((vm_const_base >> 12) & 0xFFF); \
        \
        ds = llParseString2List(llList2String(vm_active, 1), [JSON_NULL], []); \
        \
        vm_active = llDeleteSubList(vm_active, 0, 1); \
    } else { \
        return; \
    }

#define thread_halt() \
    jump thread_start

#define thread_yield() \
    vm_active += [create_thread_header(fetch_addr, vm_const_base, vm_const_count), llDumpList2String(ds, JSON_NULL)]

#define thread_fork(dest) \
    vm_active += [create_thread_header(dest, vm_const_base, vm_const_count), llDumpList2String(ds, JSON_NULL)]

#define thread_const_base() \
    vm_const_base

list vm_active;
int vm_code_base;
int vm_const_base;
int vm_const_count;
