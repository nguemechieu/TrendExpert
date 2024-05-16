/*------------------------------------------------------------------------------

	TrendExpert
	
	Copyright (c) 2021-2024, TradeAdviser
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification,
	are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in 
      the documentation and/or other materials provided with the distribution.
    * The name of the MQLTools may not be used to endorse or promote products
      derived from this software without specific prior written permission.
		
	THIS SOFTWARE IS PROVIDED BY THE MQLTOOLS "AS IS" AND ANY EXPRESS
	OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
	IN NO EVENT SHALL THE MQLTOOLS BE LIABLE FOR ANY DIRECT, INDIRECT,
	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
	POSSIBILITY OF SUCH DAMAGE.
	
------------------------------------------------------------------------------*/

#property copyright "© 2021-2024 NGUEMECHIEU NOEL MARTIAL"
#property link      "https://www.github.com/nguemechieu/TrendExpert"
#property  strict
#property  version "1.2"
#property indicator_chart_window

#include <stdlib.mqh>
#include <WinUser32.mqh>

//#property indicator_buffers 5

#property indicator_color1 SkyBlue		// buy sig.
#property indicator_color2 OrangeRed	// sell sig.
#property indicator_color3 SkyBlue		// buy exit sig.
#property indicator_color4 OrangeRed	// sell exit sig.
#property indicator_color5 Gold			// SL values

#property indicator_width1 3
#property indicator_width2 3
#property indicator_width3 3
#property indicator_width4 3
#property indicator_width5 1


#property indicator_chart_window
#property indicator_buffers 8
#property indicator_color1 Red
#property indicator_color2 Red
#property indicator_color3 DodgerBlue
#property indicator_color4 DodgerBlue
#include <DiscordTelegram/CMyBot.mqh>


input int BackLimit=5000;

 string pus1="/////////////////////////////////////////////////";
 bool zone_show_weak=false;
 bool zone_show_untested = false;
 bool zone_show_turncoat = false;
 double zone_fuzzfactor=0.75;

 string pus2="/////////////////////////////////////////////////";
 bool fractals_show=false;
 double fractal_fast_factor = 3.0;
 double fractal_slow_factor = 6.0;
 bool SetGlobals=true;

 string pus3="/////////////////////////////////////////////////";
 bool zone_solid=true;
 int zone_linewidth=1;
 int zone_style=0;
 bool zone_show_info=false;
 int zone_label_shift=4;
 bool zone_merge=true;
 bool zone_extend=true;

extern string pus4="/////////////////////////////////////////////////";
extern bool zone_show_alerts  = false;
extern bool zone_alert_popups = true;
extern bool zone_alert_sounds = true;
extern int zone_alert_waitseconds=300;

 string pus5="/////////////////////////////////////////////////";
 int Text_size=8;
 string Text_font = "Courier New";
 color Text_color = White;
 string sup_name = "Sup";
 string res_name = "Res";
 string test_name= "Retests";
 color color_support_weak     = DarkSlateGray;
 color color_support_untested = SeaGreen;
 color color_support_verified = Green;
 color color_support_proven   = LimeGreen;
 color color_support_turncoat = OliveDrab;
 color color_resist_weak      = Indigo;
 color color_resist_untested  = Orchid;
 color color_resist_verified  = Crimson;
color color_resist_proven    = Red;
 color color_resist_turncoat  = DarkOrange;

double FastDnPts[],FastUpPts[];
double SlowDnPts[],SlowUpPts[];

double zone_hi[1000],zone_lo[1000];
int    zone_start[1000],zone_hits[1000],zone_type[1000],zone_strength[1000],zone_count=0;
bool   zone_turn[1000];

#define ZONE_SUPPORT 1
#define ZONE_RESIST  2

#define ZONE_WEAK      0
#define ZONE_TURNCOAT  1
#define ZONE_UNTESTED  2
#define ZONE_VERIFIED  3
#define ZONE_PROVEN    4

#define UP_POINT 1
#define DN_POINT -1

int time_offset=0;

double ner_lo_zone_P1[];
double ner_lo_zone_P2[];
double ner_hi_zone_P1[];
double ner_hi_zone_P2[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int inits()
  {
   IndicatorBuffers(4);

   SetIndexBuffer(0,SlowDnPts);
   SetIndexBuffer(1,SlowUpPts);
   SetIndexBuffer(2,FastDnPts);
   SetIndexBuffer(3,FastUpPts);

   if(fractals_show==true)
     {
      SetIndexStyle(0,DRAW_ARROW,0,3);
      SetIndexStyle(1,DRAW_ARROW,0,3);
      SetIndexStyle(2,DRAW_ARROW,0,1);
      SetIndexStyle(3,DRAW_ARROW,0,1);
      SetIndexArrow(0,218);
      SetIndexArrow(1,217);
      SetIndexArrow(2,218);
      SetIndexArrow(3,217);
     }
   else
     {
      SetIndexStyle(0,DRAW_NONE);
      SetIndexStyle(1,DRAW_NONE);
      SetIndexStyle(2,DRAW_NONE);
      SetIndexStyle(3,DRAW_NONE);
     }

   SetIndexBuffer(4,ner_hi_zone_P1);
   SetIndexBuffer(5,ner_hi_zone_P2);
   SetIndexBuffer(6,ner_lo_zone_P1);
   SetIndexBuffer(7,ner_lo_zone_P2);

   SetIndexStyle(4,DRAW_NONE);
   SetIndexStyle(5,DRAW_NONE);
   SetIndexStyle(6,DRAW_NONE);
   SetIndexStyle(7,DRAW_NONE);

   SetIndexLabel(4,"ner up zone P1");
   SetIndexLabel(5,"ner up zone P2");
   SetIndexLabel(6,"ner dn zone P1");
   SetIndexLabel(7,"ner dn zone P2");

   IndicatorDigits(Digits);

   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit()
  {
   DeleteZones();
   DeleteGlobalVars();
   deinits();
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int starts()
  {
   if(NewBar()==true)
     {
      int old_zone_count=zone_count;

      FastFractals();
      SlowFractals();
      DeleteZones();
      FindZones();
      DrawZones();
      if(zone_count<old_zone_count)
         DeleteOldGlobalVars(old_zone_count);
     }

   if(zone_show_info==true)
     {
      for(int i=0; i<zone_count; i++)
        {
         string lbl;
         if(zone_strength[i]==ZONE_PROVEN)
            lbl="Proven";
         else if(zone_strength[i]==ZONE_VERIFIED)
            lbl="Verified";
         else if(zone_strength[i]==ZONE_UNTESTED)
            lbl="Untested";
         else if(zone_strength[i]==ZONE_TURNCOAT)
            lbl="Turncoat";
         else
            lbl="Weak";

         if(zone_type[i]==ZONE_SUPPORT)
            lbl=lbl+" "+sup_name;
         else
            lbl=lbl+" "+res_name;

         if(zone_hits[i]>0 && zone_strength[i]>ZONE_UNTESTED)
           {
            if(zone_hits[i]==1)
               lbl=lbl+", "+test_name+"="+zone_hits[i];
            else
               lbl=lbl+", "+test_name+"="+zone_hits[i];
           }

         int adjust_hpos;
         int wbpc=WindowBarsPerChart();
         int k=Period()*60+(20+StringLen(lbl));

         if(wbpc<80)
            adjust_hpos=Time[0]+k*4;
         else if(wbpc<125)
            adjust_hpos=Time[0]+k*8;
         else if(wbpc<250)
            adjust_hpos=Time[0]+k*15;
         else if(wbpc<480)
            adjust_hpos=Time[0]+k*29;
         else if(wbpc<950)
            adjust_hpos=Time[0]+k*58;
         else
            adjust_hpos=Time[0]+k*115;

         //

         int shift=k*zone_label_shift;
         double vpos=zone_hi[i]-(zone_hi[i]-zone_lo[i])/2;

         if(zone_strength[i]==ZONE_WEAK && zone_show_weak==false)
            continue;
         if(zone_strength[i]==ZONE_UNTESTED && zone_show_untested==false)
            continue;
         if(zone_strength[i]==ZONE_TURNCOAT && zone_show_turncoat==false)
            continue;

         string s="SSSR#"+i+"LBL";
         ObjectCreate(s,OBJ_TEXT,0,0,0);
         ObjectSet(s,OBJPROP_TIME1,adjust_hpos+shift);
         ObjectSet(s,OBJPROP_PRICE1,vpos);
         ObjectSetText(s,StringRightPad(lbl,36," "),Text_size,Text_font,Text_color);
        }
     }

   CheckAlerts();

   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckAlerts()
  {
   static int lastalert=0;

   if(zone_show_alerts==false)
      return;

   if(Time[0]-lastalert>zone_alert_waitseconds)
      if(CheckEntryAlerts()==true)
         lastalert=Time[0];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckEntryAlerts()
  {
// check for entries
   for(int i=0; i<zone_count; i++)
     {
      if(Close[0]>=zone_lo[i] && Close[0]<zone_hi[i])
        {
         if(zone_show_alerts==true)
           {
            if(zone_alert_popups==true)
              {
               if(zone_type[i]==ZONE_SUPPORT)
                  Alert(Symbol()+TimeFrameToString(Period())+": Support Zone Entered");
               else
                  Alert(Symbol()+TimeFrameToString(Period())+": Resistance Zone Entered");
              }

            if(zone_alert_sounds==true)
               PlaySound("alert_wav");
           }

         return(true);
        }
     }

   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteGlobalVars()
  {
   if(SetGlobals==false)
      return;

   GlobalVariableDel("SSSR_Count_"+Symbol()+(string)Period());
   GlobalVariableDel("SSSR_Updated_"+Symbol()+(string)Period());

   int old_count=zone_count;
   zone_count=0;
   DeleteOldGlobalVars(old_count);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteOldGlobalVars(int old_count)
  {
   if(SetGlobals==false)
      return;

   for(int i=zone_count; i<old_count; i++)
     {
      GlobalVariableDel("SSSR_HI_"+Symbol()+Period()+i);
      GlobalVariableDel("SSSR_LO_"+Symbol()+Period()+i);
      GlobalVariableDel("SSSR_HITS_"+Symbol()+Period()+i);
      GlobalVariableDel("SSSR_STRENGTH_"+Symbol()+Period()+i);
      GlobalVariableDel("SSSR_AGE_"+Symbol()+Period()+i);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int bustcount=0,testcount=0;
   double hival,loval;
   bool turned=false,hasturned=false;

   double temp_hi[],temp_lo[];
   int    temp_start[],temp_hits[],temp_strength[],temp_count=0;
   bool   temp_turn[],temp_merge[];
   int merge1[],merge2[],merge_count=0;

void FindZones()
  {
           ArrayResize( temp_turn,Bars+1,0);
                    ArrayResize( temp_merge,Bars+1,0);
                        ArrayResize( temp_hits,Bars+1,0);
                            ArrayResize( temp_start,Bars+1,0);
                                ArrayResize( temp_hi,Bars+1,0);
                                
                                   ArrayResize( temp_lo,Bars+1,0);
                                    ArrayResize( temp_strength,Bars+1,0);
                                    
                                  
                                    ArrayResize( temp_merge,Bars+1,0);
                                    
                                      ArrayResize( temp_hi,Bars+1,0);
                                        ArrayResize( temp_lo,Bars+1,0);
                  
       
// iterate through zones from oldest to youngest (ignore recent 5 bars),
// finding those that have survived through to the present___
   for(int shift=MathMin(Bars-1,BackLimit); shift>5; shift--)
     {
      double atr= iATR(NULL,0,7,shift);
      double fu = atr/2 * zone_fuzzfactor;
      bool isWeak;
      bool touchOk= false;
      bool isBust = false;

      if(FastUpPts[shift]>0.001)
        {
         // a zigzag high point
         isWeak=true;
         if(SlowUpPts[shift]>0.001)
            isWeak=false;

         hival=High[shift];
         if(zone_extend==true)
            hival+=fu;

         loval=MathMax(MathMin(Close[shift],High[shift]-fu),High[shift]-fu*2);
         turned=false;
         hasturned=false;
         isBust=false;

         bustcount = 0;
         testcount = 0;

         for(int i=shift-1; i>=0; i--)
           {
            if((turned==false && FastUpPts[i]>=loval && FastUpPts[i]<=hival) || 
               (turned==true && FastDnPts[i]<=hival && FastDnPts[i]>=loval))
              {
               // Potential touch, just make sure its been 10+candles since the prev one
               touchOk=true;
               for(int j=i+1; j<i+11; j++)
                 {
                  if((turned==false && FastUpPts[j]>=loval && FastUpPts[j]<=hival) || 
                     (turned==true && FastDnPts[j]<=hival && FastDnPts[j]>=loval))
                    {
                     touchOk=false;
                     break;
                    }
                 }

               if(touchOk==true)
                 {
                  // we have a touch_  If its been busted once, remove bustcount
                  // as we know this level is still valid & has just switched sides
                  bustcount=0;
                  testcount++;
                 }
              }

            if((turned==false && High[i]>hival) || 
               (turned==true && Low[i]<loval))
              {
               // this level has been busted at least once
               bustcount++;

               if(bustcount>1 || isWeak==true)
                 {
                  // busted twice or more
                  isBust=true;
                  break;
                 }

               if(turned == true)
                  turned = false;
               else if(turned==false)
                  turned=true;

               hasturned=true;

               // forget previous hits
               testcount=0;
              }
           }

         if(isBust==false)
           {
            // level is still valid, add to our list
            
          ArrayResize( temp_merge, temp_count+Bars,0);
          
          ArrayResize( temp_lo, temp_count+Bars,0);
          
          ArrayResize( temp_turn, temp_count+Bars+1,0);
          
          ArrayResize( temp_hits, temp_count+Bars,0);
          
          ArrayResize( temp_start, temp_count+Bars,0);
          
          ArrayResize( temp_strength, temp_count+Bars,0);
          
     
          ArrayResize( temp_hi, temp_count+Bars,0);
            temp_hi[temp_count] = hival;
            temp_lo[temp_count] = loval;
            temp_turn[temp_count] = hasturned;
            temp_hits[temp_count] = testcount;
            temp_start[temp_count] = shift;
            temp_merge[temp_count] = false;

            if(testcount>3)
               temp_strength[temp_count]=ZONE_PROVEN;
            else if(testcount>0)
               temp_strength[temp_count]=ZONE_VERIFIED;
            else if(hasturned==true)
               temp_strength[temp_count]=ZONE_TURNCOAT;
            else if(isWeak==false)
               temp_strength[temp_count]=ZONE_UNTESTED;
            else
               temp_strength[temp_count]=ZONE_WEAK;

            temp_count++;
           }
        }
      else if(FastDnPts[shift]>0.001)
        {
         // a zigzag low point
         isWeak=true;
         if(SlowDnPts[shift]>0.001)
            isWeak=false;

         loval=Low[shift];
         if(zone_extend==true)
            loval-=fu;

         hival=MathMin(MathMax(Close[shift],Low[shift]+fu),Low[shift]+fu*2);
         turned=false;
         hasturned=false;

         bustcount = 0;
         testcount = 0;
         isBust=false;

         for(int i=shift-1; i>=0; i--)
           {
            if((turned==true && FastUpPts[i]>=loval && FastUpPts[i]<=hival) || 
               (turned==false && FastDnPts[i]<=hival && FastDnPts[i]>=loval))
              {
               // Potential touch, just make sure its been 10+candles since the prev one
               touchOk=true;
               for(int j=i+1; j<i+11; j++)
                 {
                  if((turned==true && FastUpPts[j]>=loval && FastUpPts[j]<=hival) || 
                     (turned==false && FastDnPts[j]<=hival && FastDnPts[j]>=loval))
                    {
                     touchOk=false;
                     break;
                    }
                 }

               if(touchOk==true)
                 {
                  // we have a touch_  If its been busted once, remove bustcount
                  // as we know this level is still valid & has just switched sides
                  bustcount=0;
                  testcount++;
                 }
              }

            if((turned==true && High[i]>hival) || 
               (turned==false && Low[i]<loval))
              {
               // this level has been busted at least once
               bustcount++;

               if(bustcount>1 || isWeak==true)
                 {
                  // busted twice or more
                  isBust=true;
                  break;
                 }

               if(turned == true)
                  turned = false;
               else if(turned==false)
                  turned=true;

               hasturned=true;

               // forget previous hits
               testcount=0;
              }
           }

         if(isBust==false)
           {
             ArrayResize( temp_hi,Bars+temp_count,0);
             
             ArrayResize( temp_lo,Bars+temp_count,0);
             
             ArrayResize( temp_hits,Bars+temp_count,0);
             
             ArrayResize( temp_merge,Bars+temp_count,0);
             
             ArrayResize( temp_start,Bars+temp_count,0);
   
       
            temp_hi[temp_count] = hival;
            temp_lo[temp_count] = loval;
            temp_turn[temp_count] = hasturned;
            temp_hits[temp_count] = testcount;
            temp_start[temp_count] = shift;
            temp_merge[temp_count] = false;

            if(testcount>3)
               temp_strength[temp_count]=ZONE_PROVEN;
            else if(testcount>0)
               temp_strength[temp_count]=ZONE_VERIFIED;
            else if(hasturned==true)
               temp_strength[temp_count]=ZONE_TURNCOAT;
            else if(isWeak==false)
               temp_strength[temp_count]=ZONE_UNTESTED;
            else
               temp_strength[temp_count]=ZONE_WEAK;

            temp_count++;
           }
        }
     }

// look for overlapping zones___
   if(zone_merge==true)
     {
      merge_count=1;         int j=0;
      int iterations=0;
      while(merge_count>0 && iterations<3)
        {
         merge_count=0;
         iterations++;

         for(int i=0; i<temp_count; i++)
            temp_merge[i]=false;

         for(int i=0; i<temp_count-1; i++)
           {
            if(temp_hits[i]==-1 || temp_merge[j]==true)
               continue;
               


            for(j=i+1; j<temp_count; j++)
              {
               if(temp_hits[j]==-1 || temp_merge[j]==true)
                  continue;

               if((temp_hi[i]>=temp_lo[j] && temp_hi[i]<=temp_hi[j]) || 
                  (temp_lo[i] <= temp_hi[j] && temp_lo[i] >= temp_lo[j]) ||
                  (temp_hi[j] >= temp_lo[i] && temp_hi[j] <= temp_hi[i]) ||
                  (temp_lo[j] <= temp_hi[i] && temp_lo[j] >= temp_lo[i]))
                 {
                   ArrayResize( merge1,Bars+merge_count,0);
                                    ArrayResize( merge2,Bars+merge_count,0);
                  merge1[merge_count] = i;
                  merge2[merge_count] = j;
                  temp_merge[i] = true;
                  temp_merge[j] = true;
                  merge_count++;
                 }
              }
           }

         // ___ and merge them ___
         for(int i=0; i<merge_count; i++)
           {
            int target = merge1[i];
            int source = merge2[i];

            temp_hi[target] = MathMax(temp_hi[target], temp_hi[source]);
            temp_lo[target] = MathMin(temp_lo[target], temp_lo[source]);
            temp_hits[target] += temp_hits[source];
            temp_start[target] = MathMax(temp_start[target], temp_start[source]);
            temp_strength[target]=MathMax(temp_strength[target],temp_strength[source]);
            if(temp_hits[target]>3)
               temp_strength[target]=ZONE_PROVEN;

            if(temp_hits[target]==0 && temp_turn[target]==false)
              {
               temp_hits[target]=1;
               if(temp_strength[target]<ZONE_VERIFIED)
                  temp_strength[target]=ZONE_VERIFIED;
              }

            if(temp_turn[target] == false || temp_turn[source] == false)
               temp_turn[target] = false;
            if(temp_turn[target] == true)
               temp_hits[target] = 0;

            temp_hits[source]=-1;
           }
        }
     }

// copy the remaining list into our official zones arrays
   zone_count=0;
   for(int i=0; i<temp_count; i++)
     {
      if(temp_hits[i]>=0 && zone_count<Bars)
        {
         zone_hi[zone_count]       = temp_hi[i];
         zone_lo[zone_count]       = temp_lo[i];
         zone_hits[zone_count]     = temp_hits[i];
         zone_turn[zone_count]     = temp_turn[i];
         zone_start[zone_count]    = temp_start[i];
         zone_strength[zone_count] = temp_strength[i];

         if(zone_hi[zone_count]<Close[4])
            zone_type[zone_count]=ZONE_SUPPORT;
         else if(zone_lo[zone_count]>Close[4])
            zone_type[zone_count]=ZONE_RESIST;
         else
           {
            for(int j=5; j<Bars-5; j++)
              {
               if(Close[j]<zone_lo[zone_count])
                 {
                  zone_type[zone_count]=ZONE_RESIST;
                  break;
                 }
               else if(Close[j]>zone_hi[zone_count])
                 {
                  zone_type[zone_count]=ZONE_SUPPORT;
                  break;
                 }
              

            if(j==BarsBack)
               zone_type[zone_count]=ZONE_SUPPORT;
           }
}
         zone_count++;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawZones()
  {
   double lower_nerest_zone_P1=0;
   double lower_nerest_zone_P2=0;
   double higher_nerest_zone_P1=EMPTY_VALUE;
   double higher_nerest_zone_P2=EMPTY_VALUE;
   
    ArrayResize(  ner_hi_zone_P1,Bars+1,0);
    ArrayResize(  ner_hi_zone_P2,Bars+1,0);
      ArrayResize(  zone_hi,Bars+1,0);
        ArrayResize(  zone_start,Bars+1,0);
          ArrayResize(  zone_strength,Bars+1,0);
            ArrayResize(  zone_type,Bars+1,0);

   if(SetGlobals==true)
     {
      GlobalVariableSet("SSSR_Count_"+Symbol()+Period(),zone_count);
      GlobalVariableSet("SSSR_Updated_"+Symbol()+Period(),TimeCurrent());
     }

   for(int i=0; i<zone_count; i++)
     {
      if(zone_strength[i]==ZONE_WEAK && zone_show_weak==false)
         continue;

      if(zone_strength[i]==ZONE_UNTESTED && zone_show_untested==false)
         continue;

      if(zone_strength[i]==ZONE_TURNCOAT && zone_show_turncoat==false)
    
    
         continue;

string s="";
      //name sup
      if(zone_type[i]==ZONE_SUPPORT)
         string s="SSSR#S"+i+" Strength=";
      else
      //name res
      s="SSSR#R"+i+" Strength=";

      if(zone_strength[i]==ZONE_PROVEN)
         s=s+"Proven, Test Count="+zone_hits[i];
      else if(zone_strength[i]==ZONE_VERIFIED)
         s=s+"Verified, Test Count="+zone_hits[i];
      else if(zone_strength[i]==ZONE_UNTESTED)
         s=s+"Untested";
      else if(zone_strength[i]==ZONE_TURNCOAT)
         s=s+"Turncoat";
      else
         s=s+"Weak";

  ArrayResize(  zone_lo,Bars+1,0); 
      ObjectCreate(s,OBJ_RECTANGLE,0,0,0,0,0);
      ObjectSet(s,OBJPROP_TIME1,Time[zone_start[i]]);
      ObjectSet(s,OBJPROP_TIME2,Time[0]);
      ObjectSet(s,OBJPROP_PRICE1,zone_hi[i]);
      ObjectSet(s,OBJPROP_PRICE2,zone_lo[i]);
      ObjectSet(s,OBJPROP_BACK,zone_solid);
      ObjectSet(s,OBJPROP_WIDTH,zone_linewidth);
      ObjectSet(s,OBJPROP_STYLE,zone_style);

      if(zone_type[i]==ZONE_SUPPORT)
        {
         // support zone
         if(zone_strength[i]==ZONE_TURNCOAT)
            ObjectSet(s,OBJPROP_COLOR,color_support_turncoat);
         else if(zone_strength[i]==ZONE_PROVEN)
            ObjectSet(s,OBJPROP_COLOR,color_support_proven);
         else if(zone_strength[i]==ZONE_VERIFIED)
            ObjectSet(s,OBJPROP_COLOR,color_support_verified);
         else if(zone_strength[i]==ZONE_UNTESTED)
            ObjectSet(s,OBJPROP_COLOR,color_support_untested);
         else
            ObjectSet(s,OBJPROP_COLOR,color_support_weak);
        }
      else
        {
         // resistance zone
         if(zone_strength[i]==ZONE_TURNCOAT)
            ObjectSet(s,OBJPROP_COLOR,color_resist_turncoat);
         else if(zone_strength[i]==ZONE_PROVEN)
            ObjectSet(s,OBJPROP_COLOR,color_resist_proven);
         else if(zone_strength[i]==ZONE_VERIFIED)
            ObjectSet(s,OBJPROP_COLOR,color_resist_verified);
         else if(zone_strength[i]==ZONE_UNTESTED)
            ObjectSet(s,OBJPROP_COLOR,color_resist_untested);
         else
            ObjectSet(s,OBJPROP_COLOR,color_resist_weak);
        }


      if(SetGlobals==true)
        {
         GlobalVariableSet("SSSR_HI_"+Symbol()+Period()+i,zone_hi[i]);
         GlobalVariableSet("SSSR_LO_"+Symbol()+Period()+i,zone_lo[i]);
         GlobalVariableSet("SSSR_HITS_"+Symbol()+Period()+i,zone_hits[i]);
         GlobalVariableSet("SSSR_STRENGTH_"+Symbol()+Period()+i,zone_strength[i]);
         GlobalVariableSet("SSSR_AGE_"+Symbol()+Period()+i,zone_start[i]);
        }

      //nearest zones
      if(zone_lo[i]>lower_nerest_zone_P2 && Bid>zone_lo[i]) {lower_nerest_zone_P1=zone_hi[i];lower_nerest_zone_P2=zone_lo[i];}
      if(zone_hi[i]<higher_nerest_zone_P1 && Bid<zone_hi[i]) {higher_nerest_zone_P1=zone_hi[i];higher_nerest_zone_P2=zone_lo[i];}
     }
 
 
 
 
   ner_hi_zone_P1[0]=higher_nerest_zone_P1;
   
   ner_hi_zone_P2[0]=higher_nerest_zone_P2;
   ner_lo_zone_P1[0]=lower_nerest_zone_P1;
   ner_lo_zone_P2[0]=lower_nerest_zone_P2;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Fractal(int M,int xP,int xshift)
  {
   if(Period()>xP)
      xP=Period();

   xP=(int)(xP/Period()*2+MathCeil(xP/Period()/2));

   if(xshift<xP)
      return(false);

   if(xshift>Bars-xP)
      return(false);

   for(int i=1; i<=xP; i++)
     {
      if(M==UP_POINT)
        {
         if(High[xshift+i]>High[xshift])
            return(false);
         if(High[xshift-i]>=High[xshift])
            return(false);
        }
      if(M==DN_POINT)
        {
         if(Low[xshift+i]<Low[xshift])
            return(false);
         if(Low[xshift-i]<=Low[xshift])
            return(false);
        }
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FastFractals()
  {
  ArrayResize(  FastUpPts,Bars+1,0);  ArrayResize(  FastDnPts,Bars+1,0);
 
   int limit=MathMin(Bars-1,BackLimit);
   int P=(int)(Period()*fractal_fast_factor);

   FastUpPts[0] = 0.0; FastUpPts[1] = 0.0;
   FastDnPts[0] = 0.0; FastDnPts[1] = 0.0;

   for(int shift=limit; shift>1; shift--)
     {
      if(Fractal(UP_POINT,P,shift)==true)
         FastUpPts[shift]=High[shift];
      else
         FastUpPts[shift]=0.0;

      if(Fractal(DN_POINT,P,shift)==true)
         FastDnPts[shift]=Low[shift];
      else
         FastDnPts[shift]=0.0;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SlowFractals()
  {
  
   int limit=MathMin(Bars-1,BackLimit);
   int P=(int)(Period()*fractal_slow_factor);
  ArrayResize(  SlowDnPts,Bars+1,0);
    ArrayResize(  SlowUpPts,Bars+1,0);
 
 
   SlowUpPts[0] = 0.0; SlowUpPts[1] = 0.0;
   SlowDnPts[0] = 0.0; SlowDnPts[1] = 0.0;

   for(int shift=limit; shift>1; shift--)
     {
      if(Fractal(UP_POINT,P,shift)==true)
         SlowUpPts[shift]=High[shift];
      else
         SlowUpPts[shift]=0.0;

      if(Fractal(DN_POINT,P,shift)==true)
         SlowDnPts[shift]=Low[shift];
      else
         SlowDnPts[shift]=0.0;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBar()
  {
   static datetime LastTime=0;
   if(iTime(Symbol(),Period(),0)+time_offset!=LastTime)
     {
      LastTime=iTime(Symbol(),Period(),0)+time_offset;
      return (true);
     }
   else
      return (false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteZones()
  {
   int len=5;
 int i=0;

   while(i<ObjectsTotal())
     {
      string objName=ObjectName(i);
      if(StringSubstr(objName,0,len)!="SSSR#")
        {
         i++;
         continue;
        }
      ObjectDelete(objName);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TimeFrameToString(int tf) //code by TRO
  {
   string tfs;

   switch(tf)
     {
      case PERIOD_M1:
         tfs="M1";
         break;
      case PERIOD_M5:
         tfs="M5";
         break;
      case PERIOD_M15:
         tfs="M15";
         break;
      case PERIOD_M30:
         tfs="M30";
         break;
      case PERIOD_H1:
         tfs="H1";
         break;
      case PERIOD_H4:
         tfs="H4";
         break;
      case PERIOD_D1:
         tfs="D1";
         break;
      case PERIOD_W1:
         tfs="W1";
         break;
      case PERIOD_MN1:
         tfs="MN";
     }

   return(tfs);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string StringRepeat(string str,int n=1)
  {
   string outstr="";
   for(int i=0; i<n; i++) outstr=outstr+str;
   return(outstr);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string StringRightPad(string str,int n=1,string str2=" ")
  {
   return(str + StringRepeat(str2,n-StringLen(str)));
  }
//+------------------------------------------------------------------+



















// EXTERN variables

// MAs

extern int MAFastBars 	= 10;
extern int MAFastType 	= MODE_EMA;
extern int MAFastPrice 	= PRICE_WEIGHTED;
extern int MASlowBars 	= 30;
extern int MASlowType 	= MODE_SMMA;
extern int MASlowPrice 	= PRICE_WEIGHTED;		


// SL (Chandelier)

extern int ChandBars 		= 7;				
extern double ChandATRFact = 2.0;	

	// risk for lot calculation according to the SL (for manual trading info)
extern bool UseSoundAlert = true;
extern bool UsePopupAlert = true;
extern bool WriteToLog = false;
// CONSTs

#define	TRADE_BUY					1
#define	TRADE_SELL					-1
#define	TRADE_NO_SIGNAL			0
#define	TRADE_EXIT_BUY				5
#define	TRADE_EXIT_SELL			-5

// BUFFERs

double dBufBuy[], dBufSell[], dBufExitBuy[], dBufExitSell[], dBufSL[];

// GLOBALNE variables
input

string	ObjPref = "TrendExpertInd_1";					// prefix for this indicator's objects

bool	BuyActive = false, SellActive = false;
double StartPrice, StartSpread;
datetime StartTime;								// for risk calculation (using first SL)

bool FirstDisplay = false;

double MinSLDistance = 0.0;
input
string	IndName = "TrendExpert";
// utils
 string logfile=IndName+".txt";
int LogHandle;
double dblPoint;
int iDigits;
 int  offsets=10;
input int BarsBack=2000;
input int RiskPercent=2;
bool AlertSound;

//--------------------------------------------------------------------------------------
// DrawFixedLbl
//--------------------------------------------------------------------------------------

void DrawFixedLbl(string OName, string Capt, int Corner, int DX, int DY, int FSize, string Font, color FColor, bool BG)
{
   if (ObjectFind(OName) < 0)
   	ObjectCreate(OName, OBJ_LABEL, 0, 0, 0);
   
   ObjectSet(OName, OBJPROP_CORNER, Corner);
   ObjectSet(OName, OBJPROP_XDISTANCE, DX);
   ObjectSet(OName, OBJPROP_YDISTANCE, DY);
   ObjectSet(OName,OBJPROP_BACK, BG);      
   
   if (Capt == "" || Capt == "Label") Capt = " ";

   ObjectSetText(OName, Capt, FSize, Font, FColor);
}

//--------------------------------------------------------------------------------------
// LogWrite
//--------------------------------------------------------------------------------------

void LogWrite(int xi, string sText) 
{
int h=FileOpen(logfile

,FILE_WRITE|FILE_ANSI|FILE_CSV,";");
///'s write to the file ten lines with three fields per line:

   for(int i=1;i<=10;i++){
      string str="Line-"+IntegerToString(xi)+"-";
      FileWrite(h,str+"1",str+"2",str+"3");
   

	if ( (!WriteToLog) || (h < 1) )
		return;

	if (h== 0){
	
		FileWrite(h, TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS) + ": " + sText);}
	else
		FileWrite(h, TimeToStr(Time[i], TIME_DATE | TIME_SECONDS) + ": " + sText);  

	FileFlush(h);
	}
	FileClose(h);
}




//-----------------------------------------------------------------------------
// INIT
//-----------------------------------------------------------------------------

int init()
{
inits();
 ChartColorSet();
   init_error = bot.Token(InpToken);


//--- set token

//--- check token
   int   getme_result=bot.GetMe();

//--- set language
   bot.Language(InpLanguage);

//--- set token


//--- set templates
   bot.Templates(InpTemplates);


   bot.ForceReply();
//--- done



//--- set timer
   int   timer_ms = 1500;
   switch(InpUpdateMode)
     {
      case UPDATE_FAST:
         timer_ms = 1000;
         break;
      case UPDATE_NORMAL:
         timer_ms = 2000;
         break;
      case UPDATE_SLOW:
         timer_ms =3000;
         break;
      default:
         timer_ms =1000;
         break;
     };


   EventSetTimer(timer_ms);

	SetIndexBuffer    (0, dBufBuy);
	SetIndexEmptyValue(0, 0.0);
	SetIndexStyle     (0, DRAW_ARROW);
	SetIndexArrow     (0, 233);					// full arrow up	
	SetIndexLabel		(0, "SI BUY");
	
	SetIndexBuffer    (1, dBufSell);
	SetIndexEmptyValue(1, 0.0);
	SetIndexStyle     (1, DRAW_ARROW);
	SetIndexArrow     (1, 234);					// full arrow down	
	SetIndexLabel		(1, "SI SELL");
 
	SetIndexBuffer    (2, dBufExitBuy);
	SetIndexEmptyValue(2, 0.0);
	SetIndexStyle     (2, DRAW_ARROW);
	SetIndexArrow     (2, 251);					// cross	
	SetIndexLabel		(2, "SI BUY EXIT");

	SetIndexBuffer    (3, dBufExitSell);
	SetIndexEmptyValue(3, 0.0);
	SetIndexStyle     (3, DRAW_ARROW);
	SetIndexArrow     (3, 251);					// cross	
	SetIndexLabel		(3, "SI SELL EXIT");
	
	SetIndexBuffer    (4, dBufSL);
	SetIndexEmptyValue(4, 0.0);
	SetIndexStyle     (4, DRAW_LINE, STYLE_DASH);
	SetIndexLabel		(4, "SI SL");
	 
	IndicatorShortName(IndName);
 
	RemoveObjects(ObjPref);	
	WindowRedraw();
string sym=Symbol();
	LogOpen(sym);
	LogWrite(ChartID(), "Log for: " + IndName);
	LogWrite(ChartID(), "Pair: " + sym+", period: "+(string)Period());
	LogWrite(ChartID(), "\n");	
	
	GetPoint();	
	
	offsets *= dblPoint;

	if (MarketInfo(NULL, MODE_STOPLEVEL) > 0)
	{
		MinSLDistance = MarketInfo(NULL, MODE_STOPLEVEL);	// min. SL distance
		MinSLDistance /= dblPoint/Point;							// in pips

		LogWrite(ChartID(), "Min. SL distance (in pips): " + (string)MinSLDistance);
	}
	

   return   INIT_SUCCEEDED;


}


//-----------------------------------------------------------------------------
// DEINIT
//-----------------------------------------------------------------------------

int deinits()
{
	RemoveObjects(ObjPref);	
	WindowRedraw();

	LogWrite(ChartID(), "END LOG");
	LogClose();

	return(0);
}


//-----------------------------------------------------------------------------
// DisplayInfo
//-----------------------------------------------------------------------------

void DisplayInfo(int BNum)
{
	int StartY, StartX, Distance, FSize, Row;
	
	color FColor;
	double Pips, Lots, LotsRisk;
	int StartBar;
	bool TradeActive = false;
	string Printout="";


	StartX = 300; StartY = 75;
	FName = "Arial"; FColor =clrBeige; FSize = 10;

	DrawFixedLbl(ObjPref + "L_Title", "TradeExpert",0, StartX, StartY,
				 		FSize, FName, FColor, false);

	StartY =50; Distance = 50;
	FSize = 20;
	
	TradeActive = BuyActive || SellActive;
	
	// trade type
	if (BuyActive){Printout = "Buy "+_Symbol;//smartBot.SendChatAction(InpChatID,ACTION_OPEN_BUY);
	
	bot.SendMessage(InpChannelChatID,Printout);bot.SendScreenShot(ChartID(),_Symbol,PERIOD_CURRENT,InpTemplates);
	}
   else if (SellActive){Printout = "Sell " +_Symbol;// smartBot.SendChatAction(InpChatID,ACTION_OPEN_SELL);//
bot.SendMessage(InpChannelChatID,Printout);bot.SendScreenShot(ChartID(),_Symbol,PERIOD_CURRENT,InpTemplates);
}else {Printout = "---"+"Wait for signal on  "+_Symbol;
	
	// smartBot.SendChatAction(InpChatID,ACTION_NO_TRADE_NOW
	 }
	 ;//smartBot.SendMessageToChannel(InpChannel,Printout);
	DrawFixedLbl(ObjPref + "L_Trade", "Trade: " + Printout, 0, StartX,(int)( StartY + Row*Distance),FSize, FName, FColor, false);
	Row++;
	
	// start price
	if (TradeActive)
		Printout = DoubleToStr(StartPrice, iDigits);
	else
		Printout = "---";	
	DrawFixedLbl(ObjPref + "L_StartP", "Entry price: " + Printout, 0, StartX, StartY + Row*Distance,
				 		FSize, FName, FColor, false);
	Row++;	
	
	// current SL
	if (TradeActive)
		Printout = DoubleToStr(dBufSL[BNum], iDigits);
	else
		Printout = "---";	
	DrawFixedLbl(ObjPref + "L_SL", "Current SL: " + Printout, 0, StartX, StartY + Row*Distance,
				 		FSize, FName, FColor, false);
	Row++;	

	// current spread
	Printout = DoubleToStr((Ask-Bid)/dblPoint, 1);
	DrawFixedLbl(ObjPref + "L_Spread", "Current spread: " + Printout, 0, StartX, StartY + Row*Distance,
				 		FSize, FName, FColor, false);
	Row++;	
	
	// lots according to risk
	if (TradeActive)
	{
		StartBar = iBarShift(NULL, 0, StartTime);
  double jkk=MarketInfo(Symbol(), MODE_TICKSIZE) * MarketInfo(Symbol(), MODE_TICKVALUE);
  if(jkk==0) {jkk=1;};
		Lots = dblPoint / jkk;
		if (BuyActive)
			Pips = (Open[StartBar] - dBufSL[StartBar])/dblPoint + StartSpread/dblPoint;	// buy SL is at Bid, so we have to add spread
		else if (SellActive)
			Pips = (dBufSL[StartBar] - Open[StartBar])/dblPoint;									// sell SL is at Ask, so spread is included here

		LotsRisk = (AccountFreeMargin() * (RiskPercent/100.0)) /Lots /Pips;
		Printout = DoubleToStr(LotsRisk, 1);
	}
	else
		Printout = "---";
		
	DrawFixedLbl(ObjPref + "L_Lots", DoubleToStr(RiskPercent,(int) MarketInfo(Symbol(),MODE_LOTSIZE)) + " % risk per SL in lots: " + Printout, 0, StartX, StartY + Row*Distance,
				 		FSize, FName, FColor, false);
}


//-----------------------------------------------------------------------------
// TradeSignal
// checks conditions for the trade
//-----------------------------------------------------------------------------

int TradeSignal(int BarNum)
{
	int FResult = TRADE_NO_SIGNAL;
	double MAF0, MAF1, MAS0, MAS1;
	double MA2M;
	double ATRVal=34;
	double BarLength=2;


	LogWrite(BarNum, "--- TradeSignal");	
		 
	MAF0 = iMA(NULL, 0, MAFastBars, 0, MAFastType, MAFastPrice, BarNum);
	MAF1 = iMA(NULL, 0, MAFastBars, 0, MAFastType, MAFastPrice, BarNum+1);
	MAS0 = iMA(NULL, 0, MASlowBars, 0, MASlowType, MASlowPrice, BarNum);
	MAS1 = iMA(NULL, 0, MASlowBars, 0, MASlowType, MASlowPrice, BarNum+1);

	MA2M = iMA(NULL, 0, 2, 0, MODE_EMA, PRICE_TYPICAL, BarNum);
	
	// conditions for BUY	(EMA2 is above fast EMA and slow SMMA, fast EMA is below slow SMMA 
	//								 and they are coming together or fast EMA is above slow SMMA and they are separating; last two bars should not be bearish)
	
	if ( 
			!(Close[BarNum] < Open[BarNum] && Close[BarNum+1] <= Open[BarNum+1])
		&& MA2M > MAF0
		&& MA2M > MAS0
		&& (	(MAF0 > MAS0 && MathAbs(MAF0 - MAS0) > MathAbs(MAF1 - MAS1))
			|| (MAF0 < MAS0 && MathAbs(MAF0 - MAS0) < MathAbs(MAF1 - MAS1)) )		
		)
	{
		LogWrite(BarNum, "BUY - CONDITIONS");
		FResult = TRADE_BUY;
	}
	
	// conditions for SELL	(EMA2 is below fast EMA and slow SMMA, fast EMA is above slow SMMA 
	//								 and they are coming together or fast EMA is below slow SMMA and they are separating; last two bars should not be bullish)
	
	if (
			!(Close[BarNum] > Open[BarNum] && Close[BarNum+1] >= Open[BarNum+1])	
		&&	MA2M < MAF0
		&& MA2M < MAS0
		&& (	(MAF0 < MAS0 && MathAbs(MAF0 - MAS0) > MathAbs(MAF1 - MAS1))
			|| (MAF0 > MAS0 && MathAbs(MAF0 - MAS0) < MathAbs(MAF1 - MAS1)) )
		)
	{
		LogWrite(BarNum, "SELL -CONDITIONS");		
		FResult = TRADE_SELL;
	}	
	
	return(FResult);
}


//-----------------------------------------------------------------------------
// SimSLHit
// simulates hitting a SL
//-----------------------------------------------------------------------------

void SimSLHit(int BarNum)
{
	bool CrossedSL = false;
	double CorrectedSL;

	
	if (!(BuyActive || SellActive))
		return;

	LogWrite(BarNum, "-----  SimSLHit");

	// if trade is buy, SL is hit at Bid price; if it's sell, SL is hit at Ask price
	if (BuyActive)
		CorrectedSL = dBufSL[BarNum];
	else if (SellActive)
		CorrectedSL = dBufSL[BarNum] - StartSpread;

	// has price hit SL at this candle?
	CrossedSL = (  (High[BarNum] >= CorrectedSL
					 && Low[BarNum] <= CorrectedSL)
					 || (BuyActive && High[BarNum] <= CorrectedSL)			// when price jumps below SL
					 || (SellActive && Low[BarNum] >= CorrectedSL) );		// when price jumps above SL

	dBufExitBuy[BarNum] = 0.0;
	dBufExitSell[BarNum] = 0.0;

	if (!CrossedSL)
		return;

	// if SL was hit
	if (BuyActive)
	{
		BuyActive = false;
		dBufExitBuy[BarNum] = dBufSL[BarNum];		// for buys mark exit at Bid price (at visual SL and as in backtester)
	
		// alert if current bar
		if (BarNum == 0)
			Alert("Exit from buy "+_Symbol );
			
	}
	else if (SellActive)
	{
		SellActive = false;
		dBufExitSell[BarNum] = dBufSL[BarNum];		// for sells mark exit at Ask price (at visual SL and as in backtester)
		
		// alert if current bar
		if (BarNum == 0)
			Alert("Exit from sell "+_Symbol);///smartBot.SendMessageToChannel(InpChannel,"Exit from sell "+_Symbol);
			
	}			

	LogWrite(BarNum, "Hit SL at: " + (string)dBufSL[BarNum]);
}


//-----------------------------------------------------------------------------
// ExitManagement
// checks exit conditions
//-----------------------------------------------------------------------------

void ExitManagement(int BarNum)
{
	int ExitSig = TRADE_NO_SIGNAL,
		 TradeSig = TRADE_NO_SIGNAL;
	double MAF0, MAF1, MAS0, MAS1, MA2M;
	
	
	if ( !(BuyActive || SellActive) || BarNum == 0 )	// for complete bars only
		return;
	
	LogWrite(BarNum, "-----  ExitManagement");

	// new trade conditions?
	TradeSig = TradeSignal(BarNum);
	LogWrite(BarNum, "Trade signal: " + TradeSig);

	MAF0 = iMA(NULL, 0, MAFastBars, 0, MAFastType, MAFastPrice, BarNum);
	MAF1 = iMA(NULL, 0, MAFastBars, 0, MAFastType, MAFastPrice, BarNum+1);
	MAS0 = iMA(NULL, 0, MASlowBars, 0, MASlowType, MASlowPrice, BarNum);
	MAS1 = iMA(NULL, 0, MASlowBars, 0, MASlowType, MASlowPrice, BarNum+1);	
	MA2M = iMA(NULL, 0, 2, 0, MODE_EMA, PRICE_TYPICAL, BarNum);


	dBufExitBuy[BarNum] = 0.0;
	dBufExitSell[BarNum] = 0.0;

	// exit from BUY
	if (	BuyActive
			&& (	TradeSig == TRADE_SELL			// new sell signal
				|| MA2M < MAS0 ) 						// or EMA2 crossed slow SMMA down
		)
	{		
		BuyActive = false;
		dBufExitBuy[BarNum] = Close[BarNum];	// for buys mark exit at Bid (visual) price
		
		if (TradeSig == TRADE_SELL){
			LogWrite(BarNum, "Exit because of sell signal: " + dBufExitBuy[BarNum]);}
			//smartBot.SendMessageToChannel(InpChannel,"Exit because of sell signal: " + dBufExitBuy[BarNum]);}
		else{
			LogWrite(BarNum, "Exit because of EMA2 crossed slow SMMA down: " + dBufExitBuy[BarNum]);
			//smartBot.SendMessageToChannel(InpChannel,"Exit because of EMA2 cross:slow"+   dBufExitBuy[BarNum]);}
			}
	}		
	// exit from SELL
	else if (	SellActive 
				&& (	TradeSig == TRADE_BUY		// new buy signal
					|| MA2M > MAS0 ) 					// or EMA2 crossed slow SMMA up
				)
	{
		SellActive = false;
		dBufExitSell[BarNum] = Close[BarNum]+StartSpread;	// for sells mark exit at Ask price
		
		if (TradeSig == TRADE_BUY){
			LogWrite(BarNum, "Exit because of buy signal: " + dBufExitSell[BarNum]);
			//smartBot.SendMessageToChannel(InpChannel,"Exit because of buu signal: " + dBufExitSell[	BarNum]);}
			}
		else{
			LogWrite(BarNum, "Exit because EMA2 crossed slow SMMA up: " + dBufExitSell[BarNum]); 
			//smartBot.SendMessageToChannel(InpChannel,"Exit because of EMA2cross : " + dBufExitSell[	BarNum]);}
			}
}

}

//-----------------------------------------------------------------------------
// NewTradeManagement
//-----------------------------------------------------------------------------

void NewTradeManagement(int BarNum)
{
	int TradeSig = TRADE_NO_SIGNAL;

	if (SellActive || BuyActive)
		return;

	LogWrite(BarNum, "-----  NewTradeManagement");
	
	TradeSig = TradeSignal(BarNum);

	dBufBuy[BarNum] = 0.0;
	dBufSell[BarNum] = 0.0;
					
	// if signal for SELL
	if (TradeSig == TRADE_SELL)
	{
		dBufSell[BarNum] = High[BarNum] + offsets;
		LogWrite(BarNum, "SELL arrow");
		
		// for history bars
		if (BarNum > 0)
		{		
		   SellActive = true;
			StartSpread = (Ask-Bid);			// current spread
			StartPrice = Open[BarNum-1];		// sells are open at Bid price
			StartTime = Time[BarNum-1];
			LogWrite(BarNum, "SellActive: true, StartPrice: " + StartPrice + ", StartTime: " + TimeToStr(StartTime, TIME_DATE | TIME_SECONDS) +
								", StartSpread: " + StartSpread);
		}	
	}
	
	// if signal for BUY
	else if (TradeSig == TRADE_BUY)
	{
		dBufBuy[BarNum] = Low[BarNum] - offsets;
		LogWrite(BarNum, "BUY arrow");

		// for history bars		
		if (BarNum > 0)
		{								
		   BuyActive = true;
			StartSpread = (Ask-Bid);							// current spread
			StartPrice = Open[BarNum-1]+StartSpread;		// buys are open at Ask price
			StartTime = Time[BarNum-1];
			LogWrite(BarNum, "BuyActive: true, StartPrice: " + StartPrice + ", StartTime: " + TimeToStr(StartTime, TIME_DATE | TIME_SECONDS) +
								", StartSpread: " + StartSpread);
		}
	}
}


//-----------------------------------------------------------------------------
// SetSL
// calculates SL for each bar
//-----------------------------------------------------------------------------

void SetSL(int BarNum)
{	
	double ATRVal=12, SLVal=23;
	double FractUp=2, FractDown=1;
	int PosUp=1, PosDown=0;


   if ( !(BuyActive || SellActive) )
   	return;
   
   LogWrite(BarNum, "-----  SetSL");
   
   // if SL is already set for this bar
   if (dBufSL[BarNum] > 0.0)
   {
   	LogWrite(BarNum, "SL already set: " + dBufSL[BarNum]);
   	return;  
   }
   
   dBufSL[BarNum] = 0.0;
     
   ATRVal = iATR(NULL, 0, 200, BarNum+1);			// ATR for 200 bars gives pretty stable bar range value for a certain pair and time period
	LogWrite(BarNum, "ATRVal: " + ATRVal);
		
	// SL for BUY
		
	if (BuyActive)
	{   	
  		SLVal = High[Highest(NULL, 0, MODE_HIGH, ChandBars, BarNum+1)] + StartSpread - ATRVal*ChandATRFact;	// calculate according to Ask price
  		
  		// if SL is too close
  		if (SLVal > Open[BarNum] + StartSpread - ATRVal)			
  			SLVal = Open[BarNum] + StartSpread - ATRVal;
  		
   	SLVal = NormalizeDouble(SLVal, Digits);   	
   	LogWrite(BarNum, "Buy, suggested SLVal: " + SLVal);
   	
   	// SL goes only in one direction (up for buys)

		// if prev. trade ended at prev. bar or new trade just started	
   	if (	(dBufExitBuy[BarNum+1] > 0.0 || dBufExitSell[BarNum+1] > 0.0) 	
   		|| dBufSL[BarNum+1] == 0.0 )										
   	{
   		LogWrite(BarNum, "New SL: " + SLVal);
   		dBufSL[BarNum] = SLVal;
   	}
   	else if ( (SLVal - dBufSL[BarNum+1] >= 0.5*dblPoint)						// if new SL is higher (at least for 0.5 pip) than previous one
   		 		 && (Open[BarNum] - SLVal > MinSLDistance*dblPoint) )			// and far enough from current price (which is open price at the beginning of the bar)
   	{
   		LogWrite(BarNum, "Old SL: " + (string)dBufSL[BarNum+1] + ", new SL: " + SLVal);   		
   		dBufSL[BarNum] = SLVal;
   	}
   	else																						// otherwise SL doesn't change
   	{
   		dBufSL[BarNum] = dBufSL[BarNum+1];
   		LogWrite(BarNum, "SL stays same: " + dBufSL[BarNum+1]);   		
   	}   		
	}
	
	// SL for SELL
	
	if (SellActive)
	{
		SLVal = Low[Lowest(NULL, 0, MODE_LOW, ChandBars, BarNum+1)] + ATRVal*ChandATRFact;						// calculate according to Bid price
		
  		// if SL is too close
  		if (SLVal < Open[BarNum] + ATRVal)	
  			SLVal = Open[BarNum] + ATRVal;

   	SLVal = NormalizeDouble(SLVal, Digits);   	
			
   	LogWrite(BarNum, "Sell, suggested SLVal: " + (string)SLVal);
		
   	// SL goes only in one direction (down for sells)
   	
		// if prev. trade ended at prev. bar or new trade just started	
		if (	(dBufExitBuy[BarNum+1] > 0.0 || dBufExitSell[BarNum+1] > 0.0)
			|| dBufSL[BarNum+1] == 0.0)		
		{
   		LogWrite(BarNum, "New SL: " + (string)SLVal);
			dBufSL[BarNum] = SLVal;		
		}
		else if ( (dBufSL[BarNum+1] - SLVal >= 0.5*dblPoint)						// if new SL is lower (at least for 0.5 pip) than previous one
			 		 && (SLVal - Open[BarNum] > MinSLDistance*dblPoint) )			// and far enough from current price (which is open price at the beginning of the bar)
		{
   		LogWrite(BarNum, "Old SL: " + (string)dBufSL[BarNum] + ", new SL: " +(string) SLVal);
	  		dBufSL[BarNum] = SLVal;
	  	}
   	else																						// otherwise SL doesn't change
   	{
   		dBufSL[BarNum] = dBufSL[BarNum+1];
   		LogWrite(BarNum, "SL stays same: " + (string)dBufSL[BarNum+1]);   		   		
   	}   		
	}
}


//-----------------------------------------------------------------------------
// ProcessAlert
//-----------------------------------------------------------------------------

void ProcessAlert(string AlertStr)
{
	if (UseSoundAlert)	 	
		PlaySound((string)AlertSound);
	
	if (UsePopupAlert)
		Alert(IndName, ": ", Symbol(), " M", Period(), ": ", AlertStr);
		   	
   LogWrite(0, AlertStr);	
}


//=============================================================================
// START
//=============================================================================

int start()
{












	int counted_bars = IndicatorCounted();
	int MinBars;
	
	static datetime PrevTime = 0;
	

	// --- common proc.
	
	// just for 1st init.
	if (PrevTime == 0)
		PrevTime = Time[0];	
		
	MinBars = 200;
	
   int i = Bars-MinBars-1;
   if (i < 0)
   	return(-1);
   	
	if (counted_bars < 0)
		return(-1);  	
  
   if ( counted_bars > MinBars )
   	i = Bars - counted_bars - 1;

	if ( i > BarsBack-1 )
		i = BarsBack-1;


	// ====================    bar processing history + current
	
	if (PrevTime == Time[0])	
	{
		for (; i>=0; i--)
		{					
			LogWrite(i, "\n\nBar: " + (string)i);
			
			SetSL(i);					// if in trade, does SL need to be changed?
			SimSLHit(i);				// if in trade, has SL been hit?
			ExitManagement(i);		// if in trade, are exit conditions met?
			NewTradeManagement(i);	// if not in trade, are entry conditions met?
		}	

		if (!FirstDisplay)
		{
			DisplayInfo(0);
			FirstDisplay = true;
		}		
	}
	
	else		// ==================   after each new bar
	{
		PrevTime = Time[0];

		LogWrite(0, "\n\nNew current bar");

		// for the just finished bar we have to recheck conditions and set flags

		ExitManagement(1);			// look for exit conditions at the just finished bar
		NewTradeManagement(1);		// look for entry conditions at the just completed bar
		SetSL(0);						// if in trade, set SL for the new bar
		DisplayInfo(0);				// if in trade, display info for trading

		// alerts			
		if ( dBufExitBuy[1] > 0.0 )	
			ProcessAlert("Exit from buy");
	
		if ( dBufExitSell[1] > 0.0 )	
			ProcessAlert("Exit from sell");
			
		if ( dBufBuy[1] > 0.0 )			
			ProcessAlert("Buy");
	
		if ( dBufSell[1] > 0.0 )		
			ProcessAlert("Sell");
	}	
	
	starts();
	
	return(0);
}	// end START



//--------------------------------------------------------------------------------------
// GetPoint
//--------------------------------------------------------------------------------------

void GetPoint()
{
	if (Digits == 3 || Digits == 5)   
		dblPoint = Point * 10;
	else
		dblPoint = Point;
      
	if (Digits == 3 || Digits == 2)
		iDigits = 2;
	else
		iDigits = 4;
}


//--------------------------------------------------------------------------------------
// RemoveObjects
//--------------------------------------------------------------------------------------

void RemoveObjects(string Pref)
{   
   
   string OName = "";

   for (int i = ObjectsTotal(); i >= 0; i--) 
   {
      OName = ObjectName(i);
      if (StringFind(OName, Pref, 0) > -1)
        	ObjectDelete(OName);
   }
}


// *************************************************************************************
//
//	LOG routines
//
// *************************************************************************************

	string FName ="TrendExpert"+(string)Period()+".txt";
//--------------------------------------------------------------------------------------
// LogOpen
//--------------------------------------------------------------------------------------

void LogOpen(string sym)
{
	if (!WriteToLog)
		return;
	

		
	LogHandle = FileOpen(FName, FILE_WRITE);
	
	if (LogHandle < 1)
	{
		Print("Cannot open LOG file ", FName + "; Error: ", GetLastError(), " : ", ErrorDescription( GetLastError() ) );
		return;
	}	

	FileSeek(LogHandle, 0, SEEK_END);
}


//--------------------------------------------------------------------------------------
// LogClose
//--------------------------------------------------------------------------------------

void LogClose()
{
	if ( (!WriteToLog) || (LogHandle < 1) )
		return;

	FileClose(LogHandle); 
}


