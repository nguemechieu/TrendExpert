//+------------------------------------------------------------------+
//|                                                        Crypt.mqh |
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
#ifndef __CRYPT_MQH__

// Include necessary headers
#include <Arrays\ArrayChar.mqh>
#ifndef __CRYPT_MQH__
#define __CRYPT_MQH__

#include <WinUser32.mqh> // Include WinUser32.mqh for MD5 hash calculation
#include <DiscordTelegram/SHA256.mqh>    // Include SHA256.mqh for SHA-256 hash calculation

enum ENUM_HASH_METHOD {
    HASH_MD5,    // MD5 hash
    HASH_SHA1,   // SHA-1 hash
    HASH_SHA256, // SHA-256 hash
    // Add more hash algorithms as needed
};
// Function to decode a Base64 encoded string to a byte array
bool Base64Decode(const string& inputs, uchar& output[], int& size) {
    // Define the Base64 characters
    string base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // Initialize variables
    int inputLength = StringLen(inputs);
    int paddingCount = 0;
    size = 0;

    // Count padding characters '=' at the end of the input
    for (int i = inputLength - 1; i >= 0; i--) {
        if (inputs[i] == '=') {
            paddingCount++;
        } else {
            break;
        }
    }

    // Calculate the size of the output array
    size = (inputLength * 3) / 4 - paddingCount;
    if (size <= 0) return false;  // Invalid input size

    // Allocate memory for the output array
    ArrayResize(output, size);

    int buffer = 0;  // Buffer to hold 4 Base64 characters at a time for decoding
    int bufferLength = 0;  // Length of data in the buffer

    for (int i = 0; i < inputLength; i++) {
        char c = inputs[i];
        int index = base64Chars.Find(c);
        if (index < 0) return false;  // Invalid Base64 character

        // Append the bits of the Base64 character to the buffer
        buffer = (buffer << 6) | index;
        bufferLength += 6;

        // If buffer is full (contains 8 bits or more), decode it to output array
        if (bufferLength >= 8) {
            bufferLength -= 8;
            output[size - (inputLength - i - 1) * 3 / 4 - 1] = (uchar)((buffer >> bufferLength) & 0xFF);
        }
    }

    return true;  // Decoding successful
}

// Convert a string to a hash value using the specified hash algorithm
string StringToHash(const string& data, ENUM_HASH_METHOD method) {
    if (method == HASH_MD5) {
        uchar hash[16]; // MD5 hash size
        MD5Buffer(data, hash);
        string result;
        for (int i = 0; i < 16; i++) {
            result += StringFormat("%02x", hash[i]);
        }
        return result;
    }
    else if (method == HASH_SHA1) {
        uchar hash[20]; // SHA-1 hash size
        SHA1Buffer(data, hash);
        string result;
        for (int i = 0; i < 20; i++) {
            result += StringFormat("%02x", hash[i]);
        }
        return result;
    }
    else if (method == HASH_SHA256) {
        uchar hash[32]; // SHA-256 hash size
        SHA256Buffer(data, hash);
        string result;
        for (int i = 0; i < 32; i++) {
            result += StringFormat("%02x", hash[i]);
        }
        return result;
    }
    return ""; // Unsupported hash algorithm
}

#endif // __CRYPT_MQH__

// Define encryption methods
// Function to encode a byte array to Base64
string Base64Encode(const uchar& inputs[], int size) {
    // Define the Base64 characters
    string base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    string output;  // Output string for Base64 encoded data

    int i = 0;  // Index for input array
    uchar buffer[3];  // Buffer to hold 3 bytes at a time for encoding

    while (i < size) {
        // Fill the buffer with 3 bytes from the input
        buffer[0] = inputs[i++];
        buffer[1] = (i < size) ? inputs[i++] : 0;
        buffer[2] = (i < size) ? inputs[i++] : 0;

        // Encode the buffer using Base64 algorithm
        output += base64Chars[(buffer[0] >> 2) & 0x3F];  // First 6 bits of first byte
        output += base64Chars[((buffer[0] << 4) | (buffer[1] >> 4)) & 0x3F];  // Last 2 bits of first byte + first 4 bits of second byte
        output += (i > size + 1) ? '=' : base64Chars[((buffer[1] << 2) | (buffer[2] >> 6)) & 0x3F];  // Last 4 bits of second byte + first 2 bits of third byte
        output += (i > size) ? '=' : base64Chars[buffer[2] & 0x3F];  // Last 6 bits of third byte
    }

    return output;
}

// Encrypt data using the specified encryption method and key
bool CryptEncode(ENUM_CRYPT_METHOD method, const string& data, const string& key, string& result) {
 if (method == CRYPT_BASE64) {
        result = Base64Encode(data);
        return true;
    }
    else if (method == CRYPT_AES256) {
        // Implement AES encryption
        // Example: AES encryption using Crypto library
        Crypto aes;
        result = aes.Encrypt(data, key);
        return true;
    }
    else if (method == CRYPT_DES) {
        // Implement DES encryption
        // Example: DES encryption using Crypto library
        // Crypto des;
        // result = des.Encrypt(data, key);
        return true;
    }
    else if (method == CRYPT_HASH_MD5) {
        result = StringToHash(data, HASH_MD5);
        return true;
    }
    else if (method == CRYPT_HASH_SHA1) {
        result = StringToHash(data, HASH_SHA1);
        return true;
    }
    else if (method == CRYPT_HASH_SHA256) {
        result = StringToHash(data, HASH_SHA256);
        return true;
    }
    return false; // Unsupported encryption method
}

// Decrypt data using the specified encryption method and key
bool CryptDecode(ENUM_CRYPT_METHOD method, const string& data, const string& key, uchar &result[]) {
    if (method == CRYPT_NO) {
        result = data;
        return true;
    }
    else if (method == CRYPT_BASE64) {
        result = Base64Decode(key,result,ArraySize(result));
        return true;
    }
    else if (method == CRYPT_AES256) {
        // Implement AES decryption
        // Example: AES decryption using Crypto library
        // Crypto aes;
        // result = aes.Decrypt(data, key);
        return true;
    }
    else if (method == CRYPT_DES) {
        // Implement DES decryption
        // Example: DES decryption using Crypto library
        // Crypto des;
        // result = des.Decrypt(data, key);
        return true;
    }
    return false; // Unsupported encryption method
}

// Function to compute the SHA-1 hash of a buffer
bool SHA1Buffer(const uchar& buffer[], int bufferSize, uchar& hash[], int& hashSize) {
    CArrayChar dataBuffer; // Create an ArrayChar object to hold the buffer data
    dataBuffer.CopyArray(buffer, bufferSize); // Copy the buffer data to the ArrayChar object

    CSHA1 sha1; // Create an instance of the SHA-1 algorithm
    sha1.Update(dataBuffer); // Update the SHA-1 algorithm with the buffer data
    sha1.Final(); // Finalize the SHA-1 computation

    CArrayChar result; // Create an ArrayChar object to hold the hash result
    sha1.GetHash(result); // Get the computed hash from the SHA-1 algorithm

    hashSize = result.Total(); // Get the size of the hash
    if (hashSize <= 0) return false; // Check for invalid hash size

    // Allocate memory for the output hash array
    ArrayResize(hash, hashSize);
    // Copy the hash data from the result ArrayChar object to the output hash array
    ArrayCopyArray(hash, result, 0, 0, hashSize);

    return true; // Hash computation successful
}
#endif // __CRYPT_MQH__
