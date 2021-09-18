#include "int.h"

// Fetch module internal state
int fetch_buf;
int fetch_rem;
int fetch_req;
int fetch_result;
int fetch_addr;

#define fetch_update() \
    if(fetch_req > fetch_rem) { \
        fetch_buf = (fetch_buf & ~(0xFFFFFFFF << fetch_rem)) | ((read0(Int, (fetch_addr + fetch_rem) >> 5) >> ((fetch_addr + fetch_rem) & 0x1F)) << fetch_rem); \
        fetch_rem = 32; \
    } \
    \
    fetch_result = fetch_buf & ~(0xFFFFFFFF << fetch_req); \
    fetch_buf = fetch_buf >> fetch_req; \
    fetch_rem -= fetch_req; \
    fetch_addr += fetch_req

#define fetch_jump(dest) \
    fetch_addr = dest; \
    fetch_invalidate()

#define fetch_invalidate() \
    fetch_rem = 0

#define fetch_request(bits) \
    fetch_req = bits
