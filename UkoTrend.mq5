//+------------------------------------------------------------------+
//|                                                         MACD.mq5 |
//|                   Copyright 2009-2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2022-2022, lumtu Software"
#property link        "http://www.lumtu.de"
#property description "UKO Trend"

// class CPnt;
#define LINE_PREFIX "TrendLine-"

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
      if(_prev != NULL)
         return false;
         
      return _prev.Price() < Price();
   }

   bool IsDown()
   { 
      if(_prev != NULL)
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
      g_trend = new CPnt();
      g_last = new CPnt();
      g_trend.Next(g_last);
      
      if( open[1] < close[1])
      {  // is green
         g_trend.Set(low[0], time[0]);
         g_last.Set(high[1], time[1]);
      }
      else
      {  // is red
         g_trend.Set(high[0], time[0]);
         g_last.Set(low[1], time[1]);
      }
      
      start=2;
   }

   if(!IsNewBar())
      return prev_calculated;

   for(int i=start; i < rates_total ; i++)
   {  
      double prevPrice = g_last.Prev().Price();
      double lastPrice = g_last.Price();
      if(g_last.IsUp())
      {
         // price in current trend line is up
         if(high[i] >= lastPrice)
         {  // new high
            g_last.Set(lastPrice, time[i]);
         }
         
         else if(prevPrice > lastPrice)
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
         
         else if(lastPrice < low[i-1])
         {  
            CPnt *pnt = new CPnt(low[i], time[i]);
            g_last.Next(pnt);
            g_last = pnt;
         }
      }
      else
      {
         // price in current trend line is down
         if(low[i] <= lastPrice)
         {  // new low
            g_last.Set(lastPrice, time[i]);
         }
         
         else if(prevPrice < lastPrice)
         {  // last high is broken (Trend is broken)
            // \    _ /__
            //  \/\  /  broken
            //     \/
            // 
            DeleteGrafik();
            
            CPnt *pnt = new CPnt(high[i], time[i]);
            g_last.Next(pnt);
            g_last = pnt;
            
         }   

         else if(lastPrice > high[i-1])
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
   g_lineCount = INT_MAX;
   int lineCount = 1;
   long chartId = ChartID();
   
   for(int i=0; i<g_lineCount; ++i)
   {
      string name = LINE_PREFIX + IntegerToString(i);
      ObjectDelete(chartId, name); 
   }   
}

void DrawTrend()
{
   if(g_lineCount > 100)
   {
      DeleteGrafik();
   }

   double price = g_trend.Price();
   datetime time = g_trend.Time();
   
   int lineCount = 1;
   CPnt* current = g_trend.Next();
   while(current != NULL)
   {
      double p2 = g_trend.Price();
      datetime t2 = g_trend.Time();
      AddLine(lineCount++, price, time, p2, t2 );
   }
   
   g_lineCount = MathMax(lineCount, g_lineCount);
}


bool AddLine(int idx, double p1, datetime t1, double p2, datetime t2, bool isDot=false)
{
   
   
   string name = LINE_PREFIX + IntegerToString(idx);
   uint clr = clrAquamarine;
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


