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
input int InpBarShiftTF1 = 0; // TF1 Barshift 
input int InpBarShiftTF2 = 0; // TF2 Barshift 
input int InpBarShiftTF3 = 0; // TF3 Barshift 

input group "Partial profit"
// input bool Fibo_23=true;
input bool Fibo_38=true;
input bool Fibo_50=true;
input bool Fibo_61=true;
input bool Fibo_78=true;
input bool Fibo100=true;
input bool Fibo138=true;
input bool Fibo161=true;
input bool Fibo238=true;

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
CTheStratExpert ExtExpert(ExitTimeframe, TradingTimeframe, HTF1, HTF2, HTF3,InpBarShiftTF1,InpBarShiftTF2,InpBarShiftTF3);

//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
{

    if(TradingTimeframe == PERIOD_CURRENT
        || ExitTimeframe == PERIOD_CURRENT
        || HTF1 == PERIOD_CURRENT )
        return INIT_PARAMETERS_INCORRECT;
        
   if(HTF1>HTF2 || HTF1 > HTF3)
      return INIT_PARAMETERS_INCORRECT;

   if(HTF2>HTF3)
      return INIT_PARAMETERS_INCORRECT;

   if(TradingTimeframe>HTF1)
      return INIT_PARAMETERS_INCORRECT;


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

  if(Fibo_38) ExtExpert.SetPartialFibo(38.2);
  if(Fibo_50) ExtExpert.SetPartialFibo(50.0);
  if(Fibo_61) ExtExpert.SetPartialFibo(61.8);
  if(Fibo_78) ExtExpert.SetPartialFibo(78.6);
  if(Fibo100) ExtExpert.SetPartialFibo(100);
  if(Fibo138) ExtExpert.SetPartialFibo(138.2);
  if(Fibo161) ExtExpert.SetPartialFibo(161.8);
  if(Fibo238) ExtExpert.SetPartialFibo(238.2);

   int eh = EndHour;
   if(EndHour<StartHour) {
      eh += 24;
   }
   ExtExpert.m_startHour = StartHour;
   ExtExpert.m_startMin = StartMin;
   ExtExpert.m_endHour = eh;
   ExtExpert.m_endMin = EndMin;


  //--- ok
  return (INIT_SUCCEEDED);
}

double OnTester()
{
  double  param = 0.0;

//  Balance max + min Drawdown + Trades Number:
  double  balance = TesterStatistics(STAT_PROFIT);
  double  min_dd = TesterStatistics(STAT_BALANCE_DD);
  if(min_dd > 0.0)
  {
    min_dd = 1.0 / min_dd;
  }
  double  trades_number = TesterStatistics(STAT_TRADES);
  param = balance * min_dd * trades_number;

  return(param);
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
