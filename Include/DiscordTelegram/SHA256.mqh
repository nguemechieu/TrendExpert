//+------------------------------------------------------------------+
//|                                                       SHA256.mqh |
//|                                     Copyright 2023, sopotek ,inc |
//|                   https://www.github.com/nguemechieu/tradeexpert |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, sopotek ,inc"
#property link      "https://www.github.com/nguemechieu/tradeexpert"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
// Define the ROTR macro if not already defined
#ifndef ROTR
#define ROTR(x, n) (((x) >> (n)) | ((x) << (32 - (n))))
#endif
#ifndef __SHA256_MQH__
#define __SHA256_MQH__

// Define uint32 type if not already defined
#ifndef uint32
#define uint32 unsigned int
#endif

// Constants for SHA-256 computation
#define SHA256_BLOCK_SIZE   64
#define SHA256_DIGEST_SIZE  32

// SHA-256 context structure
struct SHA256_CTX {
    uint32 total[2];   // Number of bytes processed
    uint32 state[8];   // Intermediate hash value
    uchar buffer[SHA256_BLOCK_SIZE]; // Data block being processed
};

// Initialize SHA-256 context
void SHA256Init(SHA256_CTX& ctx) {
    ctx.total[0] = 0;
    ctx.total[1] = 0;
    ctx.state[0] = 0x6A09E667;
    ctx.state[1] = 0xBB67AE85;
    ctx.state[2] = 0x3C6EF372;
    ctx.state[3] = 0xA54FF53A;
    ctx.state[4] = 0x510E527F;
    ctx.state[5] = 0x9B05688C;
    ctx.state[6] = 0x1F83D9AB;
    ctx.state[7] = 0x5BE0CD19;
}

// SHA-256 update function
void SHA256Update(SHA256_CTX& ctx, const uchar &inputs[], uint32 length) {
    uint32 left = length;
    uint32 offset = (ctx.total[0] >> 3) % SHA256_BLOCK_SIZE;
     uchar data = inputs[0];
    uint32 index = (uint32)((ctx.total[0] >> 3) & 0x3F);

    ctx.total[0] += length << 3;
    ctx.total[1] += length >> 29;

    if ((ctx.total[0] += length << 3) < length << 3) {
        ctx.total[1]++;
    }

    if (offset) {
        uint32 space = SHA256_BLOCK_SIZE - offset;
        uint32 copy = (length < space) ? length : space;
        
        memcpy(ctx.buffer, data, copy);

        if (length < space) return;

        data += copy;
        left -= copy;
        SHA256Transform(ctx.state, ctx.buffer);
    }

    while (left >= SHA256_BLOCK_SIZE) {
        memcpy(ctx.buffer, data, SHA256_BLOCK_SIZE);
        data += SHA256_BLOCK_SIZE;
        left -= SHA256_BLOCK_SIZE;
        SHA256Transform(ctx.state, ctx.buffer);
    }

    if (left) {
        memcpy(ctx.buffer,data, left);
    }
}

// SHA-256 finalization function
void SHA256Final(SHA256_CTX& ctx, uchar &hash[]) {
    uint32 index = (uint32)((ctx.total[0] >> 3) & 0x3F);
    uint32 padLen = (index < 56) ? (56 - index) : (120 - index);
    uchar padding[SHA256_BLOCK_SIZE] = { 0x80 };

    SHA256Update(ctx, padding, padLen);

    // Append total bits
    for (int i = 0; i < 8; i++) {
        ctx.buffer[56 + i] = (uchar)(ctx.total[(i >= 4) ? 0 : 1] >> ((3 - i) * 8));
    }

    SHA256Transform(ctx.state, ctx.buffer);

    // Output hash
    for (int i = 0; i < 8; i++) {
        hash[i * 4] = (uchar)(ctx.state[i] >> 24);
        hash[i * 4 + 1] = (uchar)(ctx.state[i] >> 16);
        hash[i * 4 + 2] = (uchar)(ctx.state[i] >> 8);
        hash[i * 4 + 3] = (uchar)(ctx.state[i]);
    }

    memset(ctx.buffer, 0, sizeof(ctx));
}

// Define the memset function for setting memory blocks


 // Define the memset function for setting memory blocks
void memset(uchar& dst[], uchar value, int size) {
    // Check if the size is valid
    if (ArraySize(dst) < size) {
        Print("Error: Invalid size for memset operation.");
        return;
    }

    // Set the memory block to the specified value
    for (int i = 0; i < size; i++) {
        dst[i] = value;
    }
}

// Define the memcpy function for copying memory blocks
void memcpy(uchar& dst[], uchar& src, int size) {
    uchar dstArray[];
    uchar srcArray[];
    ArrayResize(dst,size,0);

    // Convert destination and source to byte arrays
    StringToCharArray(dst[0],dstArray,0,WHOLE_ARRAY,CP_ACP);
    StringToCharArray((string)src, srcArray,0, WHOLE_ARRAY,CP_ACP);

    // Check if the size is valid
    if (ArraySize(dstArray) < size || ArraySize(srcArray) < size) {
        Print("Error: Invalid size for memcpy operation.");
        return;
    }

    // Copy the memory block
    for (int i = 0; i < size; i++) {
        dstArray[i] = srcArray[i];
    }

    // Convert back to string
    dst[0] = CharArrayToString(dstArray, 0, size);
}
// Perform SHA-256 transformation on the data block
void SHA256Transform(uint32 &state[], const uchar &block[]) {
    uint32 w[64];
    w[0]=0;
    uint32 a, b, c, d, e, f, g, h,k[];
    uint32 t1;

    for (int i = 0; i < 16; i++) {
        w[i] = (block[i * 4] << 24) | (block[i * 4 + 1] << 16) | (block[i * 4 + 2] << 8) | (block[i * 4 + 3]);
    }

    for (int i = 16; i < 64; i++) {
        uint32 s0 = ROTR(w[i - 15], 7) ^ ROTR(w[i - 15], 18) ^ (w[i - 15] >> 3);
        uint32 s1 = ROTR(w[i - 2], 17) ^ ROTR(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = w[i - 16] + s0 + w[i - 7] + s1;
    }

    a = state[0];
    b = state[1];
    c = state[2];
    d = state[3];
    e = state[4];
    f = state[5];
    g = state[6];
    h = state[7];

    for (int i = 0; i < 64; i++) {
        uint32 s0 = ROTR(a, 2) ^ ROTR(a, 13) ^ ROTR(a, 22);
        uint32 maj = (a & b) ^ (a & c) ^ (b & c);
        uint32 t2 = s0 + maj;
        uint32 s1 = ROTR(e, 6) ^ ROTR(e, 11) ^ ROTR(e, 25);
        uint32 ch = (e & f) ^ ((~e) & g);
        t1 = h + s1 + ch + k[i] + w[i];

        h = g;
        g = f;
        f = e;
        e = d + t1;
        d = c;
        c = b;
        b = a;
        a = t1 + t2;
    }

    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
    state[4] += e;
    state[5] += f;
    state[6] += g;
    state[7] += h;
}

#endif // __SHA256_MQH__