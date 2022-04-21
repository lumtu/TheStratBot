//+------------------------------------------------------------------+
//|                                               TheStratExpert.mqh |
//|                                          Copyright , Udo köller  |
//|                                              http://www.lumtu.de |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available money management
#include <Expert\Money\MoneyNone.mqh>
#include <Expert\Money\MoneySizeOptimized.mqh>

#include "Candle.mqh"


class CTheStratExpert
{
protected:
    double            m_adjusted_point;             // point value adjusted for 3 or 5 points
    double            m_lots;                       // Initial position size
    CTrade            m_trade;                      // trading object
    CSymbolInfo       m_symbol;                     // symbol info object
    CPositionInfo     m_position;                   // trade position object
    CAccountInfo      m_account;                    // account info wrapper
    bool              m_useMoneyInsteadOfPercentage;
    bool              m_useEquityInsteadOfBalance ; // Eigenkapital statt Balance
    double            m_fixedBalance;               // If greater than 0, position size calculator will use it instead of actual account balance.
    double            m_moneyRisk;                  // Risk tolerance in base currency
    double            m_risk;                       // Risk tolerance in percentage points
    int               m_lotFactor;
    bool              m_useTargets;
    bool              m_useExitTimeFrame;
    ENUM_TIMEFRAMES   m_exitTimeframe;
    ENUM_TIMEFRAMES   m_entryTimeframe;
    datetime          m_lastBar;
    bool              m_isBarBurned;
    double            m_riskRatio;
    double            m_rewardRatio;
    
    Candle m_c_cur_0;
    Candle m_c_cur_1;
    Candle m_c_cur_2;
    Candle m_c_cur_3;
    Candle m_c_htf1; 
    Candle m_c_htf2; 
    Candle m_c_htf3; 

public:
    CTheStratExpert(double lots, 
      ENUM_TIMEFRAMES exitTF,
      ENUM_TIMEFRAMES entryTF,
      ENUM_TIMEFRAMES lowHigherTF,
      ENUM_TIMEFRAMES midHigherTF,
      ENUM_TIMEFRAMES bigHigherTF);
    ~CTheStratExpert(void);
    bool Init(void);
    void Deinit(void);
    bool Processing(void);
    
    void UseExitTimeFrame(bool useExitTimeFrame) 
    { m_useExitTimeFrame = useExitTimeFrame; }
    
    void SetRR(double riskRatio, double rewardRatio)
    {
         m_riskRatio = riskRatio;
         m_rewardRatio = rewardRatio;
    }
    
protected:
    bool InitCheckParameters();
    bool InitIndicators(void);
    bool LongClosed(void);
    bool ShortClosed(void);
    bool LongModified(void);
    bool ShortModified(void);
    bool LongOpened(void);
    bool ShortOpened(void);

    bool BuyMarket(double stopLoss, double takeProfit, string comment);
    bool SellMarket(double stopLoss, double takeProfit, string comment);
    double TradeSizeOptimized(double stopLoss);
    double CalculateNormalizedDigits();
    
    bool IsNewBar();
};


CTheStratExpert::CTheStratExpert(double lots,
      ENUM_TIMEFRAMES exitTF,
      ENUM_TIMEFRAMES entryTF,
      ENUM_TIMEFRAMES lowHigherTF,
      ENUM_TIMEFRAMES midHigherTF,
      ENUM_TIMEFRAMES bigHigherTF)
    : m_adjusted_point(0)
    , m_lots(lots)
    , m_useMoneyInsteadOfPercentage(false)
    , m_useEquityInsteadOfBalance(true)
    , m_fixedBalance(0.0)
    , m_moneyRisk(0.0)
    , m_risk(2.0)
    , m_lotFactor(1)
    , m_c_cur_0(entryTF, 0)
    , m_c_cur_1(entryTF, 1)
    , m_c_cur_2(entryTF, 2)
    , m_c_cur_3(entryTF, 3)
    , m_c_htf1 (lowHigherTF, 0)
    , m_c_htf2 (midHigherTF, 0)
    , m_c_htf3 (bigHigherTF, 0)
    , m_useExitTimeFrame(false)
    , m_exitTimeframe(exitTF)
    , m_entryTimeframe(entryTF)
    , m_lastBar(0)
    , m_isBarBurned(false)
    , m_riskRatio(1)
    , m_rewardRatio(1.7)
    
{

}

CTheStratExpert::~CTheStratExpert(void)
{

}

bool CTheStratExpert::Init(void)
{
//--- initialize common information
    m_symbol.Name(Symbol());                  // symbol

    if(!InitCheckParameters())
        return(false);

    return true;
}

void CTheStratExpert::Deinit(void)
{

}

bool CTheStratExpert::Processing(void)
{
//--- refresh rates
    if(!m_symbol.RefreshRates())
        return(false);
      
    if( !m_c_cur_0.RefreshRates() ) return (false);
    if( !m_c_cur_1.RefreshRates() ) return (false);
    if( !m_c_cur_2.RefreshRates() ) return (false);
    if( !m_c_cur_3.RefreshRates() ) return (false);
    if( !m_c_htf1 .RefreshRates() ) return (false);
    if( !m_c_htf2 .RefreshRates() ) return (false);
    if( !m_c_htf3 .RefreshRates() ) return (false);

    if( IsNewBar())
    { m_isBarBurned = false; }


//--- it is important to enter the market correctly, 
//--- but it is more important to exit it correctly...   
//--- first check if position exists - try to select it
   if(m_position.Select(Symbol()))
     {
      if(m_position.PositionType()==POSITION_TYPE_BUY)
        {
         //--- try to close or modify long position
         if(LongClosed())
            return(true);
            
         if(LongModified())
            return(true);
        }
        
      else
        {
         //--- try to close or modify short position
         if(ShortClosed())
            return(true);
            
         if(ShortModified())
            return(true);
        }
     }
//--- no opened position identified
   else if(m_isBarBurned == false)
     {
      //--- check for long position (BUY) possibility
      if(LongOpened())
         return(true);
         
      //--- check for short position (SELL) possibility
      if(ShortOpened())
         return(true);
     }
//--- exit without position processing
   return(false);
}


bool CTheStratExpert::InitCheckParameters()
{
//--- initial data checks

//--- check for right lots amount
    if(m_lots<m_symbol.LotsMin() || m_lots>m_symbol.LotsMax())
    {
        printf("Lots amount must be in the range from %f to %f",m_symbol.LotsMin(),m_symbol.LotsMax());
        return(false);
    }

    if(MathAbs(m_lots/m_symbol.LotsStep()-MathRound(m_lots/m_symbol.LotsStep()))>1.0E-10)
    {
        printf("Lots amount is not corresponding with lot step %f", m_symbol.LotsStep());
        return(false);
    }

//--- succeed
   return(true);
}

bool CTheStratExpert::InitIndicators(void)
{
   bool result = false;
   return result;
}

bool CTheStratExpert::LongClosed(void)
{
   bool result = false;
//--- should it be closed?
   m_position.Select(_Symbol);

   if(m_useExitTimeFrame)
   {
      Candle c_exit0(m_exitTimeframe, 0);
      c_exit0.RefreshRates();
      
      if(c_exit0.TwoDown() || c_exit0.Three())
      {
         m_isBarBurned = true;
         m_trade.PositionClose(m_position.Ticket());
      }
   }
   
    double prof = m_position.Profit();
    double comm = m_position.Commission();
    double balance = 0.01*m_account.Balance();
   
    // m_rewardRatio 1.7 / 100 
    //bool closeWithProfit = (m_position.Profit() - m_position.Commission()) > 0.01 *m_account.Balance();
    bool closeWithProfit = (m_position.Profit() - m_position.Commission()) > (m_rewardRatio/100.0) *m_account.Balance();
    bool closeWithLost =   (m_position.Profit() + m_position.Commission()) < ( (m_riskRatio/100.0)*m_account.Balance()*-1.0 );
    
    if(closeWithProfit || closeWithLost )
   // if( (m_position.Profit() - m_position.Commission()) > 0.01 * m_account.Balance())
   {
      m_isBarBurned = true;
      m_trade.PositionClose(m_position.Ticket());
   } 

//--- result
   return (false);
}


bool CTheStratExpert::ShortClosed(void)
{
//--- should it be closed?
    if(m_useExitTimeFrame)
    {
       Candle c_exit0(m_exitTimeframe, 0);
       if(c_exit0.TwoUp() || c_exit0.Three())
       {
         m_isBarBurned = true;
         m_trade.PositionClose(m_position.Ticket());
       }
    }
    
    double prof = m_position.Profit();
    double comm = m_position.Commission();
    double balance = 0.01*m_account.Balance();
    
    bool closeWithProfit = (m_position.Profit() - m_position.Commission()) > (m_rewardRatio/100.0) *m_account.Balance();
    bool closeWithLost =   (m_position.Profit() + m_position.Commission()) < ( (m_riskRatio/100.0)*m_account.Balance()*-1.0 );
    
    if(closeWithProfit || closeWithLost )
    {
        m_isBarBurned = true;
        m_trade.PositionClose(m_position.Ticket());
    }

//--- result
      return (false);
}

bool CTheStratExpert::LongModified(void)
{
   bool result = false;
//--- check for trailing stop
  
   double longStopLoss  = m_c_cur_1.GetLow();; //  - CalculateNormalizedDigits() - m_symbol.Spread(); 
   
   if(m_position.StopLoss() != longStopLoss)
   {
      // result = true;
      double tp = m_position.TakeProfit();
      m_trade.PositionModify(m_position.Ticket(), longStopLoss, tp);
   }
      
//--- result
   return result;
}

bool CTheStratExpert::ShortModified(void)
{
   bool result = false;
//--- check for trailing stop
   double shortStopLoss = m_c_cur_1.GetHigh(); //  + CalculateNormalizedDigits() + m_symbol.Spread();
   
   if(m_position.StopLoss() != shortStopLoss)
   {
      // result = true;
      double tp = m_position.TakeProfit();
      m_trade.PositionModify(m_position.Ticket(), shortStopLoss, tp);
   }
      
//--- result
   return result;
}

bool CTheStratExpert::LongOpened(void)
{
   bool result = false;
   double longStopLoss  = m_c_cur_1.GetLow(); //  - CalculateNormalizedDigits() - m_symbol.Spread(); 

//--- check for long position (BUY) possibility
   if( (m_c_htf1.TwoUp() || m_c_htf1.Three() ) && m_c_htf1.IsGreen() &&
       (m_c_htf2.TwoUp() || m_c_htf2.Three() ) && m_c_htf2.IsGreen() &&
       (m_c_htf3.TwoUp() || m_c_htf3.Three() ) && m_c_htf3.IsGreen() ) {
      
         double tp = 0.0;
      
         if(m_c_cur_0.TwoUp()   && m_c_cur_0.IsGreen() && 
            m_c_cur_1.TwoDown() && m_c_cur_1.IsRed()) {
            
            result = BuyMarket(longStopLoss, tp, "2-2 Bullish Reversal");
              
          } else if(m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() && (
                     (m_c_cur_1.One() && m_c_cur_2.Three() && m_c_cur_2.IsRed()) ||
                     (m_c_cur_1.One() && m_c_cur_2.One()   && m_c_cur_3.Three() && m_c_cur_3.IsRed())
                     ) ){
              result = BuyMarket(longStopLoss, tp, "3-1-2 Bullish Reversal");
              
          } else if(m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() && 
                    m_c_cur_1.TwoDown() && m_c_cur_1.IsGreen() && 
                    m_c_cur_2.Three() && m_c_cur_2.IsRed()){
                    
              result = BuyMarket(longStopLoss, 0.0, "3-2-2  Bullish Reversal");
              
          } else if(m_c_cur_0.TwoUp()   && m_c_cur_0.IsGreen() &&
                    m_c_cur_1.One()     && 
                    m_c_cur_2.TwoDown() && m_c_cur_2.IsRed() ){
                     
              result = BuyMarket(longStopLoss, tp, "2-1-2  Bullish Reversal");
              
          } else if(m_c_cur_0.TwoUp()  && m_c_cur_0.IsGreen() &&
                    m_c_cur_1.Three()  && m_c_cur_1.IsRed()){
                    
              result = BuyMarket(longStopLoss, tp, "3-2 Bullish Reversal");
              
          } else if (m_c_cur_0.TwoUp()   && m_c_cur_0.IsGreen() &&
                     m_c_cur_1.TwoDown() && m_c_cur_1.IsRed()   &&
                     m_c_cur_2.One() ) {
          
              result = BuyMarket(longStopLoss, 0.0, "1-2-2 Bullish RevStrat");
          
          }else  if(m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() && 
                    m_c_cur_1.One()   && 
                    m_c_cur_2.TwoUp() && m_c_cur_2.IsGreen() ){
                     
            result = BuyMarket(longStopLoss, 0.0, "2-1-2 Bullish Continuation");
              
          }else if(m_c_cur_0.IsGreen() && m_c_cur_0.TwoUp()  && 
                   m_c_cur_1.IsGreen() && m_c_cur_1.TwoUp()  && 
                   m_c_cur_2.IsGreen() && m_c_cur_2.TwoUp() ){
                   
              // result = BuyMarket(longStopLoss, "2-2-2 Bullish Continuation");
          }
    } else {
      //Print("NO UPSIDE FTFC OR LONG POSITION ALREADY OPEN");
    }

//--- result
   return result;
}

bool CTheStratExpert::ShortOpened(void)
{
    double shortStopLoss = m_c_cur_1.GetHigh(); // + CalculateNormalizedDigits() + m_symbol.Spread();

    bool result = false;
//--- check for short position (SELL) possibility
    if( (m_c_htf1.TwoDown() || m_c_htf1.Three() ) && m_c_htf1.IsRed() &&
        (m_c_htf2.TwoDown() || m_c_htf2.Three() ) && m_c_htf2.IsRed() &&
        (m_c_htf3.TwoDown() || m_c_htf3.Three() ) && m_c_htf3.IsRed() ) {
       
      double tp = 0.0;
       
      if(m_c_cur_0.TwoDown()  && m_c_cur_0.IsRed() && 
            m_c_cur_1.TwoUp()    && m_c_cur_1.IsGreen()) {
            
            result = SellMarket(shortStopLoss, tp, "2-2 Bearish Reversal");
           
       } else if(m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() && (
                  (m_c_cur_1.One()                        && m_c_cur_2.Three()  && m_c_cur_2.IsGreen()) ||
                  (m_c_cur_1.One()   && m_c_cur_2.One()   && m_c_cur_3.Three()  && m_c_cur_3.IsGreen()))){
            
            result = SellMarket(shortStopLoss, tp, "3-1-2  Bearish Reversal");
            
       } else if(m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() && 
                 m_c_cur_1.TwoUp()   && m_c_cur_1.IsRed() && 
                 m_c_cur_2.Three()   && m_c_cur_2.IsGreen()){
                 
            result = SellMarket(shortStopLoss, 0.0, "3-2-2  Bearish Reversal");
            
       }else if(m_c_cur_0.TwoDown()&& m_c_cur_0.IsRed() && 
                m_c_cur_1.One()    && 
                m_c_cur_2.TwoUp()  && m_c_cur_2.IsGreen() ){
                 
            result = SellMarket(shortStopLoss, tp, "2-1-2  Bearish Reversal");
            
       } else if(m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() && 
                 m_c_cur_1.Three()   && m_c_cur_1.IsGreen()){
                 
            result = SellMarket(shortStopLoss, tp, "3-2  Bearish Reversal");
           
       } else  if(m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() &&  
                  m_c_cur_1.One()     && 
                  m_c_cur_2.TwoDown() && m_c_cur_2.IsRed() ){
                  
            result = SellMarket(shortStopLoss, 0.0, "2-1-2 Bearish Continuation");
              
       } else if(m_c_cur_0.TwoDown() && m_c_cur_0.IsRed()   &&
                 m_c_cur_1.TwoUp()   && m_c_cur_1.IsGreen() &&
                 m_c_cur_2.One()) {
          
            result = SellMarket(shortStopLoss, 0.0, "1-2-2 Bearish RevStrat");
       
       }else if(m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() &&
                m_c_cur_1.TwoDown() && m_c_cur_1.IsRed() && 
                m_c_cur_2.TwoDown() && m_c_cur_2.IsRed() ){
                 
           // result = SellMarket(shortStopLoss, "2-2-2 Bearish Continuation");
       }
    } else {
      //Print("NO DOWNSIDE FTFC OR LONG POSITION ALREADY OPEN");
    }
      
//--- result
   return result;
}

//+------------------------------------------------------------------+
//| Buy                                                              |
//+------------------------------------------------------------------+
bool CTheStratExpert::BuyMarket(double stopLoss, double takeProfit, string comment)
{
    // printf("Sending buy order for %s", Symbol());

    bool res=false;
    double price = m_symbol.Ask();
    double lots = TradeSizeOptimized(price - stopLoss);

    //--- check for free money
    if(m_account.FreeMarginCheck(_Symbol, ORDER_TYPE_BUY, lots, price)<0.0)
    {
        printf("We have no money. Free Margin = %f",m_account.FreeMargin());
    }
    else
    {
        //--- open position
        if(m_trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lots, price, stopLoss, takeProfit, comment))
        {
            printf("Position by %s to be opened",Symbol());
        }
        else
        {
            printf("Error opening BUY position by %s : '%s'",Symbol(),m_trade.ResultComment());
            printf("Open parameters : price=%f,SL=%f",price, stopLoss);
        }
    }

    return (res);
}

//+------------------------------------------------------------------+
//| Sell                                                             |
//+------------------------------------------------------------------+
bool CTheStratExpert::SellMarket(double stopLoss, double takeProfit, string comment)
{
	// Print("Sending sell order for ", Symbol());

    bool res=false;
    double price = m_symbol.Bid();
    double lots = TradeSizeOptimized(stopLoss - price);

    //--- check for free money
    if(m_account.FreeMarginCheck(_Symbol, ORDER_TYPE_SELL, lots, price)<0.0)
    {
        printf("We have no money. Free Margin = %f",m_account.FreeMargin());
    }
    else
    {
        //--- open position
        if(m_trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lots, price, stopLoss, takeProfit, comment))
        {
            printf("Position by %s to be opened",Symbol());
        }
        else
        {
            printf("Error opening BUY position by %s : '%s'",Symbol(),m_trade.ResultComment());
            printf("Open parameters : price=%f,SL=%f",price, stopLoss);
        }
    }
    return (res);
}

//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double CTheStratExpert::TradeSizeOptimized(double stopLoss)
{
    
//--- select lot size
    bool MM  = false;  	// If true - Parabolic SAR based risk sizing

    Print("Stop Loss in points : ", stopLoss);
	if (!MM) 
        return (m_lots);

    double Size, RiskMoney, PositionSize = 0;

    if (m_symbol.CurrencyBase() == "") 
        return(0);

    if (m_fixedBalance > 0)
    {
        Size = m_fixedBalance;
    }
    else if (m_useEquityInsteadOfBalance)
    {
        Size = m_account.Equity();
    }
    else
    {
        Size = m_account.Balance();
    }

    if (!m_useMoneyInsteadOfPercentage)
    {
        RiskMoney = Size * m_risk / 100;
    }
    else
    {
        RiskMoney = m_moneyRisk;
    }

    double UnitCost = m_symbol.TickValue();
    double TickSize = m_symbol.TickSize();

    if ((stopLoss != 0) && (UnitCost != 0) && (TickSize != 0))
    {
        PositionSize = NormalizeDouble(RiskMoney / (stopLoss * UnitCost / TickSize), m_symbol.Digits());
    }

    PositionSize = MathMax(PositionSize, m_symbol.LotsMin());
    PositionSize = MathMin(PositionSize, m_symbol.LotsMax());
   
    PositionSize = m_lotFactor * PositionSize;
    double LotStep = m_symbol.LotsStep();
    PositionSize = PositionSize - MathMod(PositionSize, LotStep);
   
    printf("Position Size: %.3f", PositionSize);

    return(PositionSize);
}

double CTheStratExpert::CalculateNormalizedDigits()
{
   // If there are 3 or fewer digits (JPY, for example), then return 0.01, which is the pip value.
   if (_Digits <= 3){
      return(0.01);
   }
   // If there are 4 or more digits, then return 0.0001, which is the pip value.
   else if (_Digits >= 4){
      return(0.0001);
   }
   // In all other cases, return 0.
   else 
    return(0);
}


bool CTheStratExpert::IsNewBar() { 
  
   datetime currBar  =  iTime(Symbol(), m_entryTimeframe, 0);
   
   if(m_lastBar != currBar) {
      m_lastBar  =  currBar;
      return (true); 
   } else {
      return(false);
   }
}
