#include "any.h"
#include "int.h"

#define DECODE_STATE_OP          0
#define DECODE_STATE_CONST       1
#define DECODE_STATE_IMM         2
#define DECODE_STATE_LIB         3
#define DECODE_STATE_LIB_MULTI   4
#define DECODE_STATE_CONST_RANGE 5

#define OP_SIZE_BITS   4
#define OP_CONST       0x0
#define OP_IMM8        0x1
#define OP_IMM16       0x2
#define OP_RET         0x3
#define OP_CONST_RANGE 0x4
#define OP_LIB         0xE
#define OP_LIB_MULTI   0xF

#define CONST_BITS 8

#define CONST_RANGE_BITS 4
#define CONST_RANGE_MASK 0xF

#define LIB_MULTI_COUNT_BITS 4

#define LIB_SIZE_BITS       8
#define LIB_OWNER_SAY       0x00
#define LIB_GET_USED_MEMORY 0x01
#define LIB_GET_FREE_MEMORY 0x02
#define LIB_STRING_EMPTY    0x03
#define LIB_STRING_CAT      0x04
#define LIB_THREAD_HALT     0x05
#define LIB_THREAD_YIELD    0x06
#define LIB_THREAD_FORK     0x07
#define LIB_ENTER           0x08
#define LIB_CALL            0x09
#define LIB_LIST            0x0A
#define LIB_STRING_PARSE    0x0B

#define INS_CONST_SIZE_BITS          12 // = OP_SIZE_BITS + CONST_BITS
#define INS_IMM8_SIZE_BITS           12 // = OP_SIZE_BITS + 8
#define INS_IMM16_SIZE_BITS          20 // = OP_SIZE_BITS + 16
#define INS_LIB_SIZE_BITS            12 // = OP_SIZE_BITS + LIB_SIZE_BITS
#define INS_LIB_MULTI_HEAD_SIZE_BITS  8 // = OP_SIZE_BITS + LIB_MULTI_COUNT_BITS

#define CS_TAG_NORMAL 0x00000000
#define CS_TAG_LIST   0x10000000

int decode_state;
int decode_op;
int decode_lib_mult_rep;

#define decode_update(fetch_result) \
    debug(fetch_addr - fetch_req, ": ", fetch_result, "(", fetch_req, ") in state ", decode_state);
    if(!decode_state) { \
        decode_op(fetch_result); \
    } else { \
        if(decode_state == DECODE_STATE_CONST) { \
            decode_const(fetch_result); \
        } else if(decode_state == DECODE_STATE_IMM) { \
            decode_imm(fetch_result); \
        } else if(decode_state == DECODE_STATE_LIB) { \
            decode_lib(fetch_result); \
        } else if(decode_state == DECODE_STATE_LIB_MULTI) { \
            decode_lib_multi(fetch_result); \
        } else if(decode_state == DECODE_STATE_CONST_RANGE) { \
            decode_const_range(fetch_result); \
        } \
        \
        if(decode_state != DECODE_STATE_LIB || !--decode_lib_mult_rep) { \
            decode_state = DECODE_STATE_OP; \
            fetch_request(OP_SIZE_BITS); \
        } \
    }

#define decode_op(op) \
    if(!(decode_op = op)) { \
        decode_op_const(); \
    } else if(decode_op <= OP_IMM16) { \
        decode_op_imm(); \
    } else if(decode_op == OP_RET) { \
        decode_op_ret(); \
    } else if(decode_op == OP_CONST_RANGE) { \
        decode_op_const_range(); \
    } else if(decode_op == OP_LIB) { \
        decode_op_lib(); \
    } else if(decode_op == OP_LIB_MULTI) { \
        decode_op_lib_multi(); \
    }

#define decode_op_const() \
    decode_state = DECODE_STATE_CONST; \
    fetch_req = CONST_BITS

#define decode_op_imm() \
    decode_state = DECODE_STATE_IMM; \
    fetch_req = decode_op << 3

#define decode_op_ret() \
    int r = cs_peek(); \
    if(r) { \
        if((r & 0xF0000000) == CS_TAG_LIST) { \
            ds_push(llGetListLength(ds) - ((r >> 12) & 0xFFF) + 1); \
        } \
        fetch_jump(r & 0xFFF); \
        cs_drop(); \
    } else { \
        jump thread_start; \
    }

#define decode_op_const_range() \
    decode_state = DECODE_STATE_CONST_RANGE; \
    fetch_request(CONST_BITS + CONST_RANGE_BITS)

#define decode_op_lib() \
    decode_state = DECODE_STATE_LIB; \
    decode_lib_mult_rep = 1; \
    fetch_request(LIB_SIZE_BITS)

#define decode_op_lib_multi() \
    decode_state = DECODE_STATE_LIB_MULTI; \
    fetch_request(LIB_MULTI_COUNT_BITS)

#define decode_const(idx) \
    ds_push_list(read(Any, thread_const_base(), idx), 1)

#define decode_imm(value) \
    ds_push(value)

#define decode_lib(fn) \
    if(!fn) { \
        decode_lib_owner_say(); \
    } else if(fn == LIB_GET_USED_MEMORY) { \
        decode_lib_get_used_memory(); \
    } else if(fn == LIB_GET_FREE_MEMORY) { \
        decode_lib_get_free_memory(); \
    } else if(fn == LIB_STRING_EMPTY) { \
        decode_lib_string_empty(); \
    } else if(fn == LIB_STRING_CAT) { \
        decode_lib_string_cat(); \
    } else if(fn == LIB_THREAD_HALT) { \
        decode_lib_thread_halt(); \
    } else if(fn == LIB_THREAD_YIELD) { \
        decode_lib_thread_yield(); \
    } else if(fn == LIB_THREAD_FORK) { \
        decode_lib_thread_fork(); \
    } else if(fn == LIB_ENTER) { \
        decode_lib_enter(); \
    } else if(fn == LIB_CALL) { \
        decode_lib_call(); \
    } else if(fn == LIB_LIST) { \
        decode_lib_list(); \
    } else if(fn == LIB_STRING_PARSE) { \
        decode_lib_string_parse(); \
    }

#define decode_lib_owner_say() \
    ds_arg_count(1); \
    llOwnerSay("VM: " + ds_arg0(String))

#define decode_lib_get_used_memory() \
    ds_push_noarg(llGetUsedMemory())

#define decode_lib_get_free_memory() \
    ds_push_noarg(llGetFreeMemory())

#define decode_lib_string_empty() \
    ds_push_noarg("")

#define decode_lib_string_cat() \
    ds_arg_count(2); \
    ds_push(ds_arg(String, 1) + ds_arg0(String))

#define decode_lib_thread_halt() \
    thread_halt()

#define decode_lib_thread_yield() \
    thread_yield()

#define decode_lib_thread_fork() \
    ds_arg_count(1); \
    thread_fork(ds_arg0(Int))

#define decode_lib_enter() \
    ds_arg_count(1); \
    fetch_jump(ds_arg0(Int))

#define decode_lib_call() \
    ds_arg_count(1); \
    cs_push(fetch_addr); \
    fetch_jump(ds_arg0(Int))

#define decode_lib_list() \
    ds_arg_count(1); \
    cs_push(fetch_addr | CS_TAG_LIST | (llGetListLength(ds) << 12)); \
    fetch_jump(ds_arg0(Int))

#define decode_lib_string_parse() \
    int keeps_len = ds_arg(Int, 1); \
    int drops_len = ds_arg(Int, keeps_len + 2); \
    int last_arg = keeps_len + drops_len + 2; \
    \
    list keeps = llList2List(ds, 2, keeps_len + 1); \
    if(!keeps_len) keeps = []; \
    list drops = llList2List(ds, keeps_len + 3, last_arg); \
    if(!drops_len) drops = []; \
    \
    list parse = llParseString2List(ds_arg0(String), drops, keeps); \
    int parse_len = llGetListLength(parse); \
    \
    ds_push_list([parse_len] + parse, parse_len + 1)

#define decode_lib_multi(count) \
    decode_lib_mult_rep = fetch_result + 3; \
    decode_state = DECODE_STATE_LIB; \
    fetch_request(LIB_SIZE_BITS)

#define decode_const_range(data) \
    int size = ((data) & CONST_RANGE_MASK) + 1; \
    ds_push_list(read_list(thread_const_base(), (data) >> CONST_RANGE_BITS, ((data) >> CONST_RANGE_BITS) + size), size + 1)
