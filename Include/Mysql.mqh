//+------------------------------------------------------------------+
//|                                                    EAX_mysql.mqh |
//|          Copyright 2012, Michael Schoen <michael@schoen-hahn.de> |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024,nguemechieu noel martial"
#property version   "1.02"

/**
+------------------------------------------------------------------+
Version History
25/05/2012 MS | Fix on 64 bit
26/05/2012 MN | Alert Box for Error Handling of SQL added
01/06/2012 MN | Fix for inserting / updating difference
+------------------------------------------------------------------+
**/



#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayString.mqh>
#include <Arrays\ArrayInt.mqh>

#import "libmysql.dll"
    int mysql_init(int mysql);
    int mysql_real_connect(int mysql, string& host, string& user, string& password,
                           string& DB,int port,int socket,int clientflag);    
    int mysql_real_query(int mysql,string query,int lenght);                        
    int mysql_errno(int mysql);
    int mysql_fetch_row(int mysql);
    int mysql_fetch_field(int mysql);
    int mysql_fetch_lengths(int mysql);
    int mysql_store_result(int mysql);
    int mysql_field_count(int mysql);
    int mysql_num_rows(int mysql);
    int mysql_num_fields(int mysql);
    int mysql_free_result(int mysql);
    int mysql_insert_id(int mysql);
    
    void mysql_close(int mysql);                        
    string mysql_error(int mysql);
    int mysql_get_client_info();
    int mysql_get_host_info(int mysql);
    int mysql_get_host_info(int mysql);
    int mysql_get_server_info(int mysql);
    int mysql_character_set_name(int mysql);
    
    int mysql_stat(int mysql);    
    
    
      
#import "msvcrt.dll"
  // TODO extend/handle 32/64 bit codewise
  int memcpy(char &Destination[], int Source, int Length);
  int memcpy(char &Destination[], long Source, int Length);
  int memcpy(int &dst,  int src, int cnt);
  int memcpy(long &dst,  long src, int cnt);  
#import

static int __db_mysql_global;

class CMysql {

private:

    class CMysqlField : public CObject {
    public:
        string key;
        string value;
        int modified;
        CMysqlField() { modified = 0; };
    };

    class CMysqlRow : public CObject {
    public:
        CArrayObj* fields;
        int changed;
        int updated;
        CMysqlRow() { fields = new CArrayObj(); changed = 0; updated = 0; };
        ~CMysqlRow() { delete(fields); };

    };

    CArrayObj* m_rows;

    string hostname;
    string username;
    string password;
    string database;
    string tablename;
    int xresults;

  protected:  int db;
    void clear();
    string implode(string, CArrayString* pString);
    string escape(string );
    string get_primary_key(string);
    
    void error(string query);
    
    string UNICODE2ANSI(string);
    string ANSI2UNICODE(string);
    bool is64;

public:
    /**
     * Constructor for CMysql class.
     */
    CMysql();

    /**
     * Destructor for CMysql class.
     */
    ~CMysql();

    /**
     * Connects to the MySQL database.
     * @param hostname MySQL server hostname.
     * @param username MySQL username.
     * @param password MySQL password.
     * @param database MySQL database name.
     * @param table MySQL table name.
     */
    void connect(string hostname, string username, string password, string database, string table);

    /**
     * Reads rows from the database based on the SQL query.
     * @param strSQL SQL query to read rows.
     * @return Number of rows read.
     */
    int read_rows(string strSQL);

    /**
     * Retrieves a value from the database based on key and index.
     * @param strKey Key to search for.
     * @param iValue Index of the value.
     * @return Retrieved value.
     */
    string get(string strKey, int iValue);

    /**
     * Clears the data rows.
     */
    

    /**
     * Adds a new row to the specified table.
     * @param strTable Table name.
     */
    void AddNew(string strTable);

    /**
     * Escapes special characters in a string for SQL queries.
     * @param strInput Input string to escape.
     * @return Escaped string.
     */
  

    /**
     * Sets a value in the current row.
     * @param strKey Key to set.
     * @param strValue Value to set.
     */
    void set(string strKey, string strValue);

    /**
     * Selects a table for querying.
     * @param xtablename Table name to select.
     */
    void select(string xtablename);

    /**
     * Reads a value from the database based on a given value.
     * @param strValue Value to search for.
     * @return Number of rows read.
     */
    int read(string strValue);

    /**
     * Writes data to the database.
     * @return Status of the write operation.
     */
    void write(string str);
    
    bool isConnected();

};

/**
 * Constructor implementation for CMysql class.
 */
CMysql::CMysql() {

    if (MQLInfoInteger(MQL_DLLS_ALLOWED) == 0) {
        Alert("DLL calling not allowed. Allow and try again!");
    }

    m_rows = new CArrayObj();

    if (__db_mysql_global != 0) {
        this.db = __db_mysql_global;
    }

    is64 = TerminalInfoInteger(TERMINAL_X64);
}

/**
 * Destructor implementation for CMysql class.
 */
CMysql::~CMysql() {

    this.clear();
    delete m_rows;

}

/**
 * Connects to the MySQL database.
 * @param hostname MySQL server hostname.
 * @param username MySQL username.
 * @param password MySQL password.
 * @param database MySQL database name.
 * @param table MySQL table name.
 */
void CMysql::connect(string xhostname, string xusername, string xpassword, string xdatabase, string xtable) {

    if (__db_mysql_global == 0) {
        db = mysql_init(0);
    
       int port=3306;
        string xhost = UNICODE2ANSI(xhostname);
        string user = UNICODE2ANSI(xusername);
        string pass = UNICODE2ANSI(xpassword);
        string DB = UNICODE2ANSI(xdatabase);
        string table = UNICODE2ANSI(xtable);
    
        if (mysql_real_connect(db, xhost, user, pass, DB, port, 0, 0) == 0) {
            error("DB CONNECTION ERROR");
            return;
        }
    
        this.hostname = xhostname;
        this.username = xusername;
        this.password = xpassword;
        this.database = xdatabase;
        this.tablename = xtable;
    }

}
// Additional functions specific to MysqlDB
bool CMysql::isConnected() {
    if (db != 0) {
        return true;
    } else {
        return false;
    }
}

void CMysql::error(string query) {
    string s = mysql_error(db);
            Comment(                         "DB Error: "+  UNICODE2ANSI(query));
    //Alert("SQL Input: ", sqlin);
   
      Print("Error: ",  UNICODE2ANSI(query));
    
}

string CMysql::get(string strKey, int iValue) {

    if (m_rows.Total() >= iValue + 1) {
        CMysqlRow* pRow = m_rows.At(iValue);
        CArrayObj* pFields = pRow.fields;

        for (int i = 0; i < pFields.Total(); i++) {
            CMysqlField* pField = pFields.At(i);
            if (pField.key == strKey) {
                return pField.value;
            }
        }
    }

    return "";
}

void CMysql::clear() {

    for (int i = 0; i < m_rows.Total(); i++) {
        CMysqlRow* pRow = m_rows.At(i);
        delete pRow;
    }
    m_rows.Clear();

}

void CMysql::AddNew(string strTable) {
    this.clear();
    this.tablename = strTable;
}

string CMysql::implode(string parm, CArrayString* pString) {

    string ret = "";
    int iTotal = pString.Total();
    for (int i = 0; i < pString.Total(); i++) {
        ret = ret + parm + escape(pString.At(i)) + parm;
        if (i < (iTotal - 1)) {
            ret = ret + ", ";
        }
    }
    return ret;
}

void CMysql::set(string strKey, string strValue) {

    CMysqlRow* pRow;
    if (m_rows.Total() == 0) {
        pRow = new CMysqlRow();
        m_rows.Add(pRow);
    }

    pRow = m_rows.At(0);
    pRow.changed = 1;

    CArrayObj* pFields = pRow.fields;
    for (int i = 0; i < pFields.Total(); i++) {
        CMysqlField* pField = pFields.At(i);
        if (pField.key == strKey) {
            pField.value = strValue;
            pField.modified = 1;
            return;
        }
    }

    CMysqlField* xpField = new CMysqlField();
    xpField.key = strKey;
    xpField.value = strValue;
    xpField.modified = 2;

    pRow.fields.Add(xpField);

    return;

}

void CMysql::select(string xtablename) {
    this.tablename = xtablename;
}
string CMysql::escape(string strInput) {
    StringReplace(strInput, "'", "\\'");  // Escape single quotes
    return strInput;
}



string CMysql::UNICODE2ANSI(string str) {
    int len = StringLen(str);
    uchar byteArr[];
    ArrayResize(byteArr, len * 2 + 1);
     StringToCharArray(str,byteArr,WHOLE_ARRAY,CP_ACP);
    return CharArrayToString(byteArr);
}

 string CMysql:: ANSI2UNICODE(string str) {
    int len = StringLen(str);
    uchar wcharArr[];
    ArrayResize(wcharArr, len + 1,0);
  
    return CharArrayToString(wcharArr,0,WHOLE_ARRAY,CP_ACP);
}

// Additional functions specific to MysqlDB
void CMysql::write(string query) {
    mysql_real_query(db, UNICODE2ANSI(query), StringLen(query));
    if (mysql_errno(db)) {
        error("MySQL error: " + mysql_error(db));
    }
}