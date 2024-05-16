//+------------------------------------------------------------------+
//|                                                         json.mqh |
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
// Include necessary MQL4 headers
#include <Arrays\ArrayObj.mqh>
#include <Strings\String.mqh>

class CJSON
{
private:
   class CJSONValue
{
public:
    JSON_TYPE type;
    string key;
    string value_str;
    double value_num;
    bool value_bool;
    CArrayObj* value_array;
    CArrayObj* value_object;

    CJSONValue(JSON_TYPE type, string key, string value_str = "", double value_num = 0.0, bool value_bool = false, CArrayObj* value_array = NULL, CArrayObj* value_object = NULL)
    {
        this.type = type;
        this.key = key;
        this.value_str = value_str;
        this.value_num = value_num;
        this.value_bool = value_bool;
        this.value_array = value_array;
        this.value_object = value_object;
    }

    ~CJSONValue()
    {
        if (value_array != NULL)
            delete value_array;
        if (value_object != NULL)
            delete value_object;
    }
};
    CArrayObj* json_data;

 
void ParseObject(string json, int &pos, CArrayObj* array_obj)
{
    while (pos < StringLen(json))
    {
        // Skip whitespace characters
        while (StringIsSpace(StringGetChar(json, pos))) {
            pos++;
        }

        // Check for the end of the object
        if (StringGetChar(json, pos) == '}')
        {
            pos++; // Move to the next character after '}'
            break;
        }

        // Parse key
        string key;
        if (StringGetChar(json, pos) == '"')
        {
            // Parse string key
            pos++; // Skip the opening quote
            int endPos = StringFind(json, '"', pos); // Find the closing quote
            key = StringSubstr(json, pos, endPos - pos); // Extract the key
            pos = endPos + 1; // Move past the closing quote
        }

        // Skip whitespace characters after key
        while (StringIsSpace(StringGetChar(json, pos))) {
            pos++;
        }

        // Check for colon between key and value
        if (StringGetChar(json, pos) != ':') {
            // Handle syntax error
            Print("Syntax error: Missing colon between key and value.");
            return;
        }

        pos++; // Move past the colon

        // Skip whitespace characters after colon
        while (StringIsSpace(StringGetChar(json, pos))) {
            pos++;
        }

        // Parse value based on JSON type
        if (StringGetChar(json, pos) == '{')
        {
            // Parse JSON object recursively
            CJSONValue* value = new CJSONValue(JSON_OBJECT, key);
            array_obj.values.Add(value);
            ParseObject(json, ++pos, value.value_object);
        }
        // Add other value type parsing logic here

        // Skip whitespace characters after value
        while (StringIsSpace(StringGetChar(json, pos))) {
            pos++;
        }

        // Check for comma or end of object
        if (StringGetChar(json, pos) == ',')
        {
            pos++; // Move past the comma
        }
        else if (StringGetChar(json, pos) == '}')
        {
            // End of object
            pos++; // Move past '}'
            break;
        }
        else
        {
            // Handle syntax error
            Print("Syntax error: Missing comma or end of object.");
            return;
        }
    }
}
  

public:
    CJSON()
    {
        json_data = new CArrayObj();
    }
void ParseArray(string json, int &pos, CArrayObj* array_obj)
{  
    int len = StringLen(json);
    while (pos < len)
    {
        char ch = StringGetCharacter(json, pos);
        if (ch == ']')
            break; // End of array
        else if (ch == ',')
        {
            pos++; // Skip comma
        }
        else if (ch == '"')
        {
            // String value
            pos++;
            string value = ExtractStringValue(json, pos);
            array_obj.Add(new CJSONValue(JSON_STRING, "", value));
        }
        else if (ch == '[')
        {
            // Nested array
            pos++;
            CArrayObj* arr = new CArrayObj();
            ParseArray(json, pos, arr);
            array_obj.Add(new CJSONValue(JSON_ARRAY, "", "", 0.0, false, arr));
        }
        else if (ch == '{')
        {
            // Nested object
            pos++;
            CArrayObj* obj = new CArrayObj();
            ParseObject(json, pos, obj);
            array_obj.Add(new CJSONValue(JSON_OBJECT, "", "", 0.0, false, NULL, obj));
        }
        else
        {
            // Number, boolean, or null value
            double num_value = ExtractNumberValue(json, pos);
            bool bool_value = ExtractBoolValue(json, pos);
            array_obj.Add(new CJSONValue(JSON_NUMBER, "", "", num_value, bool_value));
        }
    }
    pos++; // Skip closing bracket
}

    ~CJSON()
    {
        if (json_data != NULL)
            delete json_data;
    }

    void ParseJSON(string json)
    {
        int pos = 0;
        ParseObject(json, pos, json_data);
    }

  string ExtractStringValue(string json, int &pos)
{
    int len = StringLen(json);
    string value = "";
    while (pos < len)
    {
        char ch = StringGetCharacter(json, pos);
        if (ch == '"')
            break; // End of string
        else
        {
            value += ch;
            pos++;
        }
    }
    pos++; // Skip closing quote
    return value;
}
double ExtractNumberValue(string json, int &pos)
{
    int len = StringLen(json);
    string value_str = "";
    while (pos < len)
    {
        char ch = StringGetCharacter(json, pos);
        if ((ch >= '0' && ch <= '9') || ch == '.' || ch == '-')
        {
            value_str += ch;
            pos++;
        }
        else
        {
            break;
        }
    }
    return StringToDouble(value_str);
}

bool ExtractBoolValue(string json, int &pos)
{
    int len = StringLen(json);
    string value_str = "";
    while (pos < len)
    {
        char ch = StringGetCharacter(json, pos);
        if (ch == 't' || ch == 'T' || ch == 'f' || ch == 'F')
        {
            value_str += ch;
            pos++;
        }
        else
        {
            break;
        }
    }
    return (StringToLower(value_str) == "true" || StringToLower(value_str) == "t");
}


};
