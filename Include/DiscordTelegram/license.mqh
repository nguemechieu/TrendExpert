//+------------------------------------------------------------------+
//|                                                      license.mqh |
//|                                     Copyright 2023, sopotek ,inc |
//|                   https://www.github.com/nguemechieu/tradeexpert |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, sopotek ,inc"
#property link      "https://www.github.com/nguemechieu/tradeexpert"
#property strict
#include <DiscordTelegram/CCryptAES.mqh>
#include <DiscordTelegram/CCryptDES.mqh>
#include  <DiscordTelegram/UserDataBase.mqh>
#include <DiscordTelegram/User.mqh>

#include <Arrays/ArrayObj.mqh> // Include the ArrayObj class for dynamic arrays
#include <Arrays/List.mqh>          // Include the Object class for inheritance


#define COUNTACC 5
#define PRODMAXLENGTH 255

#define __DEBUG_USERMQH__

struct ea_user{
   ea_user() {expired = -1;}
   datetime expired;
   int      namelength;
   char    uname[PRODMAXLENGTH];
   void SetEAname(string name) {
      namelength = StringToCharArray(name, uname);
   }
   string GetEAname() {
      return CharArrayToString(uname, 0, namelength);
   }
   bool IsExpired() {
      if (expired == -1) return false; // NOT expired
      return expired <= TimeLocal();
   }
};//struct ea_user

struct user_lic {
   user_lic() {
      uid       = -1;
      log_count =  0;
      ea_count  =  0;
      expired   = -1;
      ArrayFill(logins, 0, COUNTACC, 0);
   }
   long uid;
   datetime expired;
   int  log_count;
   long logins[COUNTACC];   
   int  ea_count;
   bool AddLogin(long lg){
      if (log_count >= COUNTACC) return false;
      logins[log_count++] = lg;
      return true;
   }
   long GetLogin(int num) {
      if (num >= log_count) return -1;
      return logins[num];
   }
   bool IsExpired() {
      if (expired == -1) return false; // NOT expired
      return expired <= TimeLocal();
   }   
};//struct user_lic

class CLic {

public:

   static int iSizeEauser;
   static int iSizeUserlic;
   
   CLic() {}
  ~CLic() {}
   
   int SetUser(const user_lic& header){
      Reset();
      if (!StructToCharArray(header, dest) ) return 0;
      return ArraySize(dest);
   }//int SetUser(user_lic& header)
// Define a custom ArrayInsert function to insert elements into an array at a specified position
void ArrayInsert(CArrayObj &array[] , const CObject& element, int index) {
    // Check if the index is within bounds
    if (index < 0 || index > ArraySize(array)) {
        Print("Error: Invalid index for ArrayInsert");
        return;
    }

    // Resize the array to accommodate the new element
    ArrayResize(array, ArraySize(array) + 1);

    // Shift elements to the right to make space for the new element
    for (int i = ArraySize(array) - 1; i > index; i--) {
        array[i] = array[i - 1];
    }

    // Insert the new element at the specified index
    array[index] = element;
}

// Define a custom ArraySave function to save an array to a file
void ArraySave(CArrayObj &data[],  int &count, string fileName) {
    // Open the file for writing
    int fileHandle = FileOpen(fileName, FILE_WRITE|FILE_BIN);
    if (fileHandle == INVALID_HANDLE) {
        Print("Error: Failed to open file ", fileName, " for writing");
        return;
    }



    // Write the array elements to the file


    // Close the file
    FileClose(fileHandle);
}
   int AddEA(const ea_user& eax) {
      int c = ArraySize(dest);
      if (c == 0) return 0;
      uchar tmp[];
      
      return 0;
      }
   
   bool GetUser(user_lic& header) const {
      if (ArraySize(dest) < iSizeUserlic) return false;
      return CharArrayToStruct(header, dest);
   }//bool GetUser(user_lic& header)
   
   //num - 0 based
   bool GetEA(int num, ea_user& eaX) const {
      int index = iSizeUserlic + num * iSizeEauser;
      if (ArraySize(dest) < index + iSizeEauser) return false;
      return CharArrayToStruct(eaX, dest, index);
   }//bool GetEA(int num, ea_user& ea)
   
   int Encode(ENUM_CRYPT_METHOD method, string key, uchar&  buffer[]) const {
      if (ArraySize(dest) < iSizeUserlic) return 0;
      if(!IsKeyCorrect(method, key) ) return 0;      
      uchar k[];
      StringToCharArray(key, k);
      return CryptEncode(method, dest, k, buffer); 
   }
   
   int Decode(ENUM_CRYPT_METHOD method, string key, uchar&  buffer[]) {
      Reset();
      if(!IsKeyCorrect(method, key) ) return 0;
      uchar k[];
      StringToCharArray(key, k);
      return CryptDecode(method, buffer, k, dest); 
   }   
#ifdef __DEBUG_USERMQH__   
   void SaveArray(){
      int h = FileOpen("encrypruser.bin", FILE_WRITE | FILE_BIN);
      if (h == INVALID_HANDLE) {
         Print("File create failed: encrypruser.bin");
      }else {
         FileWriteArray(h, dest);
         FileClose(h);            
      }
      uchar key[], result[];
      CryptEncode(CRYPT_BASE64,dest,key,result);    
      int h1 = FileOpen("encrypruser_base64.bin", FILE_WRITE | FILE_BIN);
      if (h1 == INVALID_HANDLE) {
         Print("File create failed: encrypruser.bin");
      }else {
         FileWriteArray(h1, result);
         FileClose(h1);            
      }        
   }
#endif 
protected:
   void Reset() {ArrayResize(dest, 0);}
   
   bool IsKeyCorrect(ENUM_CRYPT_METHOD method, string key) const {
      int len = StringLen(key);
      switch (method) {
         case CRYPT_AES128:
            if (len == 16) return true;
            break;
         case CRYPT_AES256:
            if (len == 32) return true;
            break;
         case CRYPT_DES:
            if (len == 7) return true;
            break;
      }
#ifdef __DEBUG_USERMQH__
   Print("Key length is incorrect: ",len);
#endif       
      return false;
   }//bool IsKeyCorrect(ENUM_CRYPT_METHOD method, string key)
   
private:
   uchar dest[];
};//class CLic

   static int CLic::iSizeEauser  = sizeof(ea_user);  //267
   static int CLic::iSizeUserlic = sizeof(user_lic); //64

bool CreateLic(ENUM_CRYPT_METHOD method, string key, CLic& li, string licname) {
   uchar cd[];
   if (li.Encode(method, key, cd) == 0) return false;
   int h = FileOpen(licname, FILE_WRITE | FILE_BIN);
   if (h == INVALID_HANDLE) {
#ifdef __DEBUG_USERMQH__
      Print("File create failed: ",licname);
#endif    
      return false;
   }
   FileWriteArray(h, cd);
   FileClose(h);  
#ifdef __DEBUG_USERMQH__    
   li.SaveArray();
#endif    
   return true;
}// bool CreateLic(ENUM_CRYPT_METHOD method, string key, const CLic& li, string licname)


bool ReadLic(ENUM_CRYPT_METHOD method, string key, CLic& li, string licname) {
   int h = FileOpen(licname, FILE_READ | FILE_BIN);
   if (h == INVALID_HANDLE) {
#ifdef __DEBUG_USERMQH__
      Print("File open failed: ",licname);
#endif    
      return false;
   }
   uchar cd[];
   FileReadArray(h,cd);
   if (ArraySize(cd) < CLic::iSizeUserlic) {
#ifdef __DEBUG_USERMQH__
      Print("File too small: ",licname);
#endif    
      return false;
   }
   li.Decode(method, key, cd);
   FileClose(h);
   return true;
}// bool ReadLic(ENUM_CRYPT_METHOD method, string key, CLic& li, string licname)

