//+------------------------------------------------------------------+
//|                                                  TheStratBot.mq5 |
//|                                           Copyright 2022, lumtu  |
//|                                             https://www.lumtu.de |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, lumtu"
#property link "https://www.lumtu.de"
#property version "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Arrays\List.mqh>
#include <Expert\Expert.mqh>
//--- available money management
#include <Expert\Money\MoneyNone.mqh>
#include <Expert\Money\MoneySizeOptimized.mqh>

#include "TheStratExpert.mqh"

string Expert_Title = "TheStartEA";  // Document name
ulong Expert_MagicNumber = 23456821; //
bool Expert_EveryTick = false;       //

int ExtTimeOut = 10; // time out in seconds between trade operations

// Money management
input group "Money management"
input bool   UseMoneyInsteadOfPercentage = false;
input bool   UseEquityInsteadOfBalance   = true; // Eigenkapital statt Balance
input double FixedBalance       = 0.0;      // FixedBalance If greater than 0, position size calculator will use it instead of actual account balance.
input double MoneyRisk          = 0.0;      // MoneyRisk Risk tolerance in base currency
input double TotalRiskInPercent = 1.0;      // Risk tolerance in percentage points
input int    LotFactor          = 1;

input group "Time management"
input int StartHour = 16;
input int StartMin = 30;
input int EndHour = 23;
input int EndMin = 00;

input group "Exit management"
input EnTrailingStop   TrailingStop    = EnTrailingStop::Use_None;
input EnTakeProfitType TakeProfitType  = EnTakeProfitType::Reward2;
input ENUM_TIMEFRAMES  TargetTimeFrame = PERIOD_H4;
input bool             UseTheStratExit = true;
input ENUM_TIMEFRAMES  ExitTimeframe   = PERIOD_H1; // TheStratExit Timeframe


input group "Entry management"
input int UseVolumeAvgAmount = 0; //  0 = Nein, Sonst Anzahl Bars

input ENUM_TIMEFRAMES TradingTimeframe = PERIOD_H1; // Timeframe für den Einstieg
input ENUM_TIMEFRAMES HTF1 = PERIOD_H4;             // nächst größerer Timeframe
input ENUM_TIMEFRAMES HTF2 = PERIOD_D1;             // nächst größerer Timeframe
input ENUM_TIMEFRAMES HTF3 = PERIOD_W1;             // nächst größerer Timeframe

input group "TheStrat pattern"
input bool UseReversal_22 = true;   // UseReversal 2-2
input bool UseReversal_312 = true;  // UseReversal 3-1-2 
input bool UseReversal_3112 = true; // UseReversal 3-1-1-2  
input bool UseReversal_322 = true;  // UseReversal 3-2-2 
input bool UseReversal_212 = true;  // UseReversal 2-1-2 
input bool UseReversal_32 = false;  // Reversal 3-2 ( Start on M30 or H1 )
input bool UseReversal_122 = true;  // Reversal 1-2-2
input bool UseContinuation_212 = false;  // Continuation 2-1-2
input bool UseContinuation_222 = false;  // Continuation 2-2-2



//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CTheStratExpert ExtExpert(ExitTimeframe, TradingTimeframe, HTF1, HTF2, HTF3);

//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
{
  //--- Initializing expert
  // if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))

  if (!ExtExpert.Init())
  {
    //--- failed
    printf(__FUNCTION__ + ": error initializing expert");
    ExtExpert.Deinit();
    return (INIT_FAILED);
  }

  ExtExpert.SetUseMoneyInsteadOfPercentage(UseMoneyInsteadOfPercentage);
  ExtExpert.SetUseEquityInsteadOfBalance(UseEquityInsteadOfBalance);
  ExtExpert.SetFixedBalance(FixedBalance);
  ExtExpert.SetMoneyRisk(MoneyRisk);
  ExtExpert.SetRisk(TotalRiskInPercent);
  ExtExpert.SetLotFactor(LotFactor);

  ExtExpert.SetTrailingStop(TrailingStop);
  
  ExtExpert.UseTheStratExit(UseTheStratExit);
  ExtExpert.UseTargetTimeframe(TakeProfitType, TargetTimeFrame);
  ExtExpert.UseVolumeAVG(UseVolumeAvgAmount);
  
  ExtExpert.UseReversal_22(UseReversal_22);
  ExtExpert.UseReversal_312(UseReversal_312);
  ExtExpert.UseReversal_3112(UseReversal_3112);
  ExtExpert.UseReversal_322(UseReversal_322);
  ExtExpert.UseReversal_212(UseReversal_212);
  ExtExpert.UseReversal_32(UseReversal_32);
  ExtExpert.UseReversal_122(UseReversal_122);
  ExtExpert.UseContinuation_212(UseContinuation_212);
  ExtExpert.UseContinuation_222(UseContinuation_222);

   int eh = EndHour;
   if(EndHour<StartHour) {
      eh += 24;
   }
   ExtExpert.m_startHour = StartHour;
   ExtExpert.m_startMin = StartMin;
   ExtExpert.m_endHour = eh;
   ExtExpert.m_endMin = EndMin;

   if(HTF1>HTF2 || HTF1 > HTF3)
      return INIT_PARAMETERS_INCORRECT;

   if(HTF2>HTF3)
      return INIT_PARAMETERS_INCORRECT;

   if(TradingTimeframe>HTF1)
      return INIT_PARAMETERS_INCORRECT;

   if(ExitTimeframe<TradingTimeframe)
      return INIT_PARAMETERS_INCORRECT;

  //--- ok
  return (INIT_SUCCEEDED);
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
  static datetime limit_time = 0; // last trade processing time + timeout
                                  //--- don't process if timeout
  if (TimeCurrent() >= limit_time)
  {
    //--- check for data
    if (ExtExpert.Processing())
      limit_time = TimeCurrent() + ExtTimeOut;
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
