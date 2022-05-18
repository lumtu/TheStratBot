//+------------------------------------------------------------------+
//|                                                         MACD.mq5 |
//|                   Copyright 2009-2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2022-2022, lumtu Software"
#property link        "http://www.lumtu.de"
#property description "UKO Trend"

//---- the indicator will be plotted in the main window
#property indicator_chart_window

#property indicator_buffers 1
#property indicator_plots   1
//--- plot trend
#property indicator_label1  "Trend"
#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// class CPnt;
#define LINE_PREFIX "TrendLine-"

double TrendBuffer[];      // main buffer

int g_lineCount = 0;

class CPnt
{
   bool _pending;
   double _price; 
   datetime _time;
   
   CPnt* _subTrend;
   
   CPnt* _prev;
   CPnt* _next;
   
public:
   CPnt()
      : _price(0)
      , _time(0)
      , _subTrend(NULL)
      , _prev(NULL)
      , _next(NULL)
      , _pending(true)
   {}

   CPnt(double price, datetime time)
      : _price(price)
      , _time(time)
      , _subTrend(NULL)
      , _prev(NULL)
      , _next(NULL)
      , _pending(true)
   {}
   
   ~CPnt()
   {
      delete _prev;
      delete _next;
      delete _subTrend;
   }
   
   void Set(double price, datetime time)
   {
      _price = price;
      _time = time;
   }
   
   bool IsUp()
   { 
      if(_prev == NULL)
         return false;
         
      return _prev.Price() < Price();
   }

   bool IsDown()
   { 
      if(_prev == NULL)
         return false;
         
      return _prev.Price() > Price();
   }
   
   bool IsPending() const { return _pending; }
   void Pending(bool val) {  _pending = val; }
   
   double Price() const
   { return _price; }
   
   datetime Time() const
   { return _time; }
   

   void SubTrend(CPnt* pnt)
   { _subTrend = pnt; }

   CPnt* SubTrend() 
   { return _subTrend; }
   
   void Prev(CPnt* pnt)
   { 
      _prev = pnt; 
      if(_prev != NULL)
         _prev._next = &this;
   }

   CPnt* Prev() 
   { return _prev; }

   void Next(CPnt* pnt)
   { 
      _next = pnt; 
      if(_next != NULL)
         _next._prev = &this;
   }

   CPnt* Next() 
   { return _next; }
};

 
//--- indicator settings
// #property indicator_separate_window

CPnt* g_trend = NULL;
CPnt* g_last = NULL;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
//--- indicator buffers mapping
   SetIndexBuffer(0, TrendBuffer, INDICATOR_DATA);
   
//--- set short name and digits
   string short_name= "trend";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   PlotIndexSetString(0,PLOT_LABEL,short_name);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- set an empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   
   
   
}
  
void OnDeinit(const int reason)
{
   
}  

//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total<5)
      return(0);

   
   
   int start=prev_calculated-1;
   if(start<5)
   {
      int maxHistoryToCalc = 400;
      start=2;
      if(rates_total - maxHistoryToCalc > 5)
      {
        start = rates_total - maxHistoryToCalc;
      }
   }

   if(!IsNewBar() && g_trend != NULL)
      return prev_calculated;

   for(int i=start; i < rates_total ; i++)
   {  
      if( g_trend == NULL)
      {
          g_trend = new CPnt();
          g_last = new CPnt();
          g_trend.Next(g_last);
          
          if( open[i] < close[i])
          {  // is green
             g_trend.Set(low[i-1], time[i-1]);
             g_last.Set(high[i], time[i]);
          }
          else
          {  // is red
             g_trend.Set(high[i-1], time[i-1]);
             g_last.Set(low[i], time[i]);
          }
          continue;
      }
   
   
      if(g_last.IsUp())
      {
         double prevLow = g_last.Prev().Price();
         double lastHigh = g_last.Price();
         
         // price in current trend line is up
         if(high[i] >= lastHigh)
         {
            //   + --new high 
            //  /___
            // /
            g_last.Set(high[i], time[i]);
         }
         
         else if(prevLow > close[i])
         {  
            // last Low is broken (Trend is broken)
            //     /\
            //  /\/ _\___ broken
            // /      \
            // 
            CPnt *pnt = new CPnt(low[i], time[i]);
            g_last.Next(pnt);
            g_last = pnt;
         }
         
         else if(low[i-1] > close[i])
         {  
            // last Low is not broken
            //     /\____
            //  /\/   correction
            // /      
            // 
         
            CPnt *pnt = new CPnt(low[i], time[i]);
            g_last.Next(pnt);
            g_last = pnt;
         }
      }
      else
      {
         double prevHigh = g_last.Prev().Price();
         double lastLow = g_last.Price();
      
         // price in current trend line is down
         if(low[i] <= lastLow)
         {  // new low
            g_last.Set(low[i], time[i]);
         }
         
         else if(prevHigh < close[i])
         {  // last high is broken (Trend is broken)
            // \    _ /__
            //  \/\  /  broken
            //     \/
            // 
            
            CPnt *pnt = new CPnt(high[i], time[i]);
            g_last.Next(pnt);
            g_last = pnt;
            
         }   

         else if(high[i-1] < close[i])
         {
            CPnt *pnt = new CPnt(high[i], time[i]);
            g_last.Next(pnt);
            g_last = pnt;
         }
      }
   }
   
   
   DrawTrend();
   
   return(rates_total);
}

//--- Detects when a "new bar" occurs, which is the same as when the previous bar has completed.
bool IsNewBar()
{
   string symbol = _Symbol;
   ENUM_TIMEFRAMES period = PERIOD_CURRENT;
   bool isNewBar = false;
   static datetime priorBarOpenTime = NULL;

//--- SERIES_LASTBAR_DATE == Open time of the last bar of the symbol-period
   const datetime currentBarOpenTime = (datetime) SeriesInfoInteger(symbol, period, SERIES_LASTBAR_DATE);

   if(priorBarOpenTime != currentBarOpenTime)
   {
      //--- Don't want new bar just because EA started
      isNewBar = (priorBarOpenTime == NULL) ? false : true; // priorBarOpenTime is only NULL once

      //--- Regardless of new bar, update the held bar time
      priorBarOpenTime = currentBarOpenTime;
   }

   return isNewBar;
}

void DeleteGrafik()
{
   int lineCount = 1;
   long chartId = ChartID();
   
   for(int i=0; i<g_lineCount; ++i)
   {
      string name = LINE_PREFIX + IntegerToString(i);
      ObjectDelete(chartId, name); 
   }   
   
   g_lineCount = 0;
}

void DrawTrend()
{
   if(g_lineCount > 100)
   {
      DeleteGrafik();
   }

   int lineCount = 1;
   CPnt* current = g_trend.Next();
   while(current != NULL)
   {
      double p1 = current.Prev().Price();
      datetime t1 = current.Prev().Time();
      double p2 = current.Price();
      datetime t2 = current.Time();
      current = current.Next();
      AddLine(lineCount++, p1, t1, p2, t2 );
      
      
   }
   
   g_lineCount = MathMax(lineCount, g_lineCount);
}


bool AddLine(int idx, double p1, datetime t1, double p2, datetime t2, bool isDot=false)
{
   
   
   string name = LINE_PREFIX + IntegerToString(idx);
   uint clr = clrOrangeRed;
   long chartId = ChartID();
  
   if(ObjectFind(chartId, name) < 0 )
   {
      // if (!ObjectCreate( chartId, name, OBJ_HLINE, 0, 0, price))
      if (!ObjectCreate( chartId, name, OBJ_TREND, 0, t1, p1, t2,  p2))
      {
         PrintFormat("ObjectCreate(%s, HLINE) [1] failed: %d", name, GetLastError() );
      }
      else if (!ObjectSetInteger( 0, name, OBJPROP_COLOR, clr )) 
      {
         PrintFormat("ObjectSetInteger(%s, Color) [2] failed: %d", name, GetLastError() );
      }
      else if (!ObjectSetInteger( 0, name, OBJPROP_WIDTH, 2)) 
      {
         PrintFormat("ObjectSetInteger(%s, Width) [2] failed: %d", name, GetLastError() );
      }
   }
   else if(!ObjectMove(chartId, name, 0, t1, p1) || !ObjectMove(chartId, name, 1, t2, p2))
   {
      PrintFormat("ObjectMove(%s, OBJ_HLINE) [3] failed: %d", name, GetLastError() );
   }
   
   if(isDot)
   {
      ObjectSetInteger(chartId, name, OBJPROP_STYLE, STYLE_DOT);
   }
   
   return true;
}


