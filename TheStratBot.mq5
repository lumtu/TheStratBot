//+------------------------------------------------------------------+
//|                                                  TheStratBot.mq5 |
//|                                           Copyright 2022, lumtu  | 
//|                                             https://www.lumtu.de |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, lumtu"
#property link      "https://www.lumtu.de"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Arrays\List.mqh>
#include <Expert\Expert.mqh>
//--- available money management
#include <Expert\Money\MoneyNone.mqh>
#include <Expert\Money\MoneySizeOptimized.mqh>

#include "TheStratExpert.mqh"

string  Expert_Title                 = "TheStartEA"; // Document name
ulong   Expert_MagicNumber           = 23456821;        // 
bool    Expert_EveryTick             = false;        // 

int ExtTimeOut=10; // time out in seconds between trade operations

// Money management
input double Lots = 0.1; 		// Basic lot size
input bool UseFixLots = true;
input bool UseExitTimeFrame = true;
input double RewardRatio = 1.7;
double RiskRatio = 1;

input ENUM_TIMEFRAMES TradingTimeframe = PERIOD_H1;  // Timeframe für den Einstieg
input ENUM_TIMEFRAMES ExitTimeframe = PERIOD_H1;    // Timeframe für die EXIT Auswertung 
input ENUM_TIMEFRAMES HTF1 = PERIOD_H4; // nächst größerer Timeframe
input ENUM_TIMEFRAMES HTF2 = PERIOD_D1; // nächst größerer Timeframe
input ENUM_TIMEFRAMES HTF3 = PERIOD_W1; // nächst größerer Timeframe




//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CTheStratExpert ExtExpert(Lots, ExitTimeframe, TradingTimeframe, HTF1, HTF2, HTF3);

//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   // if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))

    if(!ExtExpert.Init()) {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
     
     ExtExpert.UseFixLots(UseFixLots);
     ExtExpert.UseExitTimeFrame(UseExitTimeFrame);   
     ExtExpert.SetRR(RiskRatio, RewardRatio);
     
     
//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   static datetime limit_time=0; // last trade processing time + timeout
//--- don't process if timeout
   if(TimeCurrent()>=limit_time)
     {
      //--- check for data
      if(ExtExpert.Processing())
         limit_time=TimeCurrent()+ExtTimeOut;
    }

  }
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   // ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   // ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+

  
  

