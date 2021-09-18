#define DEBUG

#include "VM.h"

#define COMPILE_FLUSH 0
#define COMPILE_FN    1
#define COMPILE_CONST 2
#define COMPILE_RET   3
#define COMPILE_IMM8  4
#define COMPILE_IMM16 5
#define COMPILE_CALL  6

list compile_fns = [
    "owner-say", "used-memory", "free-memory", "string-empty", "string-concat", "halt", "yield", "fork", "enter", "call", "list", "string-parse"
];

list compile_env;

int comp_write_buf;
int comp_write_buf_used;
int comp_write_addr;

compile_write(int value, int size) {
    debug("Write", comp_write_addr, " = ", value, "(", size, ")");
    if(comp_write_buf_used + size >= 32) {
        list_replace1(vm_mem, comp_write_buf += value << comp_write_buf_used, comp_write_addr >> 5);
        int t = 32 - comp_write_buf_used;
        comp_write_buf = (value >> t) & ~(0xFFFFFFFF << (comp_write_buf_used = (size - t)));
    } else {
        comp_write_buf += value << comp_write_buf_used;
        comp_write_buf_used += size;
    }
    
    comp_write_addr += size;
}

int comp_last_op;
list comp_buf;

compile_append(int op, int arg) {
    if(comp_last_op != op) {
        if(comp_last_op == COMPILE_FN) {
            int len = llGetListLength(comp_buf);
            if(len == 1) {
                compile_write(OP_LIB, OP_SIZE_BITS);
                compile_write(llList2Int(comp_buf, 0), LIB_SIZE_BITS);
            } else if(len > 1) {
                compile_write(OP_LIB_MULTI, OP_SIZE_BITS);
                compile_write(len - 2, LIB_MULTI_COUNT_BITS);
                int i;
                while(i < len) {
                    compile_write(llList2Int(comp_buf, i++), LIB_SIZE_BITS);
                }
            }
        } else if(comp_last_op == COMPILE_CONST) {
            int len = llGetListLength(comp_buf);
            if(len == 1) {
                compile_write(OP_CONST, OP_SIZE_BITS);
                compile_write(llList2Int(comp_buf, 0), CONST_BITS);
            } else if(len > 1) {
                compile_write(OP_CONST_RANGE, OP_SIZE_BITS);
                compile_write(len - 2, CONST_RANGE_BITS);
                compile_write(llList2Int(comp_buf, 0), CONST_BITS);
            }
        }
        
        comp_last_op = op;
        comp_buf = [];
    }
    
    if(op == COMPILE_FN || op == COMPILE_CONST) {
        comp_buf += [arg];
    } else if(op == COMPILE_RET) {
        compile_write(OP_RET, OP_SIZE_BITS);
    } else if(op == COMPILE_IMM8) {
        compile_write(OP_IMM8, OP_SIZE_BITS);
        compile_write(arg, 8);
    } else if(op == COMPILE_IMM16) {
        compile_write(OP_IMM16, OP_SIZE_BITS);
        compile_write(arg, 16);
    } else if(op == COMPILE_CALL) {
        int callsite = llList2Int(compile_env, arg + 1);
        compile_write(OP_IMM16, OP_SIZE_BITS);
        compile_write(callsite & 0xFFF, 16);
        compile_write(OP_LIB, OP_SIZE_BITS);
        compile_write(LIB_CALL, LIB_SIZE_BITS);
    }
}

compile_flush() {
    compile_append(COMPILE_FLUSH, 0);
    list_replace1(vm_mem, comp_write_buf, comp_write_addr >> 5);
}

compile(list words) {
    list todo = [llGetListLength(words) << 16, -1];
    list comp_consts;
    
    int prog_start = llGetListLength(vm_mem) << 5;
    comp_write_addr = prog_start;
    comp_write_buf = comp_write_buf_used = 0;
    
    while(todo) {
        int slice = llList2Int(todo, 0);
        int place = llList2Int(todo, 1);
        todo = llDeleteSubList(todo, 0, 1);
        
        // Update reference
        if(~place) {
            compile_flush();
            list_replace1(vm_mem, (comp_write_addr << (place & 0x1F)) | (llList2Int(vm_mem, place >> 5) & ~(0xFFFF << (place & 0x1F))), place >> 5);
        }
        
        // Compile code
        int ptr = slice & 0xFFFF;
        int end = ptr + (slice >> 16);
        
        while(ptr < end) {
            string word = llList2String(words, ptr++);
            if(word == "[") {
                // Find corresponding brace
                int start = ptr;
                int depth = 1;
                while(depth && ptr < end) {
                    if((word = llList2String(words, ptr++)) == "[") ++depth;
                    else if(word == "]") --depth;
                }
                
                debug("Compile", "Block from ", start, " to ", ptr - 2);
                
                // Append reference to be patched up later
                compile_append(COMPILE_IMM16, 0);
                todo += [start | ((ptr - 2) << 16), comp_write_addr - 16];
            } else if(word == "]") {
                debug("Compile", "Error: found unmatched ] at ", ptr);
            } else if(word == "def") {
                string name = llList2String(words, ptr++);
            } else {
                int idx = llListFindList(compile_fns, [word]);
                if(~idx) {
                    compile_append(COMPILE_FN, idx);
                } else if(~(idx = llListFindList(compile_env, [word]))) {
                    compile_append(COMPILE_CALL, idx);
                } else {
                    string f = llGetSubString(word, 0, 0);
                    if(f == "\"") {
                        // Read until we find a string ending with " but not \" which is the end of the string
                        int start = ptr - 1;
                        int check = TRUE;
                        while(check) {
                            if((ptr != start + 1 || word != "\"") && llGetSubString(word, -1, -1) == "\"" && llGetSubString(word, -2, -2) != "\\") {
                                check = FALSE;
                            } else {
                                word = llList2String(words, ptr++);
                            }
                        }
                        
                        // Generate string buffer and test for "", the special empty case
                        string buffer = llGetSubString(llDumpList2String(llList2List(words, start, ptr - 1), " "), 1, -2);
                        if(buffer != "\"\""){
                            compile_append(COMPILE_CONST, llGetListLength(comp_consts));
                            comp_consts += [buffer];
                        } else {
                            compile_append(COMPILE_FN, LIB_STRING_EMPTY);
                        }
                    } else if((int)f || f == "0" || f == "-" || f == ".") {
                        // Float or Int
                        if(!~llSubStringIndex(word, ".") && (int)word >= 0) {
                            // Nat
                            if((int)word <= 0xFF) {
                                compile_append(COMPILE_IMM8, (int)word);
                            } else if((int)word <= 0xFFFF) {
                                compile_append(COMPILE_IMM16, (int)word);
                            } else {
                                compile_append(COMPILE_CONST, llGetListLength(comp_consts));
                                comp_consts += [word];
                            }
                        } else {
                            compile_append(COMPILE_CONST, llGetListLength(comp_consts));
                            comp_consts += [word];
                        }
                    } else {
                        compile_append(COMPILE_CONST, llGetListLength(comp_consts));
                        comp_consts += [word];
                    }
                }
            }
        }
        
        compile_append(COMPILE_RET, 0);
    }
    
    compile_flush();
    
    create_thread_entry(prog_start, llGetListLength(vm_mem) - prog_start, llGetListLength(comp_consts), "");
    vm_mem += comp_consts;
}

default {
    state_entry() {
        llListen(0, "", llGetOwner(), "");
    }
    listen(int c, string n, key id, string m) {
        if(llGetSubString(m, 0, 0) == "#") {
            list words = llParseString2List(llDeleteSubString(m, 0, 0), [" "], ["[", "]"]);
            compile(words);
            debug("Mem", llList2CSV(vm_mem));
            
            vm_run();
            
            debug("Result", llList2CSV(ds));
        }
    }
}
