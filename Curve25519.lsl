#include "bits16.h"
#include "bits48.h"
#include "bits256.h"

#define call(fn, site) \
    call_stack += [site]; \
    jump fn; \
    @dispatch_##site
    
#define call_addmodp_special(site) \
    call(call_addmodp, site)
    
#define call_addmodp(site, a, b) \
    copy16(result, a); \
    copy16(argument, b); \
    call(call_addmodp, site)
    
#define call_submodp_special(site) \
    call(call_submodp, site)
    
#define call_submodp(site, a, b) \
    copy16(result, a); \
    copy16(argument, b); \
    call(call_submodp, site)

#define call_sqrmodp_special(site) \
    call(call_sqrmodp, site)
    
#define call_mulmodp_special(site) \
    call(call_mulmodp, site)
    
#define call_mulmodp(site, a, b) \
    copy16(result, a); \
    copy16(argument, b); \
    call(call_mulmodp, site)
    
#define call_mul8h_special(site) \
    call(call_mul8h, site)
    
#define call_mulasmall_special(site) \
    call(call_mulasmall, site)    

#define call_mulasmall(site, val) \
    copy16(result, val); \
    call(call_mulasmall, site)
    
#define load_public_1() \
    copy16(result, public); \
    set16(argument, 1)

#define create_private_key(i) \
    i = 16; \
    while(i--) private_list += [(int)llFrand(65536.)];

// Public interface
create_var_16(public);
list private_list;

// Overflow
create_var_16(temp_result);
create_var_16(temp_argument);
create_var_16(dxs);
create_var_16(sxd);
create_var_16(rx);
create_var_16(rz);

curve25519(){
    // Common vars and constants
    int mask16 = 0xFFFF;
    int sixteen = 16;
    int v;
    int factor;
    
    // Internal registers
    create_var_16(result);
    create_var_16(argument);
    
    // Regs for mulmodp
    create_var_16(x);
    create_var_16(y);
    create_var_16(z);
    
    // Curve main regs
    create_var_16(m);
    create_var_16(n);
    create_var_16(o);
    
    create_var_16(ax);
    create_var_16(az);

    // Call stack
    list call_stack;
    
    // TODO: in the base case, m, n, o, ax, az are constant
    
    // bigint n = sqrmodp(submodp(public, [1]));
    load_public_1();
    call_submodp_special(2);
    call_sqrmodp_special(3);
    copy16(n, result);
    
    // bigint m = sqrmodp(addmodp(public, [1]));
    load_public_1();
    call_addmodp_special(0);
    call_sqrmodp_special(1);
    copy16(m, result);
    
    // bigint o = submodp(m, n);
    copy16(argument, n);
    call_submodp_special(7);
    copy16(o, result);
    
    // bigint ax = mulmodp(m, n);
    copy16(result, m);
    call_mulmodp_special(8);
    copy16(ax, result);
    
    // bigint az = mulmodp(addmodp(mulasmall(o), m), o);
    call_mulasmall(9, o);
    copy16(argument, m);
    call_addmodp_special(10);
    copy16(argument, o);
    call_mulmodp_special(11);
    copy16(az, result);
    
    // bigint qx = c;
    create_var_16_copy(qx, public);
    
    // bigint qz = [1];
    create_var_16_set(qz, 1);
    
    int mul_loop_count = 255;
    @mul_loop;
    if(!(mul_loop_count--)) jump mul_loop_exit;
        // bigint dxs = mulmodp(submodp(ax, az), addmodp(qx, qz));
        call_addmodp(13, qx, qz);
        copy16(m, result);
        call_submodp(12, ax, az);
        copy16(argument, m);
        call_mulmodp_special(14);
        copy16(dxs, result);
        
        // bigint sxd = mulmodp(addmodp(ax, az), submodp(qx, qz));
        call_submodp(16, qx, qz);
        copy16(m, result);
        call_addmodp(15, ax, az);
        copy16(argument, m);
        call_mulmodp_special(17);
        copy16(sxd, result);
        
        // bigint rx = sqrmodp(addmodp(dxs, sxd));
        copy16(argument, dxs);
        call_addmodp_special(18);
        call_sqrmodp_special(19);
        copy16(rx, result);
        
        // bigint rz = mulmodp(sqrmodp(submodp(dxs, sxd)), public);
        call_submodp(20, dxs, sxd);
        call_sqrmodp_special(21);
        copy16(argument, public);
        call_mulmodp_special(22);
        copy16(rz, result);
        
        // if(getBit(private, mul_loop_count))
        int bit = (llList2Int(private_list, mul_loop_count >> 4) >> (mul_loop_count & 0xF)) & 1;
        
        // if(bit) n = sqrmodp(submodp(ax, az));
        // else n = sqrmodp(submodp(qx, qz));
        if(bit){
            copy16(result, ax);
            copy16(argument, az);
        } else{
            copy16(result, qx);
            copy16(argument, qz);
        }
        
        call_submodp_special(25);
        call_sqrmodp_special(26);
        copy16(n, result);
        
        // if(bit) m = sqrmodp(addmodp(ax, az));
        // else m = sqrmodp(addmodp(qx, qz));
        if(bit){
            copy16(qx, rx);
            copy16(qz, rz);
            
            copy16(result, ax);
            copy16(argument, az);
        } else{
            copy16(ax, rx);
            copy16(az, rz);
            
            copy16(result, qx);
            copy16(argument, qz);
        }
        
        call_addmodp_special(23);
        call_sqrmodp_special(24);
        copy16(m, result);
        
        // o = submodp(m, n);
        copy16(argument, n);
        call_submodp_special(27);
        copy16(o, result);
        
        // if(bit) az = mulmodp(addmodp(mulasmall(o), m), o);
        // else qz = mulmodp(addmodp(mulasmall(o), m), o);
        call_mulasmall_special(29);
        copy16(argument, m);
        call_addmodp_special(30);
        copy16(argument, o);
        call_mulmodp_special(31);
        
        if(bit){
            copy16(az, result);
        } else{
            copy16(qz, result);
        }
        
        // if(bit) ax = mulmodp(n, m);
        // else qx = mulmodp(n, m);
        call_mulmodp(28, m, n);
        
        if(bit){
            copy16(ax, result);
        } else{
            copy16(qx, result);
        }
    jump mul_loop;
    @mul_loop_exit;
    
    copy16(m, qz);
    copy16(result, qz);
    
    mul_loop_count = 250;
    @invert_loop;
    if(!--mul_loop_count) jump invert_loop_exit;
        // qz = mulmodp(sqrmodp(qz), m);
        call_sqrmodp_special(32);
        copy16(argument, m);
        call_mulmodp_special(33);
    jump invert_loop;
    @invert_loop_exit;
    
    // qz = sqrmodp(qz);
    call_sqrmodp_special(34);
    
    // qz = sqrmodp(qz); qz = mulmodp(qz, m);
    call_sqrmodp_special(35);
    copy16(argument, m);
    call_mulmodp_special(36);
    
    // qz = sqrmodp(qz);
    call_sqrmodp_special(37);
    
    // qz = sqrmodp(qz); qz = mulmodp(qz, m);
    call_sqrmodp_special(38);
    copy16(argument, m);
    call_mulmodp_special(41);
    
    // qz = sqrmodp(qz); qz = mulmodp(qz, m);
    call_sqrmodp_special(39);
    copy16(argument, m);
    call_mulmodp_special(42);
    
    
    // return mulmodp(qx, qz);
    copy16(argument, qx);
    call_mulmodp_special(40);
    
    copy16(public, result);
    return;
    
    @dispatch;
        int dest = llList2Int(call_stack, 0xFFFFFFFF);
        call_stack = llDeleteSubList(call_stack, 0xFFFFFFFF, 0xFFFFFFFF);
        
        if(!dest) jump dispatch_0;
        else if(dest == 1) jump dispatch_1;
        else if(dest == 2) jump dispatch_2;
        else if(dest == 3) jump dispatch_3;
        else if(dest == 4) jump dispatch_4;
        else if(dest == 5) jump dispatch_5;
        else if(dest == 6) jump dispatch_6;
        else if(dest == 7) jump dispatch_7;
        else if(dest == 8) jump dispatch_8;
        else if(dest == 9) jump dispatch_9;
        else if(dest == 10) jump dispatch_10;
        else if(dest == 11) jump dispatch_11;
        else if(dest == 12) jump dispatch_12;
        else if(dest == 13) jump dispatch_13;
        else if(dest == 14) jump dispatch_14;
        else if(dest == 15) jump dispatch_15;
        else if(dest == 16) jump dispatch_16;
        else if(dest == 17) jump dispatch_17;
        else if(dest == 18) jump dispatch_18;
        else if(dest == 19) jump dispatch_19;
        else if(dest == 20) jump dispatch_20;
        else if(dest == 21) jump dispatch_21;
        else if(dest == 22) jump dispatch_22;
        else if(dest == 23) jump dispatch_23;
        else if(dest == 24) jump dispatch_24;
        else if(dest == 25) jump dispatch_25;
        else if(dest == 26) jump dispatch_26;
        else if(dest == 27) jump dispatch_27;
        else if(dest == 28) jump dispatch_28;
        else if(dest == 29) jump dispatch_29;
        else if(dest == 30) jump dispatch_30;
        else if(dest == 31) jump dispatch_31;
        else if(dest == 32) jump dispatch_32;
        else if(dest == 33) jump dispatch_33;
        else if(dest == 34) jump dispatch_34;
        else if(dest == 35) jump dispatch_35;
        else if(dest == 36) jump dispatch_36;
        else if(dest == 37) jump dispatch_37;
        else if(dest == 38) jump dispatch_38;
        else if(dest == 39) jump dispatch_39;
        else if(dest == 40) jump dispatch_40;
        else if(dest == 41) jump dispatch_41;
        else if(dest == 42) jump dispatch_42;
        
    // destroys: result
    @call_addmodp;
        factor = 1;
        jump call_addsubmodp;
        
    // destroys: result
    @call_submodp;
        factor = -1;
        
    @call_addsubmodp;
        int sub_const = 0x7FFF8 & factor;
        
        result0  = getBottom(v =            (0x80000 & factor) + ((get(result, 15) >> 15) +     factor * (get(argument, 15) >> 15) - (factor < 0)) * 19 + get(result, 0) + factor * get(argument, 0));
        result1  = getBottom(v = getTop(v) +         sub_const +   get(result,  1) +            factor *  get(argument,  1));
        result2  = getBottom(v = getTop(v) +         sub_const +   get(result,  2) +            factor *  get(argument,  2));
        result3  = getBottom(v = getTop(v) +         sub_const +   get(result,  3) +            factor *  get(argument,  3));
        result4  = getBottom(v = getTop(v) +         sub_const +   get(result,  4) +            factor *  get(argument,  4));
        result5  = getBottom(v = getTop(v) +         sub_const +   get(result,  5) +            factor *  get(argument,  5));
        result6  = getBottom(v = getTop(v) +         sub_const +   get(result,  6) +            factor *  get(argument,  6));
        result7  = getBottom(v = getTop(v) +         sub_const +   get(result,  7) +            factor *  get(argument,  7));
        result8  = getBottom(v = getTop(v) +         sub_const +   get(result,  8) +            factor *  get(argument,  8));
        result9  = getBottom(v = getTop(v) +         sub_const +   get(result,  9) +            factor *  get(argument,  9));
        result10 = getBottom(v = getTop(v) +         sub_const +   get(result, 10) +            factor *  get(argument, 10));
        result11 = getBottom(v = getTop(v) +         sub_const +   get(result, 11) +            factor *  get(argument, 11));
        result12 = getBottom(v = getTop(v) +         sub_const +   get(result, 12) +            factor *  get(argument, 12));
        result13 = getBottom(v = getTop(v) +         sub_const +   get(result, 13) +            factor *  get(argument, 13));
        result14 = getBottom(v = getTop(v) +         sub_const +   get(result, 14) +            factor *  get(argument, 14));
        result15 =              (getTop(v) + (0x7FF8 & factor) +  (get(result, 15) & 0x7fff) + factor * (get(argument, 15) & 0x7FFF));
        
        jump dispatch;
        
    // destroys: argument, result
    @call_mulasmall;
        set16_2(argument, 0xDB41, 0x1);
        jump call_mulmodp;
        
    // destroys: argument, result
    @call_sqrmodp;
        copy16(argument, result);
    
    // destroys: result
    @call_mulmodp;
        create_top_bottom(result0);
        create_top_bottom(result1);
        create_top_bottom(result2);
        create_top_bottom(result3);
        create_top_bottom(result4);
        create_top_bottom(result5);
        create_top_bottom(result6);
        create_top_bottom(result7);
        
        create_top_bottom(argument0);
        create_top_bottom(argument1);
        create_top_bottom(argument2);
        create_top_bottom(argument3);
        create_top_bottom(argument4);
        create_top_bottom(argument5);
        create_top_bottom(argument6);
        create_top_bottom(argument7);
    
        copy16(temp_result, result);
        copy16(temp_argument, argument);
        
        // Generate Z
        call_mul8h_special(4);
        copy16(z, result);
        
        // Generate X
        setTopBottom(result7, temp_result15);
        setTopBottom(result6, temp_result14);
        setTopBottom(result5, temp_result13);
        setTopBottom(result4, temp_result12);
        setTopBottom(result3, temp_result11);
        setTopBottom(result2, temp_result10);
        setTopBottom(result1, temp_result9);
        setTopBottom(result0, temp_result8);
        
        setTopBottom(argument7, argument15);
        setTopBottom(argument6, argument14);
        setTopBottom(argument5, argument13);
        setTopBottom(argument4, argument12);
        setTopBottom(argument3, argument11);
        setTopBottom(argument2, argument10);
        setTopBottom(argument1, argument9);
        setTopBottom(argument0, argument8);
        
        call_mul8h_special(5);
        copy16(x, result);
        
        // Generate Y
        setTopBottom(result7, temp_result15 + temp_result7);
        setTopBottom(result6, temp_result14 + temp_result6);
        setTopBottom(result5, temp_result13 + temp_result5);
        setTopBottom(result4, temp_result12 + temp_result4);
        setTopBottom(result3, temp_result11 + temp_result3);
        setTopBottom(result2, temp_result10 + temp_result2);
        setTopBottom(result1,  temp_result9 + temp_result1);
        setTopBottom(result0,  temp_result8 + temp_result0);
        
        setTopBottom(argument7, temp_argument15 + temp_argument7);
        setTopBottom(argument6, temp_argument14 + temp_argument6);
        setTopBottom(argument5, temp_argument13 + temp_argument5);
        setTopBottom(argument4, temp_argument12 + temp_argument4);
        setTopBottom(argument3, temp_argument11 + temp_argument3);
        setTopBottom(argument2, temp_argument10 + temp_argument2);
        setTopBottom(argument1,  temp_argument9 + temp_argument1);
        setTopBottom(argument0,  temp_argument8 + temp_argument0);
        
        call_mul8h_special(6);
        copy16(y, result);
        
        // Do mul
        int add_const = 0x7FFF80;
        
        result0  = getBottom(v = 0x800000 +              get(z,  0) + (get(y,  8) - get(x,  8) - get(z,  8) + get(x,  0) -0x80) * 38);
        result1  = getBottom(v = add_const + getTop(v) + get(z,  1) + (get(y,  9) - get(x,  9) - get(z,  9) + get(x,  1))       * 38);
        result2  = getBottom(v = add_const + getTop(v) + get(z,  2) + (get(y, 10) - get(x, 10) - get(z, 10) + get(x,  2))       * 38);
        result3  = getBottom(v = add_const + getTop(v) + get(z,  3) + (get(y, 11) - get(x, 11) - get(z, 11) + get(x,  3))       * 38);
        result4  = getBottom(v = add_const + getTop(v) + get(z,  4) + (get(y, 12) - get(x, 12) - get(z, 12) + get(x,  4))       * 38);
        result5  = getBottom(v = add_const + getTop(v) + get(z,  5) + (get(y, 13) - get(x, 13) - get(z, 13) + get(x,  5))       * 38);
        result6  = getBottom(v = add_const + getTop(v) + get(z,  6) + (get(y, 14) - get(x, 14) - get(z, 14) + get(x,  6))       * 38);
        result7  = getBottom(v = add_const + getTop(v) + get(z,  7) + (get(y, 15) - get(x, 15) - get(z, 15) + get(x,  7))       * 38);
        result8  = getBottom(v = add_const + getTop(v) + get(z,  8) +  get(y,  0) - get(x,  0) - get(z,  0) + get(x,  8)        * 38);
        result9  = getBottom(v = add_const + getTop(v) + get(z,  9) +  get(y,  1) - get(x,  1) - get(z,  1) + get(x,  9)        * 38);
        result10 = getBottom(v = add_const + getTop(v) + get(z, 10) +  get(y,  2) - get(x,  2) - get(z,  2) + get(x, 10)        * 38);
        result11 = getBottom(v = add_const + getTop(v) + get(z, 11) +  get(y,  3) - get(x,  3) - get(z,  3) + get(x, 11)        * 38);
        result12 = getBottom(v = add_const + getTop(v) + get(z, 12) +  get(y,  4) - get(x,  4) - get(z,  4) + get(x, 12)        * 38);
        result13 = getBottom(v = add_const + getTop(v) + get(z, 13) +  get(y,  5) - get(x,  5) - get(z,  5) + get(x, 13)        * 38);
        result14 = getBottom(v = add_const + getTop(v) + get(z, 14) +  get(y,  6) - get(x,  6) - get(z,  6) + get(x, 14)        * 38);
        result15 =               add_const + getTop(v) + get(z, 15) +  get(y,  7) - get(x,  7) - get(z,  7) + get(x, 15)        * 38;
        
        result0  = getBottom(v = ((result15 >> 15) & 0x1FFFF) * 19 + result0);
        result1  = getBottom(v = getTop(v) + result1);
        result2  = getBottom(v = getTop(v) + result2);
        result3  = getBottom(v = getTop(v) + result3);
        result4  = getBottom(v = getTop(v) + result4);
        result5  = getBottom(v = getTop(v) + result5);
        result6  = getBottom(v = getTop(v) + result6);
        result7  = getBottom(v = getTop(v) + result7);
        result8  = getBottom(v = getTop(v) + result8);
        result9  = getBottom(v = getTop(v) + result9);
        result10 = getBottom(v = getTop(v) + result10);
        result11 = getBottom(v = getTop(v) + result11);
        result12 = getBottom(v = getTop(v) + result12);
        result13 = getBottom(v = getTop(v) + result13);
        result14 = getBottom(v = getTop(v) + result14);
        result15 =               getTop(v) + (result15 & 0x7fff);
        
        jump dispatch;
        
    // Destroys: result
    @call_mul8h;
        make48(v);
        start48(v, result0, argument0);
        result0 = vl;
        
        start48(v, result0, argument1);
        mac48(v, result1, argument0);
        result1 = vl;
        
        start48(v, result0, argument2);
        mac48(v, result1, argument1);
        mac48(v, result2, argument0);
        result2 = vl;
        
        start48(v, result0, argument3);
        mac48(v, result1, argument2);
        mac48(v, result2, argument1);
        mac48(v, result3, argument0);
        result3 = vl;
        
        start48(v, result0, argument4);
        mac48(v, result1, argument3);
        mac48(v, result2, argument2);
        mac48(v, result3, argument1);
        mac48(v, result4, argument0);
        result4 = vl;
        
        start48(v, result0, argument5);
        mac48(v, result1, argument4);
        mac48(v, result2, argument3);
        mac48(v, result3, argument2);
        mac48(v, result4, argument1);
        mac48(v, result5, argument0);
        result5 = vl;
        
        start48(v, result0, argument6);
        mac48(v, result1, argument5);
        mac48(v, result2, argument4);
        mac48(v, result3, argument3);
        mac48(v, result4, argument2);
        mac48(v, result5, argument1);
        mac48(v, result6, argument0);
        result6 = vl;
        
        start48(v, result0, argument7);
        mac48(v, result1, argument6);
        mac48(v, result2, argument5);
        mac48(v, result3, argument4);
        mac48(v, result4, argument3);
        mac48(v, result5, argument2);
        mac48(v, result6, argument1);
        mac48(v, result7, argument0);
        result7 = vl;
        
        start48(v, result1, argument7);
        mac48(v, result2, argument6);
        mac48(v, result3, argument5);
        mac48(v, result4, argument4);
        mac48(v, result5, argument3);
        mac48(v, result6, argument2);
        mac48(v, result7, argument1);
        result8 = vl;
        
        start48(v, result2, argument7);
        mac48(v, result3, argument6);
        mac48(v, result4, argument5);
        mac48(v, result5, argument4);
        mac48(v, result6, argument3);
        mac48(v, result7, argument2);
        result9 = vl;
        
        start48(v, result3, argument7);
        mac48(v, result4, argument6);
        mac48(v, result5, argument5);
        mac48(v, result6, argument4);
        mac48(v, result7, argument3);
        result10 = vl;
        
        start48(v, result4, argument7);
        mac48(v, result5, argument6);
        mac48(v, result6, argument5);
        mac48(v, result7, argument4);
        result11 = vl;
        
        start48(v, result5, argument7);
        mac48(v, result6, argument6);
        mac48(v, result7, argument5);
        result12 = vl;
        
        start48(v, result6, argument7);
        mac48(v, result7, argument6);
        result13 = vl;
        
        start48(v, result7, argument7);
        result14 = vl;
        result15 = vh;
        
        jump dispatch;
}
    
