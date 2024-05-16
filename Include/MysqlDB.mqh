//+------------------------------------------------------------------+
//|                                                      MysqlDB.mqh |
//|                                     Copyright 2023, sopotek ,inc |
//|                   https://www.github.com/nguemechieu/tradeexpert |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, sopotek ,inc"
#property link      "https://www.github.com/nguemechieu/tradeexpert"
#property strict
#include <Mysql.mqh>
class MysqlDB : public CMysql {
public:
    MysqlDB() : CMysql() {}
    ~MysqlDB() {}
    
    

    // Additional functions specific to MysqlDB
    void createDatabase(string dbName) {
        string query = "CREATE DATABASE IF NOT EXISTS " + dbName;
        mysql_real_query(db, UNICODE2ANSI(query), StringLen(query));
        if (mysql_errno(db)) {
            error(query);
        }
    }

    void dropDatabase(string dbName) {
        string query = "DROP DATABASE IF EXISTS " + dbName;
        mysql_real_query(db, UNICODE2ANSI(query), StringLen(query));
        if (mysql_errno(db)) {
           error(query);
           
        }
    }

    void showDatabases() {
        string query = "SHOW DATABASES";
        mysql_real_query(db, UNICODE2ANSI(query), StringLen(query));
        if (mysql_errno(db)) {
            error(query);
        }
        int result = mysql_store_result(db);
        if (result > 0) {
            int num_rows = mysql_num_rows(result);
            for (int i = 0; i < num_rows; i++) {
              
               int  row_ptrx= mysql_fetch_row(result);
               
               uchar results[];
                printf("Resut :"+ANSI2UNICODE(CharArrayToString(results,WHOLE_ARRAY,CP_ACP)));
            }
            mysql_free_result(result);
        }
    }

    void createTable(string tableName, string columns) {
        string query = "CREATE TABLE IF NOT EXISTS " + tableName + " (" + columns + ")";
        mysql_real_query(db, UNICODE2ANSI(query), StringLen(query));
        if (mysql_errno(db)) {
           error(query);
        }
    }

    void dropTable(string tableName) {
        string query = "DROP TABLE IF EXISTS " + tableName;
        mysql_real_query(db, UNICODE2ANSI(query), StringLen(query));
        if (mysql_errno(db)) {
            error(query);
        }
    }
    
    
   // Additional functions specific to MysqlDB
void insert(string tableName, string columns, string values) {
    string query = "INSERT INTO " + tableName + " (" + columns + ") VALUES (" + values + ")";
    mysql_real_query(db, UNICODE2ANSI(query), StringLen(query));
    if (mysql_errno(db)) {
        error("MySQL error: " + mysql_error(db));
    }
}

};