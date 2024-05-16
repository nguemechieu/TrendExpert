
   #define CAPTION_COLOR   clrYellow
   #define LOSS_COLOR      clrOrangeRed
   #include <stdlib.mqh>
   #include <stderror.mqh>
   #include <DiscordTelegram\Comment.mqh>
   #include <DiscordTelegram\Telegram.mqh>

 #include <DiscordTelegram\Discord.mqh>
 
 string discord_url="";
 input string discord_token="";
Discord dicord(discord_url);
  
#include <Arrays\ArrayObj.mqh>


struct MyNews
{
   string date;
   string title;
   string country;
   string impact;
   double forecast;
   double previous;
   int minutes;int hour;int secondes;
};

MyNews mynews[]; // Define your MyNews array
MyNews read_news_saved[123444];


// Define a struct to hold news data
struct NewsData
{
    datetime date;
    string title;
    string impact;
    string country;
    double forecast;
    double previous;
};


enum Answer {yes, no};


enum DYS_WEEK
  {
   Sunday = 0,
   Monday = 1,
   Tuesday = 2,
   Wednesday,
   Thursday = 4,
   Friday = 5,
   Saturday
  };

enum TIME_LOCK
  {
   closeall,//CLOSE_ALL_TRADES
   closeprofit,//CLOSE_ALL_PROFIT_TRADES
   breakevenprofit//MOVE_PROFIT_TRADES_TO_BREAKEVEN
  };






struct NewsEventData
{
    datetime date;
    string title;
    int impact;
    double previous;
    double forecast; string country; int minutes; int hour; int secondes;
};

   const ENUM_TIMEFRAMES _periods[] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_M30,PERIOD_H1,PERIOD_H4,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
input ENUM_LANGUAGES InpLanguage;

string symbols[];

  
   enum EXECUTION_MODE{MARKET_ORDERS,LIMIT_ORDERS,STOPLOSS_ORDERS};
     

 //+------------------------------------------------------------------+
   //|   CMyBot                                                         |
   //+------------------------------------------------------------------+
   class CMyBot: public CCustomBot
   {
   private:
      ENUM_LANGUAGES    m_lang;
      string            m_symbol;
      ENUM_TIMEFRAMES   m_period;
      string            m_template;
      CArrayString      m_templates;
   
   public:
      //+------------------------------------------------------------------+
      void              Language(const ENUM_LANGUAGES _lang)
      {
         m_lang=_lang;
      }
   
      //+------------------------------------------------------------------+
         void myAlert(string sym,string type, string message)
     {
      if(type == "print")
         Print(message);
      else if(type == "error")
        {
         Print(type+" | @  "+sym+","+IntegerToString(Period())+" | "+message);
         SendMessage(channel,type+" | @  "+sym+","+IntegerToString(Period())+" | "+message);
        }
      else if(type == "order")
        {
        }
      else if(type == "modify")
        {
        }
     }
   
   int myOrderSend(string sym,int type, double price, double volume, string ordername ) //send order, return ticket ("price" is irrelevant for market orders)
     {
     
     
      if(!IsTradeAllowed()) return(-1);
      int ticket = -1;
      int retries = 0;
      int err = 0;
      int long_trades = TradesCount(OP_BUY);
      int short_trades = TradesCount(OP_SELL);
      int long_pending = TradesCount(OP_BUYLIMIT) + TradesCount(OP_BUYSTOP);
      int short_pending = TradesCount(OP_SELLLIMIT) + TradesCount(OP_SELLSTOP);
      string ordername_ = ordername;
      if(ordername != "")
         ordername_ = "("+ordername+")";
      //test Hedging
      if(!Hedging && ((type % 2 == 0 && short_trades + short_pending > 0) || (type % 2 == 1 && long_trades + long_pending > 0)))
        {
         myAlert(sym,"print", "Order"+ordername_+" not sent, hedging not allowed");
         
         SendMessage(channel,"Order"+ordername_+ "not sent, hedging not allowed");
         return(-1);
        }
      //test maximum trades
      if((type % 2 == 0 && long_trades >= MaxLongTrades)
      || (type % 2 == 1 && short_trades >= MaxShortTrades)
      || (long_trades + short_trades >= MaxOpenTrades)
      || (type > 1 && type % 2 == 0 && long_pending >= MaxLongPendingOrders)
      || (type > 1 && type % 2 == 1 && short_pending >= MaxShortPendingOrders)
      || (type > 1 && long_pending + short_pending >= MaxPendingOrders)
      )
        {
         myAlert(sym,"print", "Order"+ordername_+" not sent, maximum reached");
        SendMessage(ChatID, "Order"+ordername_+" not sent, maximum reached");
         return(-1);
        }
       double SL=0;
      //prepare to send order
      while(IsTradeContextBusy()) Sleep(100);
      
     
      
      RefreshRates();
      if(type == OP_BUY || type==OP_BUYLIMIT || type==OP_BUYSTOP)
       {  price = MarketInfo(sym,MODE_ASK);
        SL= price -stoploss*MarketInfo(sym,MODE_POINT);
            
         TP= price +takeprofit*MarketInfo(sym,MODE_POINT);
         
        } 
      else if(type == OP_SELL || type==OP_SELLLIMIT || type==OP_SELLSTOP)
         {price =  price = MarketInfo(sym,MODE_BID);
         
         SL= price +stoploss*MarketInfo(sym,MODE_POINT);
            
         TP= price -takeprofit*MarketInfo(sym,MODE_POINT);
         
         
         }
      else if(price < 0) //invalid price for pending order
        {
        // myAlert(sym,"order", "Order"+ordername_+" not sent, invalid price for pending order");
         SendMessage(channel,"Order"+ordername_+" not sent, invalid price for pending order");
   	  return(-1);
        }
      int clr = (type % 2 == 1) ? clrWhite : clrGold;
      while(ticket < 0 && retries < OrderRetry)
        {
        LotDigits=(int)MarketInfo(sym,MODE_LOTSIZE);
        
         ticket = OrderSend(sym, type,
          NormalizeDouble(volume, LotDigits),
          NormalizeDouble(price,  (int)MarketInfo(sym,MODE_DIGITS))
           ,
           
          0, 
          SL, TP,
           ordername, 
           2234,
            0, clr);
         if(ticket < 0)
           {
            err = GetLastError();
            myAlert(sym,"print", "OrderSend"+ordername_+" error #"+IntegerToString(err)+" "+ErrorDescription(err));
           bot. SendMessage(channel, "OrderSend"+ordername_+" failed "+IntegerToString(OrderRetry+1)+" times; error #"+IntegerToString(err)+" "+ErrorDescription(err));
   
                Sleep(OrderWait*1000);
           }
           
//       
//       if(ticket < 0)
//        {
//           myAlert(sym,"error", "OrderSend"+ordername_+" failed "+IntegerToString(OrderRetry+1)+" times; error #"+IntegerToString(err)+" "+ErrorDescription(err));
//           SendMessage(channel, "OrderSend"+ordername_+" failed "+IntegerToString(OrderRetry+1)+" times; error #"+IntegerToString(err)+" "+ErrorDescription(err));
//   
//         return(-1);
//        }
      string typestr[6] = {"Buy", "Sell", "Buy Limit", "Sell Limit", "Buy Stop", "Sell Stop"};
    
          myAlert(sym,"order", "Order sent"+ordername_+": "+typestr[type]+" "+sym+" Magic #"+IntegerToString(MagicNumber));
         bot.SendMessage(channel,"Order sent"+ordername_+": "+typestr[type]+sym+" "+ (string)MagicNumber+" "+IntegerToString(MagicNumber));

         retries++;
        }
        return ticket;
     
   }
      int               Templates(const string _list)
      {
         m_templates.Clear();
         //--- parsing
         string text=StringTrim(_list);
         if(text=="")
            return(0);
   
         //---
         while(StringReplace(text,"  "," ")>0);
         StringReplace(text,";"," ");
         StringReplace(text,","," ");
   
         //---
         string array[];
         int amount=StringSplit(text,' ',array);
         amount=fmin(amount,5);
   
         for(int i=0; i<amount; i++)
         {
            array[i]=StringTrim(array[i]);
            if(array[i]!="")
               m_templates.Add(array[i]);
         }
   
         return(amount);
      }
   
      //+------------------------------------------------------------------+
      int               SendScreenShot(const long _chat_id,
                                       const string _symbol,
                                       const ENUM_TIMEFRAMES _period,
                                       const string _template=NULL)
      {
         int result=0;
   
         long chart_id=ChartOpen(_symbol,_period);
         if(chart_id==0)
            return(ERR_CHART_NOT_FOUND);
   
         ChartSetInteger(ChartID(),CHART_BRING_TO_TOP,true);
   
         //--- updates chart
         int wait=60;
         while(--wait>0)
         {
            if(SeriesInfoInteger(_symbol,_period,SERIES_SYNCHRONIZED))
               break;
            Sleep(500);
         }
   
         if(_template!=NULL)
            if(!ChartApplyTemplate(chart_id,_template))
               PrintError(_LastError,InpLanguage);
   
         ChartRedraw(chart_id);
         Sleep(500);
   
         ChartSetInteger(chart_id,CHART_SHOW_GRID,false);
   
         ChartSetInteger(chart_id,CHART_SHOW_PERIOD_SEP,false);
   
         string filename=StringFormat("%s%d.gif",_symbol,_period);
   
         if(FileIsExist(filename))
            FileDelete(filename);
         ChartRedraw(chart_id);
   
         Sleep(100);
   
         if(ChartScreenShot(chart_id,filename,800,600,ALIGN_RIGHT))
         {
            
            Sleep(100);
            
            //--- Need for MT4 on weekends !!!
            ChartRedraw(chart_id);
            
            SendChatAction(_chat_id,ACTION_UPLOAD_PHOTO);
   
            //--- waitng 30 sec for save screenshot
            wait=60;
            while(!FileIsExist(filename) && --wait>0)
               Sleep(500);
   
            //---
            if(FileIsExist(filename))
            {
               string screen_id;
               result=SendPhoto(screen_id,_chat_id,filename,_symbol+"_"+StringSubstr(EnumToString(_period),7));
            }
            else
            {
               string mask=m_lang==LANGUAGE_EN?"Screenshot file '%s' not created.":"Файл скриншота '%s' не создан.";
               PrintFormat(mask,filename);
            }
         }
   
         ChartClose(chart_id);
         return(result);
      }
   
   
   
   
   
   
   
   
     //+------------------------------------------------------------------+
      void              ProcessMessages(void)
      {
   
   #define EMOJI_TOP    "\xF51D"
   #define EMOJI_BACK   "\xF519"
   #define KEYB_MAIN    (m_lang==LANGUAGE_EN)?"[[\"Account Info\"],[\"Quotes\"],[\"Charts\"],[\"trade\"],[\"analysis\"],[\"report\"]]":"[[\"??????????\"],[\"?????????\"],[\"???????\"]]"
   #define KEYB_SYMBOLS "[[\""+EMOJI_TOP+"\",\"GBPUSD\",\"EURUSD\"],[\"AUDUSD\",\"USDJPY\",\"EURJPY\"],[\"USDCAD\",\"USDCHF\",\"EURCHF\"],[\"EURCAD\"],[\"USDCHF\"],[\"USDDKK\"],[\"USDJPY\"],[\"AUDCAD\"]]"
   #define KEYB_PERIODS "[[\""+EMOJI_TOP+"\",\"M1\",\"M5\",\"M15\"],[\""+EMOJI_BACK+"\",\"M30\",\"H1\",\"H4\"],[\" \",\"D1\",\"W1\",\"MN1\"]]"
   #define  TRADE_SYMBOLS "[[\""+EMOJI_TOP+"\",\"BUY\",\"SELL\",\"BUYLIMIT\"],[\""+EMOJI_BACK+"\",\"SELLLIMIT\",\"BUYSTOP\",\"SELLSTOP\"]]"
         for(int i=0; i<m_chats.Total(); i++)
      
         {
            CCustomChat *chat=m_chats.GetNodeAtIndex(i);
            if(!chat.m_new_one.done)
            {
               chat.m_new_one.done=true;
               string text=chat.m_new_one.message_text;
   
               //--- start
               if(StringFind(text,"start")>=0 || StringFind(text,"help")>=0)
               {
                  chat.m_state=0;
                  string msg="The bot works with your trading account:\n";
                  msg+="/info - get account information\n";
                  msg+="/quotes - get quotes\n";
                  msg+="/charts - get chart images\n";
                  msg+="/trade- start live  trade"; 
                 
                  msg+="/account -- get account infos ";
                  msg+="/analysis  -- get market analysis";
   
                  if(m_lang==LANGUAGE_RU)
                  {
                     msg="??? ???????? ? ????? ???????? ??????:\n";
                     msg+="/info - ????????? ?????????? ?? ?????\n";
                     msg+="/quotes - ????????? ?????????\n";
                     msg+="/charts - ????????? ??????\n";
                     msg+="/trade"; 
                    
                     msg+="/analysis";
                  }
   
                  SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_MAIN,false,false));
                  continue;
               }
   
               //---
               if(text==EMOJI_TOP)
               {
                  chat.m_state=0;
                  string msg=(m_lang==LANGUAGE_EN)?"Choose a menu item":"???????? ????? ????";
                  SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_MAIN,false,false));
                  continue;
               }
   
               //---
               if(text==EMOJI_BACK)
               {
                  if(chat.m_state==31)
                  {
                     chat.m_state=3;
                     string msg=(m_lang==LANGUAGE_EN)?"Enter a symbol name like 'EURUSD'":"??????? ???????? ???????????, ???????? 'EURUSD'";
                     SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
                  }
                  else if(chat.m_state==32)
                  {
                     chat.m_state=31;
                     string msg=(m_lang==LANGUAGE_EN)?"Select a timeframe like 'H1'":"??????? ?????? ???????, ???????? 'H1'";
                     SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_PERIODS,false,false));
                  }
                  else
                  {
                     chat.m_state=0;
                     string msg=(m_lang==LANGUAGE_EN)?"Choose a menu item":"???????? ????? ????";
                     SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_MAIN,false,false));
                  }
                  continue;
               }
   
               //---
               if(text=="/info" || text=="Account Info" || text=="??????????")
               {
                  chat.m_state=1;
                  string currency=AccountInfoString(ACCOUNT_CURRENCY);
                  string msg=StringFormat("%d: %s\n",AccountInfoInteger(ACCOUNT_LOGIN),AccountInfoString(ACCOUNT_SERVER));
                  msg+=AccountInfos();
                  msg+=StringFormat("%s: %.2f %s\n",(m_lang==LANGUAGE_EN)?"Profit":"???????",AccountInfoDouble(ACCOUNT_PROFIT),currency);
                  SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_MAIN,false,false));
                  continue;
               }
   
               //---
               if(text=="/quotes" || text=="Quotes" || text=="?????????")
               {
                  chat.m_state=2;
                  string msg=(m_lang==LANGUAGE_EN)?"Enter a symbol name like 'EURUSD'":"??????? ???????? ???????????, ???????? 'EURUSD'";
                  SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
                  continue;
               }
   
               //---
               if(text=="/charts" || text=="Charts" || text=="chart"|| text=="???????")
               {
                  chat.m_state=3;
                  string msg=(m_lang==LANGUAGE_EN)?"Enter a symbol name like 'EURUSD'":"??????? ???????? ???????????, ???????? 'EURUSD'";
                  SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
                  continue;
               }
               //Trade 
               
               
               
               if(text== "/trade" || text=="trade"){
               
               string msg="=======TRADE MODE====== \nSelect symbol!";
                SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
               chat.m_state =4;
              
              }
              if(text=="/analysis"|| text=="analysis"){
              
                string msg="=========== Market Analysis ==========";
               SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(TRADE_SYMBOLS,false,false));
               chat.m_state=7;
              
              }
             if(text=="/report"||text=="report"){
               string msg="========Trade Report ======";
               msg=StringFormat("Date %s\nBalance %s\nEquity %s\nProfit %s\nDaily Losses %s\nExpected Return :%s\n Weekly Report%s\n",
               TimeToStr(TimeCurrent()), DoubleToStr(AccountBalance()),
               DoubleToStr(AccountEquity()), DoubleToStr(-AccountBalance()+AccountEquity()),
              DoubleToStr( 1),DoubleToStr((AccountEquity()/AccountBalance())*100),
              
              ((SymbolName(i,false)==text)? text:Symbol()) +(string)(0)+ " pips"
               
               );
              
                SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_MAIN,false,false));
              
                chat.m_state=6;
              }
     


              
   int ticket=0;
   string symbol="";
        //CREATE ORDERS
        
              ObjectCreate(ChartID(),"symb", OBJ_LABEL,0,Time[0],MarketInfo(      Symbol(),MODE_ASK));
              
        //SEARCHING  SYMBOL TO CREATE ORDER
        int j=0;int immediateExecution = ImmediateExecution;
        while(j<SymbolsTotal(false)){
                 StringToUpper(text);
               switch (immediateExecution) {
    case MARKET_ORDERS:
        if (StringFind(text, SymbolName(j, false), 0) >= 0) {
            string symb = SymbolName(j, false);
            ObjectSetInteger(ChartID(), "symb", OBJPROP_YDISTANCE, 200);
            ObjectSetInteger(ChartID(), "symb", OBJPROP_XDISTANCE, 1);
            ObjectSetText("symb", "Telegram Symbol: " + symb, 13, NULL, clrYellow);

            if (StringFind(text, "SELL", 0) >= 0) {
                ticket = myOrderSend(symb, OP_SELL, MarketInfo(symb, MODE_BID), Lots, "MARKET SELL ORDER");
                if (ticket < 0) SendMessage(chat.m_id, " ERROR " + GetErrorDescription(GetLastError(), 0));
            } else if (StringFind(text, "BUY", 0) >= 0) {
                ticket = myOrderSend(symb, OP_BUY, MarketInfo(symb, MODE_ASK), Lots, "MARKET BUY ORDER");
                if (ticket < 0) SendMessage(chat.m_id, " ERROR " + GetErrorDescription(GetLastError(), 0));
            }
        }
        break;

    case LIMIT_ORDERS:
        if (StringFind(text, SymbolName(j, false), 0) >= 0) {
            string symb = SymbolName(j, false);
            ObjectSetInteger(ChartID(), "symb", OBJPROP_YDISTANCE, 200);
            ObjectSetInteger(ChartID(), "symb", OBJPROP_XDISTANCE, 1);
            ObjectSetText("symb", "Telegram Symbol: " + symb, 13, NULL, clrYellow);

            if (StringFind(text, "BUY", 0) >= 0) {
                ticket = myOrderSend(symb, OP_BUYLIMIT, MarketInfo(symb, MODE_ASK), Lots, "BUY LIMIT ORDER");
                if (ticket < 0) SendMessage(chat.m_id, " ERROR " + GetErrorDescription(GetLastError(), 0));
            } else if (StringFind(text, "SELL", 0) >= 0) {
                ticket = myOrderSend(symb, OP_SELLLIMIT, MarketInfo(symb, MODE_BID), Lots, "SELL Limit ORDER");
                if (ticket < 0) SendMessage(chat.m_id, " ERROR " + GetErrorDescription(GetLastError(), 0));
            }
        }
        break;

    case STOPLOSS_ORDERS:
        if (StringFind(text, SymbolName(j, false), 0) >= 0) {
            string symb = SymbolName(j, false);
            ObjectSetInteger(ChartID(), "symb", OBJPROP_YDISTANCE, 200);
            ObjectSetInteger(ChartID(), "symb", OBJPROP_XDISTANCE, 1);
            ObjectSetText("symb", "Telegram Symbol: " + symb, 13, NULL, clrYellow);

            if (StringFind(text, "BUY", 0) >= 0) {
                ticket = myOrderSend(symb, OP_BUYSTOP, MarketInfo(symb, MODE_ASK), Lots, "BUY STOPLOSS ORDER");
                if (ticket < 0) SendMessage(chat.m_id, " ERROR " + GetErrorDescription(GetLastError(), 0));
            } else if (StringFind(text, "SELL", 0) >= 0) {
                ticket = myOrderSend(symb, OP_SELLSTOP, MarketInfo(symb, MODE_BID), Lots, "SELL STOPLOSS ORDER");
                if (ticket < 0) SendMessage(chat.m_id, " ERROR " + GetErrorDescription(GetLastError(), 0));
            }
        }
        break;

    default:printf("NO ORDER SEND YET");
        // Handle default case if ImmediateExecution doesn't match any known value
        break;
}
                  j++;
                  
                 }
    
               //--- Quotes
               if(chat.m_state==2)
               {
                  string mask=(m_lang==LANGUAGE_EN)?"  Invalid symbol name '%s'":"?????????? '%s' ?? ??????";
                  string msg=StringFormat(mask,text);
                  StringToUpper(text);
                  symbol=text;
                  if(SymbolSelect(symbol,true))
                  {
                     double open[1]= {0};
   
                     m_symbol=symbol;
                     //--- upload history
                     for(int k=0; k<3; k++)
                     {
   #ifdef __MQL4__
                        double array[][6];
                        ArrayCopyRates(array,symbol,PERIOD_D1);
   #endif
   
                        Sleep(2000);
                        CopyOpen(symbol,PERIOD_D1,0,1,open);
                        if(open[0]>0.0)
                           break;
                     }
   
                     int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
                     double bid=SymbolInfoDouble(symbol,SYMBOL_BID);
   
                     CopyOpen(symbol,PERIOD_D1,0,1,open);
                     if(open[0]>0.0)
                     {
                        double percent=100*(bid-open[0])/open[0];
                        //--- sign
                        string sign=ShortToString(0x25B2);
                        if(percent<0.0)
                           sign=ShortToString(0x25BC);
   
                        msg=StringFormat("%s: %s %s (%s%%)",symbol,DoubleToString(bid,digits),sign,DoubleToString(percent,2));
                     }
                     else
                     {
                        msg=(m_lang==LANGUAGE_EN)?"No history for ":"??? ??????? ??? "+symbol;
                     }
                  }
   
                  SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
                  continue;
               }
     ArrayResize(symbols,SymbolsTotal(false),0);
               //--- Charts
               if(chat.m_state==3)
               {
   
                  StringToUpper(text);
                  symbol=text;
                  if(SymbolSelect(symbol,true))
                  {
                     m_symbol=symbol;
   
                     chat.m_state=31;
                     string msg=(m_lang==LANGUAGE_EN)?"Select a timeframe like 'H1'":"??????? ?????? ???????, ???????? 'H1'";
                     SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_PERIODS,false,false));
                  }
                  else
                  {
                     string mask=(m_lang==LANGUAGE_EN)?"Invalid symbol name '%s'":"?????????? '%s' ?? ??????";
                     string msg=StringFormat(mask,text);
                     SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
                  }
                  continue;
               }
   
   
   
    if(i<SymbolsTotal(false)){
               
               
               
                for (j =0;j<SymbolsTotal(false);j++){
                  if(StringFind(text,SymbolName(j,false),0)>=0){
                  
                symbols[0]=SymbolName(j,false);
                          Comment(symbols[0]);
                break; 
                }
          
                }
             
             }
   
   
   
   
                printf("sym[0] :"+symbols[0]);
                if(StringFind(text,"BUY",0)>=0 )
                  {
                
               myOrderSend(symbols[0],OP_BUY,MarketInfo(symbols[0],MODE_ASK),Lots,"MARKET BUY  ORDER");
               
              
              }else
              
               if(StringFind(text,"SELL",0)>=0 ){
                    
               myOrderSend(symbols[0],OP_SELL,MarketInfo(symbols[0],MODE_BID),Lots,"MARKET SELL ORDER");
               
              
                 }
                 
                  // CREATE LIMIT ORDERS 
                    
              if(StringFind(text,"BUYLIMIT",0)>=0 ){                        
                  ticket =myOrderSend(symbols[0],OP_BUYLIMIT,MarketInfo(symbols[0],MODE_ASK),Lots,"BUY LIMIT ORDER");
              
              }
              else 
     
              if( StringFind(text,"SELLLIMIT",0)>=0 ){
                    
                ticket =myOrderSend(symbols[0],OP_SELLLIMIT,MarketInfo(symbols[0],MODE_BID),Lots,"SELL Limit ORDER");
                
              
              }  
      
             // CREATE STOPLOSS ORDER 
              if(StringFind(text,"BUYSTOP",0)>=0 ){                              
               ticket =myOrderSend(symbols[0],OP_BUYSTOP,MarketInfo(symbols[0],MODE_ASK),Lots,"BUY STOPLOSS ORDER");

              }else
              
               if(StringFind(text,"SELLSTOP",0)>=0 ){
                 ticket =myOrderSend(symbols[0],OP_SELLSTOP,MarketInfo(symbols[0],MODE_BID),Lots,"SELL STOPLOSS ORDER");
                      }
   
   
           
        if(chat.m_state ==4){
                
             if(i<SymbolsTotal(false)){
          
                for (j =0;j<SymbolsTotal(false);j++){
                  if(StringFind(text,SymbolName(j,false),0)>=0){
                  
                symbols[0]=SymbolName(j,false);
                      SendMessage(chat.m_id,"Click buttons to trade",ReplyKeyboardMarkup(TRADE_SYMBOLS,false,false));
                    chat.m_state=5;
                    Comment(symbols[0]);
                break;  }
          
                }
             
             }
         }
          
          
             
          while(chat.m_state==5){//trade state
          
   
                printf("sym[0] :"+symbols[0]);
                if(StringFind(text,"BUY",0)>=0 )
                  {
                
               myOrderSend(symbols[0],OP_BUY,MarketInfo(symbols[0],MODE_ASK),Lots,"MARKET BUY  ORDER");
               
              
              }else
              
               if(StringFind(text,"SELL",0)>=0 ){
                    
               myOrderSend(symbols[0],OP_SELL,MarketInfo(symbols[0],MODE_BID),Lots,"MARKET SELL ORDER");
               
              
                 }
                 
                  // CREATE LIMIT ORDERS 
                    
              if(StringFind(text,"BUYLIMIT",0)>=0 || StringFind(text,"BUY_LIMIT",0)>=0 ){                        
                 myOrderSend(symbols[0],OP_BUYLIMIT,MarketInfo(symbols[0],MODE_ASK),Lots,"BUY LIMIT ORDER");
              
              }
              else 
     
              if( StringFind(text,"SELLLIMIT",0)>=0||StringFind(text,"SELL_LIMIT",0)>=0 ){
                    
                ticket =myOrderSend(symbols[0],OP_SELLLIMIT,MarketInfo(symbols[0],MODE_BID),Lots,"SELL Limit ORDER");
                
              
              }  
      
             // CREATE STOPLOSS ORDER 
              if(StringFind(text,"BUYSTOP",0)>=0|| StringFind(text,"BUY_STOP",0)>=0 ){                              
               ticket =myOrderSend(symbols[0],OP_BUYSTOP,MarketInfo(symbols[0],MODE_ASK),Lots,"BUY STOPLOSS ORDER");

              }else
              
               if(StringFind(text,"SELLSTOP",0)>=0||StringFind(text,"SELL_STOP",0)>=0 ){
                 ticket =myOrderSend(symbols[0],OP_SELLSTOP,MarketInfo(symbols[0],MODE_BID),Lots,"SELL STOPLOSS ORDER");
                      }
              break;            
        }
             //Charts->Periods
               if(chat.m_state==31)
               {
                  bool found=false;
                  int total=ArraySize(_periods);
                  for(int k=0; k<total; k++)
                  {
                     string str_tf=StringSubstr(EnumToString(_periods[k]),7);
                     if(StringCompare(str_tf,text,false)==0)
                     {
                        m_period=_periods[k];
                        found=true;
                        break;
                     }
                  }
   
                  if(found)
                  {
                     //--- template
                     chat.m_state=32;
                     string str="[[\""+EMOJI_BACK+"\",\""+EMOJI_TOP+"\"]";
                     str+=",[\"None\"]";
                     for(int k=0; k<m_templates.Total(); k++)
                        str+=",[\""+m_templates.At(k)+"\"]";
                     str+="]";
   
                     SendMessage(chat.m_id,(m_lang==LANGUAGE_EN)?"Select a template":"???????? ??????",ReplyKeyboardMarkup(str,false,false));
                  }
                  else
                  {
                     SendMessage(chat.m_id,(m_lang==LANGUAGE_EN)?"Invalid timeframe":"??????????? ????? ?????? ???????",ReplyKeyboardMarkup(KEYB_PERIODS,false,false));
                  }
                  continue;
               }
               //---
               if(chat.m_state==32)
               {
                  m_template=text;
                  if(m_template=="None")
                     m_template=NULL;
                  int result=SendScreenShot(chat.m_id,m_symbol,m_period,m_template);
                  if(result!=0)
                     Print(GetErrorDescription(result,InpLanguage));
               }
            }
         }
      }
   
   
   
   
   
   
   
   
      //+------------------------------------------------------------------+
     };


#include <stdlib.mqh>
#include <stderror.mqh>
#include <DiscordTelegram\Comment.mqh>
#include <DiscordTelegram\Telegram.mqh>

//+------------------------------------------------------------------+

enum MONEY_MANAGEMENT
  {
   RISK_PERCENTAGE,
   POSITION_SIZE,
   MARTINGALE,
   FIXED_SIZE
  }
;








//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Position_Size(string sym) //position sizing
  {
   double MaxLot = MarketInfo(sym, MODE_MAXLOT);
   double MinLot = MarketInfo(sym, MODE_MINLOT);
   double xlots = AccountBalance() / MM_PositionSizing;
   if(xlots > MaxLot)
      xlots = MaxLot;
   if(xlots < MinLot)
      xlots = MinLot;
   return(xlots);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MM_Size(string sym) //martingale / anti-martingale
  {
   double xlots = MM_Martingale_Start;
   double MaxLot = MarketInfo(sym, MODE_MAXLOT);
   double MinLot = MarketInfo(sym, MODE_MINLOT);
   if(SelectLastHistoryTrade(sym))
     {
      double orderprofit = OrderProfit();
      double orderlots = OrderLots();
      double boprofit = BOProfit(OrderTicket());
      if(orderprofit + boprofit > 0 && !MM_Martingale_RestartProfit)
         xlots = orderlots * MM_Martingale_ProfitFactor;
      else
         if(orderprofit + boprofit < 0 && !MM_Martingale_RestartLoss)
            xlots = orderlots * MM_Martingale_LossFactor;
         else
            if(orderprofit + boprofit == 0)
               xlots = orderlots;
     }
   if(ConsecutivePL(false,sym))
      xlots = MM_Martingale_Start;
   if(ConsecutivePL(true, sym))
      xlots = MM_Martingale_Start;
   if(xlots > MaxLot)
      xlots = MaxLot;
   if(xlots < MinLot)
      xlots = MinLot;
      for(int k=0;k<OrdersTotal();k++)
      if(OrderSelect(k,SELECT_BY_POS,MODE_TRADES)&&OrderLots()==xlots)xlots=OrderLots()+xlots;
      
   return(xlots);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SelectLastHistoryTrade(string sym)
  {
   int lastOrder = -1;
   int total = OrdersHistoryTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;
      if(OrderSymbol() == sym && OrderMagicNumber() == MagicNumber)
        {
         lastOrder = i;
         break;
        }
     }
   return(lastOrder >= 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BOProfit(int ticket) //Binary Options profit
  {
   int total = OrdersHistoryTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;
      if(StringSubstr(OrderComment(), 0, 2) == "BO" && StringFind(OrderComment(), "#" + IntegerToString(ticket) + " ") >= 0)
         return OrderProfit();
     }
   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ConsecutivePL(bool profits, string symbol)
  {
   int count = 0;
   int total = OrdersHistoryTotal();
  int n=0;
   for(int i = total - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;
      if(OrderSymbol() == symbol && OrderMagicNumber() == MagicNumber)
        {
         double orderprofit = OrderProfit();
         double boprofit = BOProfit(OrderTicket());
         if((!profits && orderprofit + boprofit >= 0) || (profits && orderprofit + boprofit <= 0))
            break;
         count++;
        }
     else n=count;}
   return(count >n);
  }
  
  

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  GetLotSize(MONEY_MANAGEMENT money){
  
  
        createObject(ChartID()  , OBJ_LABEL,0,100,200,"info3");
  if(AccountBalance()<AccountEquity())
        {
        
        
        ObjectSetText("info13","INSUFFISANT BALANCE TO OPEN THIS ORDER !\n WAITING FOR BETTER CONDITIONS.",12,NULL,clrAquamarine);
         return 0;
        }else



// Check if there's enough money for trading
         if(AccountFreeMargin() > 0 && AccountBalance() > 0)
     {
      // Calculate trade size based on available funds and lot size
      double  tradeSize = MathFloor(AccountFreeMargin() / 1000.0) * lotSize; // Assuming 1000 units per lot
      Print("Lot",tradeSize);
     }
     else
     {
      Print("Not enough money or free margin to place trades.");
       ObjectSetText("info13","Not enough money or free margin to place trades.",12,NULL,clrAquamarine);
   
      return 0;
     }
string sym=Symbol();
   if(money == RISK_PERCENTAGE)
     {
      return MM_Size(sym);
     }
   else
      if(money == MARTINGALE)
        {
         return MM_Size(sym);
        }
      else
         if(money == POSITION_SIZE)
           {
            return Position_Size(sym);
           }
         else
            
               return lotSize;

   
   
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAll()
  {
   int totalOP  = OrdersTotal(), tiket = 0;
   for(int cnt = totalOP - 1 ; cnt >= 0 ; cnt--)
     {
    Os = OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber)
        {
         Oc = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 3, CLR_NONE);
         Sleep(300);
         continue;
        }
      if(OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber)
        {
         Oc = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 3, CLR_NONE);
         Sleep(300);
        }
     }
  }


//+------------------------------------------------------------------+
//|             TradeDays                                                     |
//+------------------------------------------------------------------+
bool TradeDays()
  {
   if(SET_TRADING_DAYS == no)
      return(true);
   bool ret = false;
   int today = DayOfWeek();
   if(EA_START_DAY < EA_STOP_DAY)
     {
      if(today > EA_START_DAY && today < EA_STOP_DAY)
         return(true);
      else
         if(today == EA_START_DAY)
           {
            if(TimeCurrent() >= datetime(StringToTime(EA_START_TIME)))
               return(true);
            else
               return(false);
           }
         else
            if(today == EA_STOP_DAY)
              {
               if(TimeCurrent() < datetime(StringToTime(EA_STOP_TIME)))
                  return(true);
               else
                  return(false);
              }
     }
   else
      if(EA_STOP_DAY < EA_START_DAY)
        {
         if(today > EA_START_DAY || today < EA_STOP_DAY)
            return(true);
         else
            if(today == EA_START_DAY)
              {
               if(TimeCurrent() >= datetime(StringToTime(EA_START_TIME)))
                  return(true);
               else
                  return(false);
              }
            else
               if(today == EA_STOP_DAY)
                 {
                  if(TimeCurrent() < datetime(StringToTime(EA_STOP_TIME)))
                     return(true);
                  else
                     return(false);
                 }
        }
      else
         if(EA_STOP_DAY == EA_START_DAY)
           {
            datetime st = (datetime)StringToTime(EA_START_TIME);
            datetime et = (datetime)StringToTime(EA_STOP_TIME);
            if(et > st)
              {
               if(today != EA_STOP_DAY)
                  return(false);
               else
                  if(TimeCurrent() >= st && TimeCurrent() < et)
                     return(true);
                  else
                     return(false);
              }
            else
              {
               if(today != EA_STOP_DAY)
                  return(true);
               else
                  if(TimeCurrent() >= et && TimeCurrent() < st)
                     return(false);
                  else
                     return(true);
              }
           }
   /*int JamH1[] = { 10, 20, 30, 40 }; // A[2] == 30
    //   if (JamH1[Hour()] == Hour()) Alert("Trade");
    if (Hour() >= StartHour1 && Hour() <= EndHour1 && DayOfWeek() == 1 && MondayTrade )  return (true);
    if (Hour() >= StartHour2 && Hour() <= EndHour2 && DayOfWeek() == 2 && TuesdayTrade )  return (true);
    if (Hour() >= StartHour3 && Hour() <= EndHour3 && DayOfWeek() == 3 && WednesdayTrade )  return (true);
    if (Hour() >= StartHour4 && Hour() <= EndHour4 && DayOfWeek() == 4 && ThursdayTrade )  return (true);
    if (Hour() >= StartHour5 && Hour() <= EndHour5 && DayOfWeek() == 5 && FridayTrade && !ExitFriday)  return (true);
    if (StartHour5 <=StartHourX - LastTradeFriday - 1 && Hour() >= StartHour5 && Hour() <= StartHourX - LastTradeFriday - 1 && DayOfWeek() == 5 && FridayTrade && ExitFriday)  return (true);
    if ( DayOfWeek() == 1 && !MondayTrade )  return (true);
    if ( DayOfWeek() == 2 && !TuesdayTrade )  return (true);
    if ( DayOfWeek() == 3 && !WednesdayTrade )  return (true);
    if ( DayOfWeek() == 4 && !ThursdayTrade )  return (true);
    if ( DayOfWeek() == 5 && !FridayTrade && ExitFridayOk() == 0)  return (true);
    */
   return (ret);
  }

////////////////////////////////////////////////////////////////////////
void timelockaction(void)
  {
   if(TradeDays())
      return;
   double stoplevel = 0, proffit = 0, newsl = 0, price = 0;
   double ask = 0, bid = 0;
   string sy = NULL;
   int sy_digits = 0;
   double sy_points = 0;
   bool ans = false;
   bool next = false;
   int otype = -1;
   int kk = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderMagicNumber() != MagicNumber)
         continue;
      next = false;
      ans = false;
      sy = OrderSymbol();
      ask = SymbolInfoDouble(sy, SYMBOL_ASK);
      bid = SymbolInfoDouble(sy, SYMBOL_BID);
      sy_digits = (int)SymbolInfoInteger(sy, SYMBOL_DIGITS);
      sy_points = SymbolInfoDouble(sy, SYMBOL_POINT);
      stoplevel = MarketInfo(sy, MODE_STOPLEVEL) * sy_points;
      otype = OrderType();
      kk = 0;
      proffit = OrderProfit() + OrderSwap() + OrderCommission();
      newsl = OrderOpenPrice();
      if(proffit <= 0)
         break;
      else
        {
         price = (otype == OP_BUY) ? bid : ask;
         while(otype < 2 && kk < 5 && MathAbs(price - newsl) >= stoplevel && !OrderModify(OrderTicket(), newsl, newsl, OrderTakeProfit(), OrderExpiration()))
           {
            kk++;
            price = (otype == OP_BUY) ? SymbolInfoDouble(sy, SYMBOL_BID) : SymbolInfoDouble(sy, SYMBOL_ASK);
           }
        }
      continue;
     }
  }

//+------------------------------------------------------------------+
//|                     CHART COLOR SET                                             |
//+------------------------------------------------------------------+
bool ChartColorSet()//set chart colors
  {
   ChartSetInteger(ChartID(), CHART_COLOR_ASK, BearCandle);
   ChartSetInteger(ChartID(), CHART_COLOR_BID, clrOrange);
   ChartSetInteger(ChartID(), CHART_COLOR_VOLUME, clrAqua);
   int keyboard = 12;
   ChartSetInteger(ChartID(), CHART_KEYBOARD_CONTROL, keyboard);
   ChartSetInteger(ChartID(), CHART_COLOR_CHART_DOWN, 231);
   ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BEAR, BearCandle);
   ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BULL, BullCandle);
   ChartSetInteger(ChartID(), CHART_COLOR_CHART_DOWN, Bear_Outline);
   ChartSetInteger(ChartID(), CHART_COLOR_CHART_UP, Bull_Outline);
   ChartSetInteger(ChartID(), CHART_SHOW_GRID, 0);
   ChartSetInteger(ChartID(), CHART_SHOW_PERIOD_SEP, false);
   ChartSetInteger(ChartID(), CHART_MODE, 1);
   ChartSetInteger(ChartID(), CHART_SHIFT, 1);
   ChartSetInteger(ChartID(), CHART_SHOW_ASK_LINE, 1);
   ChartSetInteger(ChartID(), CHART_COLOR_BACKGROUND, BackGround);
   ChartSetInteger(ChartID(), CHART_COLOR_FOREGROUND, ForeGround);
   return(true);
  }

input color BearCandle = clrWhite;
input color BullCandle = clrGreen;
input color BackGround = clrBlack;
input color ForeGround = clrAquamarine;
input color Bear_Outline = clrRed;
input color Bull_Outline = clrGreen;
input string license_key = "trial";
bool CheckLicense(string license)
  {
   datetime tim = D'2023.07.01 00:00';
   if(license == "trial")
     {
      int op = FileOpen(license, FILE_WRITE | FILE_CSV);
      if(op < 0)
        {
         printf("Can't open license key folder");
         return false;
        }
      uint write = FileWrite(op, license_key + (string)AccountNumber() + (string)TimeCurrent());
      FileClose(op);
      Comment("\n\n                                                     Trial Mode");
      if(tim > TimeCurrent())
        {
         return true;
        }
      else
        {
         MessageBox("Your trial Mode is Over!Please purchase a new license to get access to a full product.You can also contact support at https://t.me/tradeexpert_infos"
                    , NULL, 1);
         return false;
        }
     }
   else
     {
      return false;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|   TRADE EXPERT parameters                                               |
//+------------------------------------------------------------------+

input string auth;//==========AUTH PARAMS ================
input ENUM_LICENSE_TYPE licenseType = 0;
input string LICENSE_KEY = "3EEEE4";
input string email = "test";
input string password = "12349";

input const string ss15 ;// "============== TELEGRAM BOT SETTINGS ================";


input string channel = "tradeexpert_infos"; // TELEGRAM CHANNEL
input long chatID = -1001648392740; // GROUP or BOT CHAT ID

input Answer telegram = yes;
input bool UseAllSymbol = true;
input bool trade0 = false;//Trade News
bool now = false;

//+------------------------------------------------------------------+
//|                         NEWS                                         |
//+------------------------------------------------------------------+
bool AvoidNews = trade0;

//-------------------------------------------- EXTERNAL VARIABLE ---------------------------------------------
//------------------------------------------------------------------------------------------------------------
extern bool    ReportActive      = true;                // Report for active chart only (override other inputs)
extern bool    IncludeHigh       = true;                 // Include high
extern bool    IncludeMedium     = true;                 // Include medium
extern bool    IncludeLow        = true;                 // Include low
extern bool    IncludeSpeaks     = true;                 // Include speaks
extern bool    IncludeHolidays   = false;                // Include holidays
extern string  FindKeyword       = "FOMC";                   // Find keyword
extern string  IgnoreKeyword     = "";                   // Ignore keyword
extern bool    AllowUpdates      = true;                 // Allow updates
extern int     UpdateHour        = 4;                    // Update every (in hours)
input string   lb_0              = "";                   // ------------------------------------------------------------
input string   lb_1              = "";                   // ------> PANEL SETTINGS
extern bool    ShowPanel         = true;                 // Show panel
extern bool    AllowSubwindow    = false;                // Show Panel in sub window
extern ENUM_BASE_CORNER Corner   = 2;                    // Panel side
extern string  PanelTitle = "Forex Calendar @ Forex Factory"; // Panel title
extern color   TitleColor        = C'46,188,46';         // Title color
extern bool    ShowPanelBG       = true;                 // Show panel backgroud
extern color   Pbgc              = C'25,25,25';          // Panel backgroud color
extern color   LowImpactColor    = C'91,192,222';        // Low impact color
extern color   MediumImpactColor = C'255,185,83';        // Medium impact color
extern color   HighImpactColor   = C'217,83,79';         // High impact color
extern color   HolidayColor      = clrOrchid;            // Holidays color
extern color   RemarksColor      = clrGray;              // Remarks color
extern color   PreviousColor     = C'170,170,170';       // Forecast color
extern color   PositiveColor     = C'46,188,46';         // Positive forecast color
extern color   NegativeColor     = clrTomato;            // Negative forecast color
extern bool    ShowVerticalNews  = true;                 // Show vertical lines
extern int     ChartTimeOffset   = -6;                    // Chart time offset (in hours)
extern int     EventDisplay      = 10;                   // Hide event after (in minutes)
input string   lb_2              = "";                   // ------------------------------------------------------------

input string   lb_4              = "";                   // ------------------------------------------------------------
input string   lb_5              = "";                   // ------> INFO SETTINGS
extern bool    ShowInfo          = true;                 // Show Symbol info ( Strength / Bar Time / Spread )
extern color   InfoColor         = C'255,185,83';        // Info color
extern int     InfoFontSize      = 10;                    // Info font size
input string   lb_6              = "";                   // ------------------------------------------------------------
input string   lb_7              = "";                   // ------> NOTIFICATION
input string   lb_8              = "";                   // *Note: Set (-1) to disable the Alert
extern int     Alert1Minutes     = 30;                   // Minutes before first Alert
extern int     Alert2Minutes     = 30;                   // Minutes before second Alert
extern bool    PopupAlerts       = true;                // Popup Alerts
extern bool    SoundAlerts       = true;                 // Sound Alerts
extern string  AlertSoundFile    = "news.wav";           // Sound file name
extern bool    EmailAlerts       = true;                // Send email
extern bool    NotificationAlerts = false;               // Send push notification


//------------------------------------------------------------------------------------------------------------
//--------------------------------------------- INTERNAL VARIABLE --------------------------------------------
//--- Vars and arrays
string xmlFileName;
string sData;
string Event[200][7];
string eTitle[10], eCountry[10], eImpact[10], eForecast[10], ePrevious[10];
int eMinutes[10];
datetime eTime[10];
int x0, xx1, xx2, xxf, xp;
int Factor = 2;
//--- Alert
bool FirstAlert;
bool SecondAlert;
datetime AlertTime;
//--- Buffers
double MinuteBuffer[];
double ImpactBuffer[];
//--- time
datetime xmlModifed;
int TimeOfDay;
datetime Midnight;
bool IsEvent;



//+------------------------------------------------------------------+
//|   GetCustomInfo                                                  |
//+------------------------------------------------------------------+
void GetCustomInfo(CustomInfo &info,
                   const int _error_code,
                   const ENUM_LANGUAGES _lang)
  {
   switch(_error_code)
     {
#ifdef __MQL5__
      case ERR_FUNCTION_NOT_ALLOWED:
         info.text1 = (_lang == LANGUAGE_EN) ? "The URL does not allowed for WebRequest" : "Этого URL нет в списке для WebRequest.";
         info.text2 = TELEGRAM_BASE_URL;
         break;
#endif
#ifdef __MQL4__
      case ERR_FUNCTION_NOT_CONFIRMED:
         info.text1 = (_lang == LANGUAGE_EN) ? "The URL does not allowed for WebRequest" : "Этого URL нет в списке для WebRequest.";
         info.text2 = TELEGRAM_BASE_URL;
         break;
#endif
      case ERR_TOKEN_ISEMPTY:
         info.text1 = (_lang == LANGUAGE_EN) ? "The 'Token' parameter is empty." : "Параметр 'Token' пуст.";
         info.text2 = (_lang == LANGUAGE_EN) ? "Please fill this parameter." : "Пожалуйста задайте значение для этого параметра.";
         break;
     }
  }


//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit3(const int reason)
  {
// Print(__FUNCTION__, " Terima Kasih - SignalForex.id");
//---
   for(int i = ObjectsTotal(); i >= 0; i--)
     {
      string name = ObjectName(i);
      if(StringFind(name, INAME) == 0)
         ObjectDelete(name);
     }
//--- Kill update timer only if removed
   if(reason == 1)
      EventKillTimer();
//---
  }
//+-----------------------------------------------------------------------------------------------+
//| Subroutine: to ID currency even if broker has added a prefix to the symbol, and is used to    |
//| determine the news to show, based on the users external inputs - by authors (Modified)        |
//+-----------------------------------------------------------------------------------------------+
bool IsCurrency(string symbol)
  {
//---
   for(int jk = 0; jk < SymbolsTotal(false); jk++)
      if(symbol == StringSubstr(SymbolName(jk, false), 0, 3))
         return(true);
   return(false);
//---
  }
//+------------------------------------------------------------------+
//| Converts ff time & date into yyyy.mm.dd hh:mm - by deVries       |
//+------------------------------------------------------------------+
string MakeDateTime(string strDate, string strTime)
  {
//---
   int n1stDash = StringFind(strDate, "-");
   int n2ndDash = StringFind(strDate, "-", n1stDash + 1);
   string strMonth = StringSubstr(strDate, 0, 2);
   string strDay = StringSubstr(strDate, 3, 2);
   string strYear = StringSubstr(strDate, 6, 4);
   int nTimeColonPos = StringFind(strTime, ":");
   string strHour = StringSubstr(strTime, 0, nTimeColonPos);
   string strMinute = StringSubstr(strTime, nTimeColonPos + 1, 2);
   string strAM_PM = StringSubstr(strTime, StringLen(strTime) - 2);
   int nHour24 = StrToInteger(strHour);
   if((strAM_PM == "pm" || strAM_PM == "PM") && nHour24 != 12)
      nHour24 += 12;
   if((strAM_PM == "am" || strAM_PM == "AM") && nHour24 == 12)
      nHour24 = 0;
   string strHourPad = "";
   if(nHour24 < 10)
      strHourPad = "0";
   return(StringConcatenate(strYear, ".", strMonth, ".", strDay, " ", strHourPad, nHour24, ":", strMinute));
//---
  }
//+------------------------------------------------------------------+
//| set impact Color - by authors                                    |
//+------------------------------------------------------------------+
color ImpactToColor(string impact)
  {
//---
   if(impact == "High")
      return (HighImpactColor);
   else
      if(impact == "Medium")
         return (MediumImpactColor);
      else
         if(impact == "Low")
            return (LowImpactColor);
         else
            if(impact == "Holiday")
               return (HolidayColor);
            else
               return (RemarksColor);
//---
  }
//+------------------------------------------------------------------+
//| Impact to number - by authors                                    |
//+------------------------------------------------------------------+
int ImpactToNumber(string impact)
  {
//---
   if(impact == "High")
      return(3);
   else
      if(impact == "Medium")
         return(2);
      else
         if(impact == "Low")
            return(1);
         else
            return(0);
//---
  }
//+------------------------------------------------------------------+
//| Convert day of the week to text                                  |
//+------------------------------------------------------------------+
string DayToStr(datetime time)
  {
   int ThisDay = TimeDayOfWeek(time);
   string day = "";
   switch(ThisDay)
     {
      case 0:
         day = "Sun";
         break;
      case 1:
         day = "Mon";
         break;
      case 2:
         day = "Tue";
         break;
      case 3:
         day = "Wed";
         break;
      case 4:
         day = "Thu";
         break;
      case 5:
         day = "Fri";
         break;
      case 6:
         day = "Sat";
         break;
     }
   return(day);
  }
//+------------------------------------------------------------------+
//| Convert months to text                                           |
//+------------------------------------------------------------------+
string MonthToStr()
  {
   int ThisMonth = Month();
   string month = "";
   switch(ThisMonth)
     {
      case 1:
         month = "Jan";
         break;
      case 2:
         month = "Feb";
         break;
      case 3:
         month = "Mar";
         break;
      case 4:
         month = "Apr";
         break;
      case 5:
         month = "May";
         break;
      case 6:
         month = "Jun";
         break;
      case 7:
         month = "Jul";
         break;
      case 8:
         month = "Aug";
         break;
      case 9:
         month = "Sep";
         break;
      case 10:
         month = "Oct";
         break;
      case 11:
         month = "Nov";
         break;
      case 12:
         month = "Dec";
         break;
     }
   return(month);
  }
  
    string  INAME="signal";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

enum ENUM_UNIT
  {
   InPips,                 // SL in pips
   InDollars               // SL in dollars
  };
/** Now, MarketData and MarketRates flags can change in real time, according with
 *  registered symbols and instruments.
 */

//+------------------------------------------------------------------+
//| Expert check license                                             |
//+------------------------------------------------------------------+
bool CheckLicense()
  {
   Print("Account name: ", AccountName());
   if(StringFind(StringLower(AccountName()), "account name in lowercase!!") < 0)
     {
      Alert("No license active!");
      Comment("No license active!");
      ExpertRemove();
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Expert string to lower                                           |
//+------------------------------------------------------------------+
string StringLower(string str)
  {
   string outstr = "ertyuio";
   string lower  = "abcdefghijklmnopqrstuvwxyz";
   string upper  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   for(int i = 0; i < StringLen(str); i++)
     {
      int t1 = StringFind(upper, StringSubstr(str, i, 1), 0);
      if(t1 >= 0)
        {
         outstr = outstr + StringSubstr(lower, t1, 1);
        }
      else
        {
         outstr = outstr + StringSubstr(str, i, 1);
        }
     }
   int op = FileOpen("licence.txt", 0, ',', CP_ACP);
   if(op > 0)
     {
      printf("File open");
     }
   else
     {
      printf("ERROR WECAN'T OPEN FILE license.txt");
     }
   return(outstr);
  }
  
  
  

extern double BreakEven_Points = 6;
int LotDigits; //initialized in OnInit

double MM_Percent = 1;

double MaxTP = 100;
double MinTP = 75;
extern double CloseAtPL = 50;
bool crossed[4]; //initialized to true, used in function Cross
input int MaxOpenTrades = 3;
input int MaxLongTrades = 3;
input int MaxShortTrades = 3;
int MaxPendingOrders = 500;
int MaxLongPendingOrders = 1000;
int MaxShortPendingOrders = 1000;
input bool Hedging = false;
input int OrderRetry = 1; //# of retries if sending order returns error
input  int OrderWait = 3; //# of seconds to wait if sending order returns error
double myPoint; //initialized in OnInit

double CalculateLotSize(double bal,double riskPercent,double stopLossPips,double price,string sym){
if(stopLossPips==0) stopLossPips=1;

   double MaxLot = MarketInfo(sym, MODE_MAXLOT);
   double MinLot = MarketInfo(sym, MODE_MINLOT);
   double tickvalue = MarketInfo(sym, MODE_TICKVALUE);
   double ticksize = MarketInfo(sym, MODE_TICKSIZE);
   double Xlots = (riskPercent / 100) * stopLossPips / 2;
   if(Xlots > MaxLot)
      Xlots = MaxLot;
   if(Xlots < MinLot)
      Xlots = MinLot;
   return(Xlots);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MM_Size_BO() //Risk % per trade for Binary Options
  {
   double MaxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double MinLot = MarketInfo(Symbol(), MODE_MINLOT);
   double tickvalue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   return(MM_Percent * 1.0 / 100 * AccountBalance());
  }

void CloseTradesAtPL(double PL) //close all trades if total P/L >= profit (positive) or total P/L <= loss (negative)
  {
   double totalPL = TotalOpenProfit(0);
   if((PL > 0 && totalPL >= PL) || (PL < 0 && totalPL <= PL))
     {
      myOrderClose(Symbol(), OP_BUY, 100, "");
      myOrderClose(Symbol(), OP_SELL, 100, "");
     }
  }
  
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TradesCount(int type) //returns # of open trades for order type, current symbol and magic number
  {
   int result = 0;
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
         continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type)
         continue;
      result++;
     }
   return(result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TotalOpenProfit(int direction)
  {
   double result = 0;
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;
      if((direction < 0 && OrderType() == OP_BUY) || (direction > 0 && OrderType() == OP_SELL))
         continue;
      result += OrderProfit();
     }
   return(result);
  }
  
  

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void myOrderClose(string sym, int type, double volumepercent, string ordername) //close open orders for current symbol, magic number and "type" (OP_BUY or OP_SELL)
  {
   if(!IsTradeAllowed())
      return;
   if(type > 1)
     {
      myAlert(sym, "error", "Invalid type in myOrderClose");
      bot.SendMessage(ChatID, "Invalid type in myOrderClose");
      return;
     }
   bool success = false;
   int retries = 0;
   int err = 0;
   string ordername_ = ordername;
   if(ordername != "")
      ordername_ = "(" + ordername + ")";
   int total = OrdersTotal();
   ulong orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy())
         Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != sym || OrderType() != type)
         continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   LotDigits = (int)MarketInfo(sym, MODE_LOTSIZE);
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect((int)orderList[i][1], SELECT_BY_TICKET, MODE_TRADES))
         continue;
      while(IsTradeContextBusy())
         Sleep(100);
      RefreshRates();
      double price = (type == OP_SELL) ? MarketInfo(sym, MODE_ASK) : MarketInfo(sym, MODE_BID);
      double volume = NormalizeDouble(OrderLots() * volumepercent * 1.0 / 100, LotDigits);
      if(NormalizeDouble(volume, (int)MarketInfo(sym, MODE_LOTSIZE)) == 0)
         continue;
      success = false;
      retries = 0;
      while(!success && retries < OrderRetry + 1)
        {
         success = OrderClose(OrderTicket(), volume, NormalizeDouble(price, (int)MarketInfo(sym, MODE_DIGITS)), MaxSlippage, clrWhite);
         if(!success)
           {
            err = GetLastError();
            myAlert(sym, "print", "OrderClose" + ordername_ + " failed; error #" + IntegerToString(err) + " " + ErrorDescription(err));
            bot.SendMessage(ChatID, "OrderClose" + ordername_ + " failed; error #" + IntegerToString(err) + " " + ErrorDescription(err));
            Sleep(OrderWait * 1000);
           }
         retries++;
        }
      if(!success)
        {
         myAlert(sym, "error", "OrderClose" + ordername_ + " failed " + IntegerToString(OrderRetry + 1) + " times; error #" + IntegerToString(err) + " " + ErrorDescription(err));
         bot.SendMessage(ChatID, "OrderClose" + ordername_ + " failed " + IntegerToString(OrderRetry + 1) + " times; error #" + IntegerToString(err) + " " + ErrorDescription(err));
         return;
        }
     }
   string typestr[6] = {"Buy", "Sell", "Buy Limit", "Sell Limit", "Buy Stop", "Sell Stop"};
   if(success)
     {
      myAlert(sym, "order", "Orders closed" + ordername_ + ": " + typestr[type] + " " + sym + " Magic #" + IntegerToString(MagicNumber));
      bot.SendMessage(ChatID, "Orders closed" + ordername_ + ": " + typestr[type] + " " + sym + " Magic #" + IntegerToString(MagicNumber));
     }
  }
  void myAlert(string sym, string type, string message)
  {
   if(type == "print")
      Print(message);
   else
      if(type == "error")
        {
         Print(type + " | @  " + sym + "," + IntegerToString(Period()) + " | " + message);
         bot.SendMessage(ChatID, type + " | @  " + sym + "," + IntegerToString(Period()) + " | " + message);
        }
      else
         if(type == "order")
           {
           }
         else
            if(type == "modify")
              {
              }
  }
  
  
  
  
int Risk_Percentage;
//-------- Debit/Credit total -------------------
bool StopTarget()
  {
   if((Risk_Percentage/AccountBalance()) *100 >= ProfitValue)
     {
     printf("Trade TARGET  STOP AT @"+(string)(Risk_Percentage/AccountBalance()*100)) ;
      return (true);
     }
   return (false);
  }
double ProfitValue;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int gmtoffset()
  {
   int gmthour;
   int gmtminute;
   datetime timegmt; // Gmt time
   datetime timecurrent; // Current time
   int gmtoffset=offset;
   timegmt=TimeGMT();
   timecurrent=TimeCurrent();
   gmthour=(int)StringToInteger(StringSubstr(TimeToStr(timegmt),11,2));
   gmtminute=(int)StringToInteger(StringSubstr(TimeToStr(timegmt),14,2));
   gmtoffset=TimeHour(timecurrent)-gmthour;
   if(gmtoffset<0)
      gmtoffset=24+gmtoffset;
   return(gmtoffset);
  }


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
input string google_urls="https://nfs.faireconomy.media/ff_calendar_thisweek.json?version=e21dd6a3050909b517a7ab0196cb9f1b";

//+------------------------------------------------------------------+
//| Function to read data from news.csv file                        |
//+------------------------------------------------------------------+
int ReadNewsData()
{
    // Open the CSV file
    int handle = FileOpen("news.csv", FILE_READ | FILE_CSV, ',');
    if (handle == INVALID_HANDLE)
    {
        Print("Error opening news.csv file!");
        return 0;
    }

    // Read the CSV file header
    string headerRow = FileReadString(handle);
    if (headerRow == "date , title ,impact , country , forecast , previous")
    {
        // Header matches, proceed to read data
        int lineCount = 0;
        while (!FileIsEnding(handle))
        {
           
            string rowData = FileReadString(handle);
if (rowData != "")
{
    string parsedData[6]; // Array to store parsed data
    int count = StringSplit(rowData, ';', parsedData); // Split rowData by ';' delimiter
ArrayResize(parsedData,count,0);
    if (count == 6)
    {
        // Data successfully parsed, do something with it
        string date = parsedData[0];
        string title = parsedData[1];
        string impact = parsedData[2];
        string country = parsedData[3];
        double forecast = StrToDouble(parsedData[4]);
        double previous = StrToDouble(parsedData[5]);

        // Print or use the parsed values
        Print("Date: ", date);
        Print("Title: ", title);
        Print("Impact: ", impact);
        Print("Country: ", country);
        Print("Forecast: ", forecast);
        Print("Previous: ", previous);

        // Assuming read_news_saved is an array of structs where each element represents a news item
        read_news_saved[lineCount].country = country;
        read_news_saved[lineCount].date = date;
        read_news_saved[lineCount].impact = impact;
        read_news_saved[lineCount].forecast = forecast;
        read_news_saved[lineCount].previous = previous;

        // Increment the line count
        lineCount++;
    }
    else
    {
        Print("Error parsing data in line ", lineCount + 2);  // Line count starts from 0, header is line 1
    }
}
        }

        // Close the file handle
        FileClose(handle);

        // Return the number of lines read
        return lineCount;
    }
    else
    {
        Print("Invalid header in news.csv file!");
        FileClose(handle);
        return 0;
    }
}
int DownLoadNews(){
string cookie = NULL, headers;
   uchar post[], result[];
   int res;
  
   int total=0;
   // Reset the last error code
   ResetLastError();
   
   // Loading a HTML page from Google Finance
   int timeout = 5000; // Timeout below 1000 (1 sec.) may not be enough for slow Internet connection
   res = WebRequest("GET", google_urls, cookie, NULL, timeout, post, 0, result, headers);
   
   // Checking errors
   if(res == -1)
   {
      Print("Error in WebRequest. Error code =", GetLastError());
      // Display a message about the necessity to add the address if URL is not listed
      MessageBox("Add the address '" + google_urls + "' in the list of allowed URLs on tab 'Expert Advisors'", "Error", MB_ICONINFORMATION);
      return 0;
   }
   else
   {
      // Load successful
      PrintFormat("The file has been successfully loaded, File size = %d bytes.", ArraySize(result));
      
      // Save the data to a file
     
   

   string out = CharArrayToString(result, 0, WHOLE_ARRAY);
   CJAVal js(NULL, out);
   
   js.Deserialize(result);

    total = ArraySize(result);
   printf("json array size" + (string)total);
  

   ArrayResize(mynews, total, 0);

   for(int i = 0; i < total; i++)
   {
      ArrayResize(js.m_e, total, 0);
      CJAVal item = js.m_e[i];

      mynews[i].date = item["date"].ToStr();
      mynews[i].title = item["title"].ToStr();
      printf(item["title"].ToStr()); // Print title for testing

      mynews[i].country = item["country"].ToStr();
      mynews[i].impact = item["impact"].ToStr();
      mynews[i].forecast = item["forecast"].ToDbl();
      mynews[i].previous = item["previous"].ToDbl();

      mynews[i].minutes = (int)(-TimeNewsFunck(i) + TimeCurrent());
   }

   // Update CSV file
   bool handle = FileOpen("news.csv", FILE_WRITE|FILE_SHARE_READ|FILE_CSV,',');
   string message = "date ,title , impact , country ";
   FileWrite(handle,"date , title , impact , country , forecast , previous"); // Save header row
   for(int i = 0; i < total; i++)
   {
      if(!handle)
      {  
      
         printf("Error: Can't open file news.csv to store news events! If open, please close it while the bot is running.");
      }
      else
      {
         FileSeek(handle, 0, SEEK_END);
         FileWrite(handle, mynews[i].date, mynews[i].title, mynews[i].impact, mynews[i].country, mynews[i].forecast, mynews[i].previous);
      }
   }
   FileClose(handle);
   
   }
   ArrayResize(read_news_saved,total,0);
   return total;
   }
int newsUpdate()
{  
   return DownLoadNews();
}
//+------------------------------------------------------------------+
//|               NEWSTRADE                                                   |
//+------------------------------------------------------------------+
bool newsTrade()//RETURN TRUE IF TRADE IS ALLOWED
  {string infoberita="";
   string message="NO MESSAGE ";
    string jamberita;
   double CheckNews=0;
   if(MinAfter>0)
     {
      if(TimeLocal()-LastUpd>=Upd)
        {
         Comment("News Loading...");
         Print("News Loading...");

         LastUpd=TimeLocal();
         Comment("");

      
        }
      NomNews=newsUpdate();
      
      ReadNewsData();
      
      WindowRedraw();
      //---Draw a line on the chart news--------------------------------------------
      if(DrawLines)
        {
         for(int i=0; i<NomNews; i++)
           {

            string Name=read_news_saved[i].date+"_"+read_news_saved[i].impact+"_"+read_news_saved[i].title;

            if(TimeNewsFunck(i)<TimeLocal() && Next)
               continue;

            color clrf = clrNONE;
            if(Vhigh &&  StringFind(read_news_saved[i].title,(string)judulnews,0)>=0)
               clrf=clrRed;

            if((Vhigh && read_news_saved[i].impact=="high") ||(Vhigh && read_news_saved[i].impact=="High"))
               clrf=clrRed;
            if((Vmedium &&read_news_saved[i].impact=="medium")||(Vmedium &&read_news_saved[i].impact=="Medium"))
               clrf=clrYellow;
            if(Vlow &&  read_news_saved[i].impact=="low")
               clrf=clrGreen;

            if(clrf==clrNONE)
               continue;

            if(mynews[i].title!="")
              {
               ObjectCreate(0,Name,OBJ_VLINE,0,TimeNewsFunck(i),Bid);
               ObjectSet(Name,OBJPROP_COLOR,clrf);
               ObjectSet(Name,OBJPROP_STYLE,Style);
               ObjectSetInteger(0,Name,OBJPROP_BACK,true);
              }
           }
        }
      //---------------event Processing------------------------------------
      int i;
      CheckNews=0;
      int power =0;

      for(i=0; i<NomNews; i++)
        {


         if(Vhigh && StringFind(mynews[i].title,(string)judulnews,0)>=0)
            power=1;

         if(Vhigh && read_news_saved[i].impact=="High")
            power=1;
         if(Vmedium && read_news_saved[i].impact=="Medium")
            power=2;
         if(Vlow &&  read_news_saved[i].impact=="Low")
            power=3;
         if(power==0)
           {
            continue;
           }
         if(TimeLocal()+ BeforeNewsStop> TimeNewsFunck(i) && TimeLocal()-60*AfterNewsStop< TimeNewsFunck(i)&&read_news_saved[i].title!="")
           {
            jamberita= "==>In "+(string)read_news_saved[i].minutes+" minutes\n"+read_news_saved[i].title;

            CheckNews=1;

            string ms;
            ms  =message=read_news_saved[i].date+ "    "+read_news_saved[i].title;//get message data with format

            if(ms!=message)
              {
               ms=message;
               bot.SendMessage(InpChannelChatID,jamberita);

              }
            else
              {
              }

           }
         else
           {
            CheckNews=0;

           }
         if((CheckNews==1 && i!=Now && Signal)||(CheckNews==1 && i!=Now && sendnews==yes))
           {

           message=read_news_saved[i].title +"    impact "+read_news_saved[i].impact;
            bot.SendMessage(InpChannelChatID,message);

            ;
            Now=i;


           }
         if(CheckNews>0 && NewsFilter)
            trade=false;
         if(CheckNews>0)
           {

            if(!StopTarget()&& !NewsFilter)
              {
               infoberita=" we are in the framework of the news\nAttention!! News Time \n!";




               /////  We are doing here if we are in the framework of the news

               if(read_news_saved[i].minutes>=AfterNewsStop&& !FirstAlert&&(CheckNews==1 && i==Now && sendnews == yes))
                 {

                  FirstAlert=true;
                  bot.SendMessage(InpChannelChatID,"-->>First Alert\n "+message);


                 }
               //--- second alert
               if(read_news_saved[i].minutes<BeforeNewsStop && !SecondAlert&&(CheckNews==1 && i==Now && sendnews == yes))
                 {
                 bot.SendMessage(InpChannelChatID,">>Second Alert\n "+message);
                  SecondAlert=true;

                 }






              }
           }
         else
           {

            if(NewsFilter)
               trade=true;
            // We are out of scope of the news release (No News)
            if(!StopTarget()&& read_news_saved[i].minutes==BeforeNewsStop && !SecondAlert&&(CheckNews==1 && i==Now && sendnews == yes))
              {
               jamberita= " We are out of scope of the news release\n (No News)\n";

               infoberita = "Waiting......";

              bot.SendMessage(InpChannelChatID,jamberita+infoberita);


              }

           }


        }

      return trade;
     }
   return trade;
  }
  
  
  bool trade=false;
  



//You can edit these externs freely *******/




input bool UseTime;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool inTimeInterval(datetime t, int From_Hour, int From_Min, int To_Hour, int To_Min)
  {

   if(UseTime==no)
      return true;
   string TOD = TimeToString(t, TIME_MINUTES);
   string TOD_From = StringFormat("%02d", From_Hour)+":"+StringFormat("%02d", From_Min);
   string TOD_To = StringFormat("%02d", To_Hour)+":"+StringFormat("%02d", To_Min);




   return((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, TOD_To) <= 0)
          || (StringCompare(TOD_From, TOD_To) > 0
              && ((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, "23:59") <= 0)
                  || (StringCompare(TOD, "00:00") >= 0 && StringCompare(TOD, TOD_To) <= 0))));
  }


//------------------------------------------------------------------------------------------------------------
//--------------------------------------------- INTERNAL VARIABLE --------------------------------------------
//--- Vars and arrays


//--- Alert

//--- Buffers


//+------------------------------------------------------------------+
//|                          TimeNewsFunck                                        |
//+------------------------------------------------------------------+
datetime TimeNewsFunck(int nomf)//RETURN CORRECT NEWS TIME FORMAT
  {
   string s=(string)mynews[nomf].date;
   string time=StringConcatenate(StringSubstr(s,0,4),".",StringSubstr(s,5,2),".",StringSubstr(s,8,2)," ",StringSubstr(s,11,2),":",StringSubstr(s,14,5));
   string hour=StringSubstr(s,5,2);
   read_news_saved[nomf].hour=((int)hour);
   string secondes=StringSubstr(s,14,5);
   read_news_saved[nomf].secondes=StrToInteger(secondes);
   return ((datetime)StringToTime(time) +offset*3600);
  }


input int GMT_offset;
int offset=GMT_offset;
bool Next;

string overboversellSymbol[2];


//+------------------------------------------------------------------+
//|                       timelockaction                                           |
//+------------------------------------------------------------------+
void timelockaction(string symbol)
  {

string sym=symbol;

   double stoplevel=0,proffit=OrderProfit(),newsl=0;

   ;
   int sy_digits=0;
   double sy_points=0;
   bool ans=false;
   bool next=false;
   int otype=-1;
   int kk=0;

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         continue;
      if(OrderMagicNumber()!=MagicNumber)
         continue;
      next=false;
      ans=false;
      string sy=OrderSymbol();

      sy_points=myPoint;
      stoplevel=MarketInfo(sy, MODE_STOPLEVEL)*sy_points;
      otype=OrderType();
      kk=0;
      proffit=OrderProfit()+OrderSwap()+OrderCommission();
      newsl=OrderOpenPrice();

      switch(EA_TIME_LOCK_ACTION)
        {
         case closeall:
            if(otype>1)
              {
               while(kk<5 && !OrderDelete(OrderTicket()))
                 {
                  kk++;

                  break;
                 }
              }
            else
              {
               double price=(otype==OP_BUY)?MarketInfo(sym,MODE_BID):MarketInfo(sym,MODE_ASK);
               while(kk<5 && !OrderClose(OrderTicket(),OrderLots(),price,10))
                 {
                  kk++;
                  price=(otype==OP_BUY)?MarketInfo(sym,MODE_BID):MarketInfo(sym,MODE_ASK);
                  break;
                 }
              }
            break;
         case closeprofit:
            if(proffit<=0)
               break;
            else
              {
               double price=(otype==OP_BUY)?MarketInfo(sym,MODE_BID):MarketInfo(sym,MODE_ASK);
               while(otype<2 && kk<5 && !OrderClose(OrderTicket(),OrderLots(),MarketInfo(sym,MODE_ASK),10))
                 {
                  kk++;
                  price=(otype==OP_BUY)?SymbolInfoDouble(sy,SYMBOL_BID):SymbolInfoDouble(sy,SYMBOL_ASK);
                  break;
                 }
              }
            break;


         case breakevenprofit:
            if(proffit<=0)
               break;
            else
              {
               double price=(otype==OP_BUY)?MarketInfo(sym,MODE_BID):MarketInfo(sym,MODE_ASK);
               while(otype<2 && kk<5 && MathAbs(price-newsl)>=stoplevel && !OrderModify(OrderTicket(),newsl,newsl,OrderTakeProfit(),OrderExpiration()))
                 {
                  kk++;
                  price=(otype==OP_BUY)?SymbolInfoDouble(sy,SYMBOL_BID):SymbolInfoDouble(sy,SYMBOL_ASK);
                  break;
                 }
              }
            break;

        }
      continue;
     }

  }
  int  TMN=0;
  TIME_LOCK EA_TIME_LOCK_ACTION;
  input bool CurrencyOnly;
  
  bool LongTradingts261M30;
  
  
//+------------------------------------------------------------------+
//|                     ControlTrade                                             |
//+------------------------------------------------------------------+
void ControlTrade(double resitance,double support,double previousdayhigh, string symbol1,bool controltrade=false)
  {

   if(controltrade)
     {
      datetime uninterrupted_trading_time=0;
      string datafeed=NULL;
      string trend=NULL;

      double moneyatrisk=0;
      double  previousdaylow;
      double openprice[100];
      double closeprice[100];
      int  lot_unit[];
      string tp_sl_mode=NULL;
      double price_average=0;
      double pair_winrate[7];
      double riskpercentage[8];
      double fibonnacci=0;
      string indicatorname=NULL;
      double lotsize=0;
      datetime timelimit=0;
      double percentagegoal=0;
      string pair=symbol1;
      string text=NULL;
      pair=symbol1;


      double S3x=0,R3x=0;

      R3x=resitance;
      double S1x=support;
      lotsize=OrderLots();

      double losses[],profit[];

      double size1=(double)Volume[0];
      double LotEq_To_Risk=((double)Volume[0])/100000;
      double yesterday_high = MathMax(yesterday_highx,   iHigh(symbol1,0,1));
     double yesterday_low = MathMin(yesterday_lowx, iLow(symbol1,0,1));


      string message=      StringFormat("Current bar for :%s,Open %2.4f ,High %2.4f,Low %2.4f Close %2.4f Volume %2.4f ",
                                        symbol1,
                                        iTime(symbol1,0,1),
                                        iOpen(symbol1,0,1),
                                        iHigh(symbol1,PERIOD_H1,0), iLow(symbol1,0,1),
                                        iClose(symbol1,PERIOD_H1,0),
                                        iVolume(symbol1, 0,1));
   

      if(Minute()==20|| Minute()==50)
        {
         bot.SendMessage(InpChannelChatID,message);
        }


       ArrayResize(riskpercentage,OrdersHistoryTotal(),0);


            ArrayResize(pair_winrate,OrdersHistoryTotal(),0);


            ArrayResize(losses,OrdersHistoryTotal(),0);

            ArrayResize(profit,OrdersHistoryTotal(),0);

            ArrayResize(closeprice,OrdersHistoryTotal()+1,0);
            ArrayResize(openprice,OrdersHistoryTotal(),0);
            ArrayResize(closeprice,OrdersHistoryTotal(),0);
      for(int h=OrdersHistoryTotal()-1; h>0; h--)
        {

         if(h <OrdersHistoryTotal())
           {

     


            if(OrderSelect(h,SELECT_BY_POS,MODE_HISTORY)&&symbol1==  OrderSymbol())
              {


               if(OrderProfit()>0)
                 {
                  profit[h]+=OrderProfit();

                 }
               if(OrderProfit()<0)
                 {
                  losses[h]+=OrderProfit();

                 }

               closeprice[h]=OrderClosePrice();
               openprice[h]=OrderOpenPrice();
               closeprice[h]=OrderClosePrice();
               previousdayhigh=yesterday_high;
               previousdaylow=yesterday_low;
               text="Trades are Allowed for this pair!";

               pair_winrate[h]=losses[h]/(1+profit[h]);






               if(pair_winrate[h]

                  ==(0.7))
                 {
                  int count=0;



                  text="Do not trade this pair today ->>"+symbol1;
                  printf("Do not trade this pair  "+symbol1);
                  count++;
                  riskpercentage[h]=(100)*pair_winrate[h];
                  if(count>2)
                     return;

                  bot.SendMessage(InpChannelChatID,text);

                 }
               else
                  if(pair_winrate[h]>=0.7 &&pair_winrate[h]<=0.79)
                    {

                     riskpercentage[h]=0.5;
                     double xtakeprofit=((stoploss/2)*MarketInfo(symbol1,MODE_POINT));
                     printf(StringFormat("symbol:   %s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],xtakeprofit));
                     message=StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],xtakeprofit);
                     bot.SendMessage(InpChannelChatID,message);

                    }
                  else
                     if(pair_winrate[h]>=0.8 &&pair_winrate[h]<=0.83)
                       {

                        riskpercentage[h]=1;
                       double xtakeprofit=((stoploss/3)*MarketInfo(symbol1,MODE_POINT));
                        printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],xtakeprofit));

                        string messages=StringFormat("%s \nPrice %2.4f \nTP  %2.4f \nSL %2.4f \nWinrate %2.4f, \nSupport %2.4f \nResistance %2.4f \nRisk To allocate %2.4f \nAdvise:%s\n", symbol1,  takeprofit,   stoploss,   pair_winrate[h],   support,    resitance,  riskpercentage[h],text);

                        printf(messages);
                        bot.SendMessage(InpChannelChatID,messages);


                       }
                     else
                        if(pair_winrate[h]>=0.84 &&pair_winrate[h]<=0.86)
                          {

                           riskpercentage[h]=2;
                          double xtakeprofit=stoploss/4;
                           printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],takeprofit));
                           string  messages=StringFormat("%s \nPrice %2.4f \nTP  %2.4f \nSL %2.4f \nWinrate %2.4f, \nSupport %2.4f \nResistance %2.4f \nRisk To allocate %2.4f \nAdvise:%s\n", symbol1, xtakeprofit,   stoploss,   pair_winrate[h],   support,    resitance,  riskpercentage[h],text);

                           bot.SendMessage(InpChannelChatID,messages);


                          }
                        else
                           if(pair_winrate[h]>=0.87 &&pair_winrate[h]<=0.89)
                             {
                              printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],takeprofit));

                              riskpercentage[h]=3;
                              double xtakeprofit=((stoploss/5)*MarketInfo(symbol1,MODE_POINT));

                              string  messages=StringFormat("%s \nPrice %2.4f \nTP  %2.4f \nSL %2.4f \nWinrate %2.4f, \nSupport %2.4f \nResistance %2.4f \nRisk To allocate %2.4f \nAdvise:%s\n", symbol1,   xtakeprofit,   stoploss,   pair_winrate[h],   support,    resitance,  riskpercentage[h],text);
                             bot.SendMessage(InpChannelChatID,messages);



                             }
                           else
                              if(pair_winrate[h]>=0.7 && pair_winrate[h]<=0.79)
                                {  double xtakeprofit=(stoploss/5)*MarketInfo(symbol1,MODE_POINT);

                                 printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],xtakeprofit));

                                 riskpercentage[h]=0.5;
                               xtakeprofit=((stoploss/2)*MarketInfo(symbol1,MODE_POINT));
                                 printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],xtakeprofit));

                                 string messages=StringFormat("%s \nPrice %2.4f \nTP  %2.4f \nSL %2.4f \nWinrate %2.4f, \nSupport %2.4f \nResistance %2.4f \nRisk To allocate %2.4f \nAdvise:%s\n", symbol1, takeprofit,   stoploss,   pair_winrate[h],   support,    resitance,  riskpercentage[h],text);

                                 bot.SendMessage(InpChannelChatID,messages);
                                }
                              else
                                 if(pair_winrate[h]>=0.90)
                                   {

                                    riskpercentage[h]=4;
                                  double  xtakeprofit=((stoploss/4)*MarketInfo(symbol1,MODE_POINT));
                                    printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],xtakeprofit));

                                    string messages=StringFormat("%s \nPrice %2.4f \nTP  %2.4f \nSL %2.4f \nWinrate %2.4f, \nSupport %2.4f \nResistance %2.4f \nRisk To allocate %2.4f \nAdvise:%s\n", symbol1, takeprofit,   stoploss,   pair_winrate[h],   support,    resitance,  riskpercentage[h],text);

                                    bot.SendMessage(InpChannelChatID,messages);



                                   }




               double R2x=0;





               bool report=  FileOpen("report.csv",FILE_READ|FILE_WRITE|FILE_SHARE_WRITE|FILE_SHARE_WRITE|FILE_CSV,';');

               if(!report)
                 {


                  printf("Error Unable to open  file!report.csv");
                  return ;

                 }

               FileWrite(report, "SYMBOL   ;  RISK%   ; LOSS    ; PROFIT");

               FileSeek(report,offset,SEEK_END);

               bool checkwrite=  FileWrite(report, symbol1,riskpercentage[h],losses[h],profit[h]);


               if(!checkwrite)
                 {


                  printf("Error Unable to write report on file!report.csv" + ErrorDescription(GetLastError()));
                  return;

                 }

               FileClose(report);






              }
           }


        }
     }





  }

        
     
double yesterday_highx;
double yesterday_lowx;


//+------------------------------------------------------------------+
//|                     CheckStochts261m30                                             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckStochts261m30(string symbol1)
  {


   double ts261m30=0;
   double OverSold=0;
   double OverBought=0;

      ts261m30=iCustom(symbol1,0,"1mfsto",30,30,30,3,1);
      OverSold=-45;
      OverBought=45;
      overboversellSymbol[0]=symbol1;
 
         if(ts261m30<OverSold)
           {
            LongTradingts261M30=true;
            ShortTradingts261M30=false;
           }
         if(ts261m30>OverBought)

           {
            LongTradingts261M30=false;
            ShortTradingts261M30=true;
           }
        
     
   return(false);
  }
  
  bool  ShortTradingts261M30=false;
  
  
  
//+------------------------------------------------------------------+
//|                      CHECK TRAILING                              |
//+------------------------------------------------------------------+
void  checkTrail(bool usetrailing,string sym)
  {
   string message;
   int count=OrdersTotal();
   double ts=0;
   if(usetrailing==false)
     {
      printf("trailling stop status:OFF");
      return;
     }
   else

      while(count>0)
        {
         int os=OrderSelect(count-1,MODE_TRADES);

         if(OrderMagicNumber()==MagicNumber)
           {
            //--- symbol variables
            double pip=SymbolInfoDouble(sym,SYMBOL_POINT);
            //if(SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS)==5 || SymbolInfoInteger(sym,SYMBOL_DIGITS)==3)
            //   pip*=10;
            int digits = (int)SymbolInfoInteger(sym,SYMBOL_DIGITS);

            switch(OrderType())
              {
               default:
                  break;
               case ORDER_TYPE_BUY:
                 {
                  switch(TrailingUnit)
                    {
                     default:
                     case InDollars:
                       {
                        double profit_distance = OrderProfit();
                        bool is_activated = profit_distance > TrailingStart;
                        if(is_activated)
                          {
                           double steps = MathFloor((profit_distance - TrailingStart)/TrailingStep);
                           if(steps>0)
                             {
                              //--- calculate stop loss distance
                              double stop_distance = GetDistanceInPoints(sym,TrailingUnit,TrailingStop*steps,1,Lots); //--- pip value forced to 1 because TrailingStop*steps already in points
                              double stop_price = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price > OrderStopLoss()))
                                {
                                 if(DebugTrailingStop)
                                   {
                                    Print("TS[Start:$"+DoubleToString(TrailingStart,2)
                                          +",Step:$"+DoubleToString(TrailingStep,2)
                                          +",Stop:$"+DoubleToString(TrailingStop,2)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:$"+DoubleToString(steps,digits)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));

                                    message="TS[Start:$"+DoubleToString(TrailingStart,2)
                                            +",Step:$"+DoubleToString(TrailingStep,2)
                                            +",Stop:$"+DoubleToString(TrailingStop,2)+"]"
                                            +" p:$"+DoubleToString(profit_distance,digits)
                                            +" s:$"+DoubleToString(steps,digits)
                                            +" sd:"+DoubleToString(stop_distance,digits)
                                            +" sp:"+DoubleToString(stop_price,digits);
                                    bot.SendMessage(ChatID,message);
                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));

                                    message="Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());


                                    bot.SendMessage(ChatID,message);


                                   }
                                }
                             }
                          }
                        break;
                       }
                     case InPips:
                       {
                       
                       pip=MarketInfo(sym,MODE_POINT);
                        double profit_distance = SymbolInfoDouble(OrderSymbol(),SYMBOL_BID) - OrderOpenPrice();
                        bool is_activated = profit_distance > TrailingStart*pip;
                        if(is_activated)    //--- get trailing steps
                          {
                           double steps = MathFloor((profit_distance - TrailingStart*pip)/(TrailingStep*pip));
                           if(steps>0)
                             {
                              //--- calculate stop loss distance
                              double stop_distance = TrailingStop*pip*steps;
                              double stop_price = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price > OrderStopLoss()))
                                {
                                 if(DebugTrailingStop)
                                   {
                                    Print("TS[Start:"+DoubleToString(TrailingStart)
                                          +",Step:"+DoubleToString(TrailingStep)
                                          +",Stop:"+DoubleToString(TrailingStop)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));
                                    message="TS[Start:"+DoubleToString(TrailingStart)
                                            +",Step:"+DoubleToString(TrailingStep)
                                            +",Stop:"+DoubleToString(TrailingStop)+"]"
                                            +" p:"+DoubleToString(profit_distance,digits)
                                            +" s:"+DoubleToString(steps)
                                            +" sd:"+DoubleToString(stop_distance,digits)
                                            +" sp:"+DoubleToString(stop_price,digits);
                                    bot.SendMessage(InpChannelChatID,message);
                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));

                                    message="Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());


                                    bot.SendMessage(InpChannelChatID,message);
                                   }
                                }
                             }
                          }
                        break;
                       }
                    }
                  break;
                 }
               case ORDER_TYPE_SELL:
                 {
                  switch(TrailingUnit)
                    {
                     default:
                     case InDollars:
                       {
                        double profit_distance = OrderProfit();
                        bool is_activated = profit_distance > TrailingStart;
                        if(is_activated)
                          {
                           double steps = MathFloor((profit_distance - TrailingStart)/TrailingStep);
                           if(steps>0)
                             {
                              //--- calculate stop loss distance
                              double stop_distance = GetDistanceInPoints(OrderSymbol(),TrailingUnit,TrailingStop*steps,1,Lots);//--- pip value forced to 1 because TrailingStop*steps already in points
                              double stop_price = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price < OrderStopLoss()))
                                {
                                 if(DebugTrailingStop)
                                   {
                                    Print("TS[Start:$"+DoubleToString(TrailingStart,2)
                                          +",Step:$"+DoubleToString(TrailingStep,2)
                                          +",Stop:$"+DoubleToString(TrailingStop,2)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:$"+DoubleToString(steps,digits)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));

                                    message="TS[Start:$"+DoubleToString(TrailingStart,2)
                                            +",Step:$"+DoubleToString(TrailingStep,2)
                                            +",Stop:$"+DoubleToString(TrailingStop,2)+"]"
                                            +" p:$"+DoubleToString(profit_distance,digits)
                                            +" s:$"+DoubleToString(steps,digits)
                                            +" sd:"+DoubleToString(stop_distance,digits)
                                            +" sp:"+DoubleToString(stop_price,digits);
                                    bot.SendMessage(InpChannelChatID,message);
                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                    if(UseBot)
                                       message="Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());
                                    bot.SendMessage(InpChannelChatID,message);
                                   }
                                }
                             }
                          }
                        break;
                       }
                     case InPips:
                       {  pip=MarketInfo(sym,MODE_POINT);
                        double profit_distance = OrderOpenPrice() - SymbolInfoDouble(OrderSymbol(),SYMBOL_ASK);
                        bool is_activated = profit_distance > TrailingStart*pip;
                        if(is_activated)    //--- get trailing steps
                          {
                           double steps = MathFloor((profit_distance - TrailingStart*pip)/(TrailingStep*pip));
                           if(steps>0)
                             {
                              //--- calculate stop loss distance
                              double stop_distance = TrailingStop*pip*steps;
                              double stop_price = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0) || (stop_price < OrderStopLoss()))
                                {
                                 if(DebugTrailingStop)
                                   {
                                    Print("TS[Start:"+DoubleToString(TrailingStart)
                                          +",Step:"+DoubleToString(TrailingStep)
                                          +",Stop:"+DoubleToString(TrailingStop)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));
                                    message="TS[Start:"+DoubleToString(TrailingStart)
                                            +",Step:"+DoubleToString(TrailingStep)
                                            +",Stop:"+DoubleToString(TrailingStop)+"]"
                                            +" p:"+DoubleToString(profit_distance,digits)
                                            +" s:"+DoubleToString(steps)
                                            +" sd:"+DoubleToString(stop_distance,digits)
                                            +" sp:"+DoubleToString(stop_price,digits);

                                    bot.SendMessage(InpChannelChatID,message);
                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                    if(UseBot)
                                      {
                                       message="Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());

                                       bot.SendMessage(InpChannelChatID,message);
                                      }
                                   }
                                }
                             }
                          }
                        break;
                       }
                    }
                  break;
                 }
              }
           }
         count--;
        }
  }


input bool UseBot= true;

//+------------------------------------------------------------------+
//|                       GetDistanceInPoints                                       |
//+------------------------------------------------------------------+
double GetDistanceInPoints(string symbo,ENUM_UNIT unit,double value,double pip_value,double volume)
  {
  if(volume==0) volume =0.01;
  
  pip_value=(int)MarketInfo(Symbol(),MODE_POINT);
  
   switch(unit)
     {
      default:
         PrintFormat("Unhandled unit %s, returning -1",EnumToString(unit));
         break;
      case InPips:
        {
         double distance = value;

         if(IsTesting()&&DebugUnit)
            PrintFormat("%s:%.2f dist: %.5f",EnumToString(unit),value,distance);

         return value;
        }
      case InDollars:
        {
         double tickSize        = MarketInfo(symbo,MODE_TICKSIZE);
         double tickValue       = MarketInfo(symbo,MODE_TICKVALUE);
         
         
         if(tickSize==0) tickSize=1;
         double dVpL            = tickValue / tickSize;
         double distance        = MarketInfo(symbo,MODE_ASK)-MarketInfo(symbo,MODE_POINT)*stoploss;

         if(IsTesting()&&DebugUnit)
            PrintFormat("%s:%s:%.2f dist: %.5f volume:%.2f dVpL:%.5f pip:%.5f",symbo,EnumToString(unit),value,distance,volume,dVpL,pip_value);

         return distance;
        }
     }
   return -1;
  }
  
//+------------------------------------------------------------------+
//|                   _BreakEvenProfits(                                             |
//+------------------------------------------------------------------+
void  BreakEvenProfits(bool usebreakeaven=false, string sym=NULL)
  {
 double lot =Lots;
   string message;
   if(usebreakeaven==false)
      return;
   int count=OrdersTotal();
   double ts=0;
   while(count>0)
     {
      int os=OrderSelect(count-1,MODE_TRADES);

      if(OrderMagicNumber()==MagicNumber)
        {
         //--- symbol variables
         double pip=SymbolInfoDouble(sym,SYMBOL_POINT);
         if(SymbolInfoInteger(sym,SYMBOL_DIGITS)==5 || SymbolInfoInteger(sym,SYMBOL_DIGITS)==3)
            pip*=10;
         int  digits = (int)SymbolInfoInteger(sym,SYMBOL_DIGITS);

         switch(OrderType())
           {
            default:
               break;
            case ORDER_TYPE_BUY:
              {
               switch(BreakEvenUnit)
                 {
                  default:
                  case InDollars:
                    {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > BreakEvenTrigger;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / BreakEvenTrigger);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoBreakEven)
                             {
                              //--- calculate stop loss distance
                              double stop_distance   = GetDistanceInPoints(sym,BreakEvenUnit,BreakEvenProfit*steps,1,lot); //--- pip value forced to 1 because BreakEvenProfit*steps already in points
                              double stop_price      = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price > OrderStopLoss()))
                                {
                                 if(DebugBreakEven)
                                   {
                                    Print("BE[Trigger:$"+DoubleToString(BreakEvenTrigger,2)
                                          +",Profit:$"+DoubleToString(BreakEvenProfit,2)
                                          +",Max:"+DoubleToString(MaxNoBreakEven,2)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:$"+DoubleToString(steps,digits)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));

                                    message="BE[Trigger:$"+DoubleToString(BreakEvenTrigger,2)
                                            +",Profit:$"+DoubleToString(BreakEvenProfit,2)
                                            +",Max:"+DoubleToString(MaxNoBreakEven,2)+"]"
                                            +" p:$"+DoubleToString(profit_distance,digits)
                                            +" s:$"+DoubleToString(steps,digits)
                                            +" sd:"+DoubleToString(stop_distance,digits)
                                            +" sp:"+DoubleToString(stop_price,digits);
                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify break even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));


                                    message="Failed to modify break even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());
                                   }
                                 
                                    bot.SendMessage(ChatID,message);

                                }
                             }
                          }
                       }
                     break;
                    }
                  case InPips:
                    {
                     double profit_distance = SymbolInfoDouble(sym,SYMBOL_BID) - OrderOpenPrice();
                     bool is_activated = profit_distance > BreakEvenTrigger*pip;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / BreakEvenTrigger*pip);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoBreakEven)
                             {
                              double stop_distance = BreakEvenProfit*pip*steps;
                              double stop_price = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price > OrderStopLoss()))
                                {
                                 if(DebugBreakEven)
                                   {
                                    string   messages;
                                    Print("BE[Trigger:"+DoubleToString(BreakEvenTrigger)
                                          +",Profit:"+DoubleToString(BreakEvenProfit)
                                          +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));
                                    messages="BE[Trigger:"+DoubleToString(BreakEvenTrigger)
                                             +",Profit:"+DoubleToString(BreakEvenProfit)
                                             +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                             +" p:"+DoubleToString(profit_distance,digits)
                                             +" s:"+DoubleToString(steps)
                                             +" sd:"+DoubleToString(stop_distance,digits)
                                             +" sp:"+DoubleToString(stop_price,digits);

                                   }


                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify break even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));

                                    if(UseBot)
                                      {
                                       message="Failed to modify Break Even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());
                                       bot.SendMessage(InpChannelChatID,message);



                                      }


                                   }


                                }
                             }
                          }
                       }
                     break;
                    }
                 }
               break;
              }
            case ORDER_TYPE_SELL:
              {
               switch(BreakEvenUnit)
                 {
                  default:
                  case InDollars:
                    {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > BreakEvenTrigger;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / BreakEvenTrigger);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoBreakEven)
                             {
                              //--- calculate stop loss distance
                              double stop_distance = GetDistanceInPoints(sym,BreakEvenUnit,BreakEvenProfit*steps,1,lot);
                              double stop_price    = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price < OrderStopLoss()))
                                {
                                 if(DebugBreakEven)
                                   {
                                    Print("BE[Trigger:$"+DoubleToString(BreakEvenTrigger,2)
                                          +",Profit:$"+DoubleToString(BreakEvenProfit,2)
                                          +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:$"+DoubleToString(steps,digits)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));
                                    message="BE[Trigger:$"+DoubleToString(BreakEvenTrigger,2)
                                            +",Profit:$"+DoubleToString(BreakEvenProfit,2)
                                            +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                            +" p:$"+DoubleToString(profit_distance,digits)
                                            +" s:$"+DoubleToString(steps,digits)
                                            +" sd:"+DoubleToString(stop_distance,digits)
                                            +" sp:"+DoubleToString(stop_price,digits);

                                    bot.SendMessage(InpChannelChatID,message);

                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify break even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));


                                    if(UseBot)
                                       message="Failed to modify Break Even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());

                                    bot.SendMessage(InpChannelChatID,message);


                                   }
                                }
                             }
                          }
                       }
                     break;
                    }
                  case InPips:
                    {
                     double profit_distance = OrderOpenPrice() - SymbolInfoDouble(sym,SYMBOL_ASK);
                     bool is_activated = profit_distance > BreakEvenTrigger*pip;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / BreakEvenTrigger*pip);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoBreakEven)
                             {
                              double stop_distance = BreakEvenProfit*pip*steps;
                              double stop_price    = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price < OrderStopLoss()))
                                {
                                 if(DebugBreakEven)
                                   {
                                    Print("BE[Trigger:"+DoubleToString(BreakEvenTrigger)
                                          +",Profit:"+DoubleToString(BreakEvenProfit)
                                          +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));

                                    message=   "BE[Trigger:"+DoubleToString(BreakEvenTrigger)
                                               +",Profit:"+DoubleToString(BreakEvenProfit)
                                               +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                               +" p:"+DoubleToString(profit_distance,digits)
                                               +" s:"+DoubleToString(steps)
                                               +" sd:"+DoubleToString(stop_distance,digits)
                                               +" sp:"+DoubleToString(stop_price,digits);
                                    bot.SendMessage(InpChannelChatID,message);//smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);

                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify break even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));

                                    message="Failed to modify Break Even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());

                                    bot.SendMessage(InpChannelChatID,message);


                                   }
                                }
                             }
                          }
                       }
                     break;
                    }
                 }
               break;
              }
           }

        }
      count--;
     }
  }

//+------------------------------------------------------------------+
//|                 CHECK PARTIAL CLOSE                              |
//+------------------------------------------------------------------+
void CheckPartialClose(bool   checkPartialClose =false,string sym=NULL)
  {
   if(!checkPartialClose)
      return;
   int count=OrdersTotal();
   double ts=0;
   while(count>0)
     {
      int os=OrderSelect(count-1,MODE_TRADES);

      if(OrderMagicNumber()==MagicNumber)
        {
         //--- symbol variables
         double pip=SymbolInfoDouble(sym,SYMBOL_POINT);
         if(SymbolInfoInteger(sym,SYMBOL_DIGITS)==5 || SymbolInfoInteger(sym,SYMBOL_DIGITS)==3)
            pip*=10;
         int digits = (int)SymbolInfoInteger(sym,SYMBOL_DIGITS);

         switch(OrderType())
           {
            default:
               break;
            case ORDER_TYPE_BUY:
              {
               switch(PartialCloseUnit)
                 {
                  default:
                  case InDollars:
                    {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > PartialCloseTrigger;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / PartialCloseTrigger);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoPartialClose)
                             {
                              //--- calculate new lot size
                              int lot_digits = (int)(MathLog(SymbolInfoDouble(sym,SYMBOL_VOLUME_STEP))/MathLog(0.1));
                              double lots = NormalizeDouble(OrderLots() * PartialClosePercent,lot_digits);
                              if(lots < SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN))    //--- close all
                                {
                                 lots = OrderLots();
                                }
                              if(OrderClose(OrderTicket(),lots,SymbolInfoDouble(sym,SYMBOL_BID),MaxSlippage,clrYellow))
                                {

                                 if(DebugPartialClose)
                                   {
                                    Print("PC[Trigger:$"+DoubleToString(PartialCloseTrigger,2)
                                          +",Percent:"+DoubleToString(PartialClosePercent,2)
                                          +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps,digits)
                                          +" l:"+DoubleToString(lots,lot_digits));

                                    string messages= "PC[Trigger:$"+DoubleToString(PartialCloseTrigger,2)
                                                     +",Percent:"+DoubleToString(PartialClosePercent,2)
                                                     +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                                     +" p:$"+DoubleToString(profit_distance,digits)
                                                     +" s:"+DoubleToString(steps,digits)
                                                     +" l:"+DoubleToString(lots,lot_digits) ;

                                    bot.SendMessage(InpChannelChatID,messages);

                                   }
                                }
                              else
                                {
                                 Print("Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));

                                 string messages=   "Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());


                                 bot.SendMessage(InpChannelChatID,messages);

                                }
                             }
                          }
                       }
                     break;
                    }
                  case InPips:
                    {
                     double profit_distance = SymbolInfoDouble(sym,SYMBOL_BID) - OrderOpenPrice();
                     bool is_activated = profit_distance > PartialCloseTrigger*pip;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / PartialCloseTrigger*pip);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoPartialClose)
                             {
                              //--- calculate new lot size
                              int lot_digits = (int)(MathLog(SymbolInfoDouble(sym,SYMBOL_VOLUME_STEP))/MathLog(0.1));
                              double lots = NormalizeDouble(OrderLots() * PartialClosePercent,lot_digits);
                              if(lots < SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN))    //--- close all
                                {
                                 lots = OrderLots();
                                }
                              if(OrderClose(OrderTicket(),lots,SymbolInfoDouble(sym,SYMBOL_BID),MaxSlippage,clrYellow))
                                {
                                 if(DebugPartialClose)
                                   {
                                    Print("PC[Trigger:"+DoubleToString(PartialCloseTrigger,2)
                                          +",Percent:"+DoubleToString(PartialClosePercent,2)
                                          +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps,digits)
                                          +" l:"+DoubleToString(lots,lot_digits));
                                    string message=           "PC[Trigger:"+DoubleToString(PartialCloseTrigger,2)
                                                              +",Percent:"+DoubleToString(PartialClosePercent,2)
                                                              +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                                              +" p:"+DoubleToString(profit_distance,digits)
                                                              +" s:"+DoubleToString(steps,digits)
                                                              +" l:"+DoubleToString(lots,lot_digits);
                                    bot.SendMessage(InpChannelChatID,message);


                                   }
                                }
                              else
                                {
                                 Print("Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                 string  messages="Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());



                                 bot.SendMessage(InpChannelChatID,messages);

                                }
                             }
                          }
                       }
                     break;
                    }
                 }
               break;
              }
            case ORDER_TYPE_SELL:
              {
               switch(PartialCloseUnit)
                 {
                  default:
                  case InDollars:
                    {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > PartialCloseTrigger;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / PartialCloseTrigger);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoPartialClose)
                             {
                              //--- calculate new lot size
                              int lot_digits = (int)(MathLog(SymbolInfoDouble(sym,SYMBOL_VOLUME_STEP))/MathLog(0.1));
                              double lots = NormalizeDouble(OrderLots() * PartialClosePercent,lot_digits);
                              if(lots < SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN))    //--- close all
                                {
                                 lots = OrderLots();
                                }
                              if(OrderClose(OrderTicket(),lots,SymbolInfoDouble(sym,SYMBOL_ASK),MaxSlippage,clrYellow))
                                {

                                 if(DebugPartialClose)
                                   {
                                    Print("PC[Trigger:$"+DoubleToString(PartialCloseTrigger,2)
                                          +",Percent:"+DoubleToString(PartialClosePercent,2)
                                          +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps,digits)
                                          +" l:"+DoubleToString(lots,lot_digits));
                                    string message="PC[Trigger:$"+DoubleToString(PartialCloseTrigger,2)
                                                   +",Percent:"+DoubleToString(PartialClosePercent,2)
                                                   +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                                   +" p:$"+DoubleToString(profit_distance,digits)
                                                   +" s:"+DoubleToString(steps,digits)
                                                   +" l:"+DoubleToString(lots,lot_digits);
                                    bot.SendMessage(InpChannelChatID,message);


                                   }
                                }
                              else
                                {
                                 Print("Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));

                                 string message="Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());

                                bot.SendMessage(InpChannelChatID,message);


                                }
                             }
                          }
                       }
                     break;
                    }
                  case InPips:
                    {
                     double profit_distance = OrderOpenPrice() - SymbolInfoDouble(sym,SYMBOL_ASK);
                     bool is_activated = profit_distance > PartialCloseTrigger*pip;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / PartialCloseTrigger*pip);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoPartialClose)
                             {
                              //--- calculate new lot size
                              int lot_digits = (int)(MathLog(SymbolInfoDouble(sym,SYMBOL_VOLUME_STEP))/MathLog(0.1));
                              double lots = NormalizeDouble(OrderLots() * PartialClosePercent,lot_digits);
                              if(lots < SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN))    //--- close all
                                {
                                 lots = OrderLots();
                                }
                              if(OrderClose(OrderTicket(),lots,SymbolInfoDouble(sym,SYMBOL_ASK),MaxSlippage,clrYellow))
                                {

                                 if(DebugPartialClose)
                                   {
                                    Print("PC[Trigger:"+DoubleToString(PartialCloseTrigger,2)
                                          +",Percent:"+DoubleToString(PartialClosePercent,2)
                                          +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps,digits)
                                          +" l:"+DoubleToString(lots,lot_digits));
                                    string    messages=      "PC[Trigger:"+DoubleToString(PartialCloseTrigger,2)
                                                             +",Percent:"+DoubleToString(PartialClosePercent,2)
                                                             +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                                             +" p:"+DoubleToString(profit_distance,digits)
                                                             +" s:"+DoubleToString(steps,digits)
                                                             +" l:"+DoubleToString(lots,lot_digits);

                                    bot.SendMessage(InpChannelChatID,messages);
                                   }
                                }
                             }
                           else
                             {
                              Print("Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                              string messages="Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());


                              bot.SendMessage(InpChannelChatID,messages);
                             }
                          }
                       }
                    }
                  break;
                 }
              }
            break;
           }
        }
      break;
     }
   count--;

  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  checkTrail(string sym)
  {
   int count=OrdersTotal();
   double ts=0;
   while(count>0)
     {
      int os=OrderSelect(count-1,MODE_TRADES);

      if(OrderMagicNumber()==MagicNumber)
        {
         //--- symbol variables
         double pip=SymbolInfoDouble(sym,SYMBOL_POINT);
         if(SymbolInfoInteger(sym,SYMBOL_DIGITS)==5 || SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS)==3)
            pip*=10;
         int digits = (int)SymbolInfoInteger(sym,SYMBOL_DIGITS);

         switch(OrderType())
           {
            default:
               break;
            case ORDER_TYPE_BUY:
              {
               switch(TrailingUnit)
                 {
                  default:
                  case InDollars:
                    {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > TrailingStart;
                     if(is_activated)
                       {
                        double steps = MathFloor((profit_distance - TrailingStart)/TrailingStep);
                        if(steps>0)
                          {
                           //--- calculate stop loss distance
                           double stop_distance = GetDistanceInPoints(sym,TrailingUnit,TrailingStop*steps,1,   Lots); //--- pip value forced to 1 because TrailingStop*steps already in points
                           double stop_price = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                           //--- move stop if needed
                           if((OrderStopLoss()==0)||(stop_price > OrderStopLoss()))
                             {
                              if(DebugTrailingStop)
                                {
                                 Print("TS[Start:$"+DoubleToString(TrailingStart,2)
                                       +",Step:$"+DoubleToString(TrailingStep,2)
                                       +",Stop:$"+DoubleToString(TrailingStop,2)+"]"
                                       +" p:$"+DoubleToString(profit_distance,digits)
                                       +" s:$"+DoubleToString(steps,digits)
                                       +" sd:"+DoubleToString(stop_distance,digits)
                                       +" sp:"+DoubleToString(stop_price,digits));
                                }
                              if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                {
                                 Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                }
                             }
                          }
                       }
                     break;
                    }
                  case InPips:
                    {
                     double profit_distance = SymbolInfoDouble(sym,SYMBOL_BID) - OrderOpenPrice();
                     bool is_activated = profit_distance > TrailingStart*pip;
                     if(is_activated)    //--- get trailing steps
                       {
                        double steps = MathFloor((profit_distance - TrailingStart*pip)/(TrailingStep*pip));
                        if(steps>0)
                          {
                           //--- calculate stop loss distance
                           double stop_distance = TrailingStop*pip*steps;
                           double stop_price = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                           //--- move stop if needed
                           if((OrderStopLoss()==0)||(stop_price > OrderStopLoss()))
                             {
                              if(DebugTrailingStop)
                                {
                                 Print("TS[Start:"+DoubleToString(TrailingStart)
                                       +",Step:"+DoubleToString(TrailingStep)
                                       +",Stop:"+DoubleToString(TrailingStop)+"]"
                                       +" p:"+DoubleToString(profit_distance,digits)
                                       +" s:"+DoubleToString(steps)
                                       +" sd:"+DoubleToString(stop_distance,digits)
                                       +" sp:"+DoubleToString(stop_price,digits));
                                }
                              if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                {
                                 Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                }
                             }
                          }
                       }
                     break;
                    }
                 }
               break;
              }
            case ORDER_TYPE_SELL:
              {
               switch(TrailingUnit)
                 {
                  default:
                  case InDollars:
                    {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > TrailingStart;
                     if(is_activated)
                       {
                        double steps = MathFloor((profit_distance - TrailingStart)/TrailingStep);
                        if(steps>0)
                          {
                           //--- calculate stop loss distance
                           double stop_distance = GetDistanceInPoints(sym,TrailingUnit,TrailingStop*steps,1,Lots);//--- pip value forced to 1 because TrailingStop*steps already in points
                           double stop_price = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                           //--- move stop if needed
                           if((OrderStopLoss()==0)||(stop_price < OrderStopLoss()))
                             {
                              if(DebugTrailingStop)
                                {
                                 Print("TS[Start:$"+DoubleToString(TrailingStart,2)
                                       +",Step:$"+DoubleToString(TrailingStep,2)
                                       +",Stop:$"+DoubleToString(TrailingStop,2)+"]"
                                       +" p:$"+DoubleToString(profit_distance,digits)
                                       +" s:$"+DoubleToString(steps,digits)
                                       +" sd:"+DoubleToString(stop_distance,digits)
                                       +" sp:"+DoubleToString(stop_price,digits));
                                }
                              if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                {
                                 Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                }
                             }
                          }
                       }
                     break;
                    }
                  case InPips:
                    {
                     double profit_distance = OrderOpenPrice() - SymbolInfoDouble(OrderSymbol(),SYMBOL_ASK);
                     bool is_activated = profit_distance > TrailingStart*pip;
                     if(is_activated)    //--- get trailing steps
                       {
                        double steps = MathFloor((profit_distance - TrailingStart*pip)/(TrailingStep*pip));
                        if(steps>0)
                          {
                           //--- calculate stop loss distance
                           double stop_distance = TrailingStop*pip*steps;
                           double stop_price = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                           //--- move stop if needed
                           if((OrderStopLoss()==0) || (stop_price < OrderStopLoss()))
                             {
                              if(DebugTrailingStop)
                                {
                                 Print("TS[Start:"+DoubleToString(TrailingStart)
                                       +",Step:"+DoubleToString(TrailingStep)
                                       +",Stop:"+DoubleToString(TrailingStop)+"]"
                                       +" p:"+DoubleToString(profit_distance,digits)
                                       +" s:"+DoubleToString(steps)
                                       +" sd:"+DoubleToString(stop_distance,digits)
                                       +" sp:"+DoubleToString(stop_price,digits));
                                }
                              if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                {
                                 Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                }
                             }
                          }
                       }
                     break;
                    }
                 }
               break;
              }
           }
        }
      count--;
     }
  }
  
 
//+--------------------------------------------------------------------+
// Virtual Trailing                                                    +
//+--------------------------------------------------------------------+
void VirtualTrailingStopLoss(string sym)
  {
// Loop through all open orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         TrailingStopLoss_entryPrice = OrderOpenPrice();
         // Buy Order Trailing
         if(OrderSymbol() ==sym && OrderType() == OP_BUY)
           {
            double LastVirtualBuySL = GetHorizontalLinePrice("B"+(string)OrderTicket());
            if(MarketInfo(sym,MODE_BID)<= LastVirtualBuySL && LastVirtualBuySL != 0)
              {
               ObjectDelete("B"+(string)OrderTicket());
               ResetLastError();
               if(!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
                  Print(__FUNCTION__ + " => Buy Order failed to close : " + (string) ErrorDescription(GetLastError()));
              }

            if(MarketInfo(sym,MODE_BID) - (TrailingStopLoss_entryPrice + Trailing_Start * gPips) > gPips * Trailing_Gap)
              {
               double VirtualBuySL = MarketInfo(sym,MODE_BID)- (gPips * Trailing_Gap);
               if(LastVirtualBuySL < VirtualBuySL || LastVirtualBuySL == 0.00)
                  DrawHline("B"+(string)OrderTicket(),VirtualBuySL,clrOrange,1);
              }
           }
        }

      // Sell Order Trailing
      if(OrderSymbol() == sym && OrderType() == OP_SELL)
        {
         double LastVirtualSellSL = GetHorizontalLinePrice("S"+(string)OrderTicket());
         if(MarketInfo(sym,MODE_ASK)>= LastVirtualSellSL && LastVirtualSellSL != 0)
           {
            ObjectDelete("S"+(string)OrderTicket());
            ResetLastError();
            if(!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
               Print(__FUNCTION__ + " => Sell Order failed to close : " + ErrorDescription(GetLastError()));
           }
         if((TrailingStopLoss_entryPrice - Trailing_Start * gPips) - MarketInfo(sym,MODE_ASK)> gPips * Trailing_Gap)
           {
            double VirtualSellSL = MarketInfo(sym,MODE_ASK) + (gPips * Trailing_Gap);
            if(LastVirtualSellSL > VirtualSellSL || LastVirtualSellSL == 0.00)
               DrawHline("S"+(string)OrderTicket(),VirtualSellSL,clrOrange,1);
           }
        }
     }
  } 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TotalOpenProfit(int direction,string sym)
  {
   double result = 0;
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != sym || OrderMagicNumber() != MagicNumber)
         continue;
      if((direction < 0 && OrderType() == OP_BUY) || (direction > 0 && OrderType() == OP_SELL))
         continue;
      result += OrderProfit();
     }
   return(result);
  }


int Oc,Os;
//+------------------------------------------------------------------+
//|                     DYp                                              |
//+------------------------------------------------------------------+
double DYp(datetime start_)
  {

   double total = 0;
   for(int i = OrdersHistoryTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
        {
         if(OrderMagicNumber() == MagicNumber  &&OrderCloseTime()>=start_)
           {
            total+=(OrderProfit()+OrderSwap()+OrderCommission());
           }
        }
     }
   return(total);
  }




// Chart Comment Status
void ChartComment()
  {

   Comment("                                               ---------------------------------------------"
           "\n                                             :: ===>RRS Trailing<==="
           "\n                                             :: Info                              : (Spread : " + gSpread + ") |:| (Stop Level : " + gStopLevel + ") |:| (Freeze Level : " + gFreezeLevel + ")" +
           "\n                                             :: Leverage                       : 1 : " + AccountLeverage() + " ("+DemoRealCheck+" Account)" +
           "\n                                             ------------------------------------------------"
           "\n                                             :: Trailing                          : (Start : " + Trailing_Start + ") |:| (Gap : " + Trailing_Gap + ") |:| (Type : " + cTrailingType + ")" +
           "\n                                             ------------------------------------------------");
  }

//+------------------------------------------------------------------+
//|  Virtual Trailing Line                                           |
//+------------------------------------------------------------------+
void DrawHline(string name,double P,color clr,int WIDTH)
  {
   if(ObjectFind(name)!=-1)
      ObjectDelete(name);
   ObjectCreate(name,OBJ_HLINE,0,0,P,0,0,0,0);
   ObjectSet(name,OBJPROP_COLOR,clr);
   ObjectSet(name,OBJPROP_STYLE,2);
   ObjectSet(name,OBJPROP_WIDTH,WIDTH);
  }

//+--------------------------------------------------------------------+
// Trailing SL                                                         +
//+--------------------------------------------------------------------+
double gPips=0,TrailingStopLoss_entryPrice=0;
void TrailingStopLoss(string sym)
  {
// Loop through all open orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         TrailingStopLoss_entryPrice = OrderOpenPrice();
         // Buy Order Trailing
         if(OrderSymbol() == sym && OrderType() == OP_BUY)
           {
            if( MarketInfo(sym,MODE_BID) - (TrailingStopLoss_entryPrice + Trailing_Start * gPips) > gPips * Trailing_Gap)
              {
               if(OrderStopLoss() <  MarketInfo(sym,MODE_BID) - gPips * Trailing_Gap || OrderStopLoss() == 0)
                 {
                  ResetLastError();
                  RefreshRates();
                  if(!OrderModify(OrderTicket(), OrderOpenPrice(),  MarketInfo(sym,MODE_BID) - gPips * Trailing_Gap, OrderTakeProfit(), 0, clrNONE))
                     Print(__FUNCTION__ + " => Buy Trail Error Code : " + GetLastError());
                 }
              }
           }

         // Sell Order Trailing
         if(OrderSymbol() == sym && OrderType() == OP_SELL)
           {
            if((TrailingStopLoss_entryPrice - Trailing_Start * gPips) -  MarketInfo(sym,MODE_ASK) > gPips * Trailing_Gap)
              {
               if(OrderStopLoss() > MarketInfo(sym,MODE_ASK) + gPips * Trailing_Gap || OrderStopLoss() == 0)
                 {
                  ResetLastError();
                  RefreshRates();
                  if(!OrderModify(OrderTicket(), OrderOpenPrice(), MarketInfo(sym,MODE_ASK) + gPips * Trailing_Gap, OrderTakeProfit(), 0, clrNONE))
                     Print(__FUNCTION__ + " => Sell Trail Error Code : " + ErrorDescription(GetLastError()));
                 }
              }
           }
        }
     }
  }
 double TP;
 string EA_name="ALPHAZERO";
//+------------------------------------------------------------------+
//| Custom create object function                                    |
//+------------------------------------------------------------------+
void createObject(long st_ID,ENUM_OBJECT obj,int window,int x,int y,string txt="")
  {
   ObjectCreate(EA_name+"_"+IntegerToString(st_ID),obj,window,0,0);
   ObjectSet(EA_name+"_"+IntegerToString(st_ID),OBJPROP_XDISTANCE,x);
   ObjectSet(EA_name+"_"+IntegerToString(st_ID),OBJPROP_YDISTANCE,y);
   ObjectSetText(EA_name+"_"+IntegerToString(st_ID),txt,text_size,"Arial",text_color);
  }
  //+------------------------------------------------------------------+
//| Virtual Trailing Line Price                                      |
//+------------------------------------------------------------------+
double GetHorizontalLinePrice(string objectName)
  {
// Loop through all objects on the chart
   for(int i = ObjectsTotal()-1; i >= 0; i--)
     {
      // Check if the object is a horizontal line and its name matches the specified objectName
      if(ObjectName(i) == objectName)
        {
         // Return the price value of the horizontal line
         return ObjectGetDouble(0, objectName, OBJPROP_PRICE1);
        }
     }
// If the object with the specified name is not found, return a default value (e.g., 0.00)
   return 0.00;
  }
input bool UsePartialClose                      = true;                  // Use Partial Close
input ENUM_UNIT PartialCloseUnit                = InPips;             // Partial Close Unit
input double PartialCloseTrigger                = 40;                    // Partial Close after
input double PartialClosePercent                = 0.5;                   // Percentage of lot size to close
input int MaxNoPartialClose                     = 1;                     // Max No of Partial Close
input string ___TRADE_MONITORING_TRAILING___    = "";                    // - Trailing Stop Parameters
input bool UseTrailingStop                      = true;                  // Use Trailing Stop
input ENUM_UNIT TrailingUnit                    = InPips;             // Trailing Unit
input int TrailingStart                      = 35;                   // Trailing Activated After
input int TrailingStep                       = 10;                   // Trailing Step
input double TrailingStop                       = 2;                    // Trailing Stop
input string ___TRADE_MONITORING_BE_________    = "";                    // - Break Even Parameters
input bool UseBreakEven                         = true;                  // Use Break Even
input ENUM_UNIT BreakEvenUnit                   = InPips;             // Break Even Unit
input double BreakEvenTrigger                   = 30;                   // Break Even Trigger
input double BreakEvenProfit                    = 1;                   // Break Even Profit
input int MaxNoBreakEven                        = 1;                     // Max No of Break Even
extern Answer     DeletePendingOrder       = yes;          //Delete Pending Order
extern int        orderexp          = 43;           //Pending order Experation (inBars)


extern bool        OpenNewBarIndicator           = true;        //Open New Bar Indicator

input bool DebugTrailingStop         = true;           // Trailing Stop Infos in Journal
input bool DebugBreakEven            = true;           // Break Even Infos in Journal
input bool DebugUnit                 = true;           // SL TP Trail BE Units Infos in Journal (in tester)
input bool DebugPartialClose         = true;           // Partial close Infos in Journal
input Answer UseFibo_TP=yes;//Use Fibo take profit?(Yes/No)
//extern bool     snr           = TRUE;           //Use Support & Resistance
extern bool    showfibo       = true;           // Show Fibo Line
extern bool Show_Support_Resistance=true;//Show Support & Resistance lines
extern  ENUM_TIMEFRAMES snrperiod     = PERIOD_M30;         //Support & Resistance Time Frame
extern Answer      sendTradesignal       = yes; //Send Strategy Trade Signal

extern int MaxSlippage = 3; //Slippages
input ENUM_UNIT TakeProfitUnit       = InDollars;      // Take Profit Unit

double inpTP= MaxTP;
input ENUM_UNIT StopLossUnit         = InDollars;      // Stop Loss Unit



extern string __TrailingManagement__ = "***Trailing Settings***";
enum TrailingType_enum {Virtual_Trailing, Classic_Trailing};
extern TrailingType_enum Trailing_Type = Virtual_Trailing;
extern int Trailing_Start = 30;
extern int Trailing_Gap = 30;




//---
CComment       comment;
CMyBot         bot;
ENUM_RUN_MODE  run_mode;
datetime       time_check;
int            web_error;
int            init_error;
string         photo_id = NULL;
int siz = 0;



int MagicNumber = 1345;




//  Input parameters                                               |
input ENUM_UPDATE_MODE  InpUpdateMode = UPDATE_NORMAL; //Update Mode
input string            InpToken = ""; //API KEY
input long ChatID = -1001648392740; //CHAT OR GROUP ID

input string CHANNEL_NAME = "tradeexpert_infos";
long TELEGRAM_GROUP_CHAT_ID = ChatID;
string            InpUserNameFilter = ""; //Whitelist Usernames
input   string            InpTemplates = "TrendExpert,ADX,RSI, ADX,Momentum"; //Templates for screenshot

//I need an expert to develop a Telegram to MT4 & MT5 copying system with the following functions:


input EXECUTION_MODE  ImmediateExecution;// TRADE MODE

input MONEY_MANAGEMENT  money_management;// MONEY MANAGEMENT
input bool  Move_SL_Automatically = true; // MOVE SL AUTOMATICALLY
input bool  Move_TP_to_Breakeven = true; //MOVE TP TO BREAKEVEN


input int slippage = 2; //SLIPPAGE
input int stoploss = 100; // SL IN POINT
input int takeprofit = 100; // SL IN POINT
extern string  h1i                   = "===Time Management System==="; // =========Monday==========
input  Answer   SET_TRADING_DAYS     = no;
input  DYS_WEEK EA_START_DAY        = Sunday;//Starting Day
input string EA_START_TIME          = "22:00";
input DYS_WEEK EA_STOP_DAY          = Friday;//Ending Day
input string EA_STOP_TIME          = "22:00";
input string fsiz;//FIXED SIZE PARAMS
input double lotSize = 0.01; //FIXED SIZE
input string sddd; //MATINGALE PARAMS
input   double MM_Martingale_Start = 0.01;
input double MM_Martingale_ProfitFactor = 1;
input double MM_Martingale_LossFactor = 2;
input bool MM_Martingale_RestartProfit = true;
input bool MM_Martingale_RestartLoss = false;
input int MM_Martingale_RestartLosses = 1000;
input int MM_Martingale_RestartProfits = 1000;
input string psds;//POSITION SIZE PARAMS
input double MM_PositionSizing = 10000;
  bool Now;
  long InpChannelChatID=ChatID;
  input bool sendnews;
  bool NewsFilter;
  bool Signal;
  
  
  bool Vlow=0, Vhigh,Vmedium;
  input int  BeforeNewsStop;
  
  input int AfterNewsStop=60;
 int MinAfter=AfterNewsStop;
  input int MinBefore=60;
  input bool DrawLines =true;
  int Style=0;
  int NomNews=0;
  bool judulnews; datetime LastUpd,Upd;
  input bool Allow_pen_orders=true; // Allows placement of pending orders
input bool Set_SL = true; // Allows input of StopLoss for active orders before execution
input bool Set_TP = true; // Allows input of TakeProfit for active orders before execution
input bool Display_legend=true; // Allows display of action commands



input int text_size=12;
input color text_color=clrYellowGreen;
input int right_edge_shift = 10;
input int upper_edge_shift = 20;
//+------------------------------------------------------------------+
//| Pre-Defined Value Auto                                           |
//+------------------------------------------------------------------+

int gStopLevel = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
int gFreezeLevel =(int) MarketInfo(Symbol(), MODE_FREEZELEVEL);
string DemoRealCheck = IsDemo() ? "Demo" : "Live";

int gSpread;

string cTrailingType;
  double Lots = GetLotSize( money_management);
  
  
  //+------------------------------------------------------------------+
//|                                                  decryptuser.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <DiscordTelegram/license.mqh>

#include <DiscordTelegram/User.mqh>

CLic nl;
void encrypUser()
  {
      user_lic ul;
      ul.uid = 123;
      ul.expired = D'2025.06.01 12:30:27';
      ul.AddLogin(AccountInfoInteger(ACCOUNT_LOGIN));   
      ul.AddLogin(3072021);
      ul.ea_count = 2;
      
      ea_user e1, e2;
      e1.SetEAname(AccountInfoString(ACCOUNT_NAME));
      e2.SetEAname("NY cool bot v.6.0");
      e2.expired = D'2025.05.28 12:30:27';
      datetime expr=D'2025.05.28 12:30:27';
      
      CLic cl;
      cl.SetUser(ul);
      cl.AddEA(e1);
      cl.AddEA(e2);
      createObject(ChartID(),OBJ_LABEL,0,400,10,"license");
      
      ObjectSetText("license","   License Exp:"+ TimeToStr(e2.expired) ,12,NULL,clrYellow);
      string k =license_key;
      ENUM_CRYPT_METHOD m = CRYPT_AES128;
      
      Print("Create license",CreateLic(m, k, cl, "license.txt"));

  }
  
  
  bool decryptUser()
  {
      
     
      
      string k = license_key;
      ENUM_CRYPT_METHOD m = CRYPT_AES128;
            
      Print("Read license: ",ReadLic(m, k, nl, "license.txt"));

      user_lic ul1;
      nl.GetUser(ul1);
      ea_user e3;
      nl.GetEA(1, e3);

      Print("acc: ",ul1.log_count);
      for(int i =0; i < ul1.log_count; i++) {
         Print(i," ",ul1.logins[i]);
      }
      
      Print("ea count:", ul1.ea_count);
      for(int i = 0; i < ul1.ea_count; i++){
         nl.GetEA(i, e3);
         Print(e3.GetEAname()," ",e3.IsExpired() );
      }
/************************************* SHA256 ************************************/      
      uchar key[], result[], enc[];
      StringToCharArray(k, enc);
//      for(int i = 0; i < ArraySize(enc); i++) PrintFormat("%d   %X ",i, enc[i]);
      int sha = CryptEncode(CRYPT_HASH_SHA256,enc,key,result);   
      string sha256;
      for(int i = 0; i < sha; i++) sha256 += StringFormat("%X ",result[i]);
      Print("SHA256 len: ",sha," Value:  ",sha256);
      int h = FileOpen("sha256.bin", FILE_WRITE | FILE_BIN);
      if (h == INVALID_HANDLE) {
         Print("File create failed: sha256.bin");
      }else {
         FileWriteArray(h, result);
         FileClose(h);            
      }     
      
   return   ReadLic(m, k, nl, "license.txt"); 
  }
//+------------------------------------------------------------------+

  
  // Define a struct to hold account information
struct AccountInfo {
    double balance;
    double equity;
    double margin;
    double freeMargin;
    double marginLevel;
};

// Function to fetch and return account information
AccountInfo GetAccountInfo() {
    AccountInfo info;
    info.balance = AccountBalance();
    info.equity = AccountEquity();
    info.margin = AccountMargin();
    info.freeMargin = AccountFreeMargin();
    info.marginLevel = AccountLeverage();
    return info;
}

// Function to print account information to the Experts tab
string  AccountInfos() {
    AccountInfo info = GetAccountInfo();
  string  print;
  print=("Account Balance: "+ info.balance);
    print+=("Account Equity: "+ info.equity);
    print+=("Account Margin: "+ info.margin);
    print+=("Account Free Margin: "+info.freeMargin);
    print+=("Account Margin Level: "+ info.marginLevel);
    return print;
}

// Function to modify account parameters
bool ModifyAccountParameters(double leverage, double stopOutLevel) {
    // Check if modification is allowed based on trading conditions
    if (!IsTradeAllowed()) {
        Print("Trading is not allowed at the moment.");
        return false;
    }

 

    Print("Account parameters updated successfully.");
    return true;
}
