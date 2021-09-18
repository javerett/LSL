#include "bits256.h"

create_var_16(schedule);
create_var_16(keystream);

#define ROTL32(a, b) \
    (((a) << (b)) | (((a) >> (32 - (b))) & ~(0xFFFFFFFF << (b))))

#define QR(a, b, c, d) \
    get(keystream, a) += get(keystream, b); get(keystream, d) = ROTL32(get(keystream, d) ^ get(keystream, a), 16); \
    get(keystream, c) += get(keystream, d); get(keystream, b) = ROTL32(get(keystream, b) ^ get(keystream, c), 12); \
    get(keystream, a) += get(keystream, b); get(keystream, d) = ROTL32(get(keystream, d) ^ get(keystream, a),  8); \
    get(keystream, c) += get(keystream, d); get(keystream, b) = ROTL32(get(keystream, b) ^ get(keystream, c),  7)

#define inc16(dest, src) \
    dest##0  += src##0;  dest##1  += src##1;  dest##2  += src##2;  dest##3  += src##3; \
    dest##4  += src##4;  dest##5  += src##5;  dest##6  += src##6;  dest##7  += src##7; \
    dest##8  += src##8;  dest##9  += src##9;  dest##10 += src##10; dest##11 += src##11; \
    dest##12 += src##12; dest##13 += src##13; dest##14 += src##14; dest##15 += src##15

#define chacha20_setup(k0, k1, k2, k3, k4, k5, k6, k7, n0, n1) \
    schedule0 = 0x61707865; \
    schedule1 = 0x3320646E; \
    schedule2 = 0x79622D32; \
    schedule3 = 0x6B206574; \
    schedule4 = k0; \
    schedule5 = k1; \
    schedule6 = k2; \
    schedule7 = k3; \
    schedule8 = k4; \
    schedule9 = k5; \
    schedule10 = k6; \
    schedule11 = k7; \
    schedule12 = 0; \
    schedule13 = 0; \
    schedule14 = n0; \
    schedule15 = n1
    
// Key: 4 - 11
// Counter: 12 - 13
// Nonce: 14 - 15

chacha20(){
    copy16(keystream, schedule);
    
    int i = 10;
    while(i--){
        QR(0, 4, 8, 12);
        QR(1, 5, 9, 13);
        QR(2, 6, 10, 14);
        QR(3, 7, 11, 15);
        QR(0, 5, 10, 15);
        QR(1, 6, 11, 12);
        QR(2, 7, 8, 13);
        QR(3, 4, 9, 14);
    }
    
    inc16(keystream, schedule);
    
    // Inc nonce counter
    if(!++schedule12) if(!++schedule13) if(!++schedule14) ++schedule15;
}
