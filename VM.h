#include "debug.h"

#include "VM-cs.h"
#include "VM-decode.h"
#include "VM-ds.h"
#include "VM-fetch.h"
#include "VM-code.h"
#include "VM-thread.h"

vm_run() {
@thread_start;
    thread_switch();

@fetch_start;
    fetch_update();
    debug(fetch_addr - fetch_req, ": ", fetch_result, "(", fetch_req, ") in state ", decode_state);
    decode_update(fetch_result);
    ds_update();

    debug("DS", llList2CSV(ds));

    jump fetch_start;
}
