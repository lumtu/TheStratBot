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

enum EnTrailingStop
{
   Use_None,
   Use_PSAR,
   Use_Bar2Bar,
};

enum EnTakeProfitType
{
    None = 0,
    Reward1 = 1,
    Reward2 = 2,
    Reward3 = 3,
    Reward4 = 4,
    Reward5 = 5,
    TargetTF = 10,
    TargetTF_R1 = 11,
};

class CTheStratExpert
{
protected:
    double m_adjusted_point;  // point value adjusted for 3 or 5 points
    CTrade m_trade;           // trading object
    CSymbolInfo m_symbol;     // symbol info object
    CPositionInfo m_position; // trade position object
    CAccountInfo m_account;   // account info wrapper
    
    CiSAR m_sar;            // object-indicator
    EnTrailingStop m_trailingStop;
    
    bool m_useMoneyInsteadOfPercentage;
    bool m_useEquityInsteadOfBalance; // Eigenkapital statt Balance
    double m_fixedBalance;            // If greater than 0, position size calculator will use it instead of actual account balance.
    double m_moneyRisk;               // Risk tolerance in base currency
    double m_risk;                    // Risk tolerance in percentage points
    int m_lotFactor;

    ENUM_TIMEFRAMES m_exitTimeframe;

    bool m_useTheStratExit;
    ENUM_TIMEFRAMES m_entryTimeframe;

    EnTakeProfitType m_takeProfitType;
    ENUM_TIMEFRAMES m_targetTimeframe;
    bool m_useTargets;

    datetime m_lastBar;
    bool m_isBarBurned;

    bool m_useReversal_22;
    bool m_useReversal_312;
    bool m_useReversal_3112;
    bool m_useReversal_322;
    bool m_useReversal_212;
    bool m_useReversal_32; // false (M30 and H1)
    bool m_useReversal_122;
    bool m_useContinuation_212; // false
    bool m_useContinuation_222; // false
    
    Candle m_c_cur_0;
    Candle m_c_cur_1;
    Candle m_c_cur_2;
    Candle m_c_cur_3;
    Candle m_c_htf1;
    Candle m_c_htf2;
    Candle m_c_htf3;

    int m_volumeAvgAmount;

public:
   int m_startHour;
   int m_startMin;
   int m_endHour;
   int m_endMin;


public:
    CTheStratExpert(ENUM_TIMEFRAMES exitTF,
                    ENUM_TIMEFRAMES entryTF,
                    ENUM_TIMEFRAMES lowHigherTF,
                    ENUM_TIMEFRAMES midHigherTF,
                    ENUM_TIMEFRAMES bigHigherTF);
    ~CTheStratExpert(void);
    bool Init(void);
    void Deinit(void);
    bool Processing(void);

    void SetUseMoneyInsteadOfPercentage(bool val) { m_useMoneyInsteadOfPercentage = val; }
    void SetUseEquityInsteadOfBalance(bool val) { m_useEquityInsteadOfBalance = val; }
    void SetFixedBalance(double fixedBalance) { m_fixedBalance = fixedBalance; }
    void SetMoneyRisk(double moneyRisk) { m_moneyRisk = moneyRisk; }
    void SetRisk(double risk) { m_risk = risk; }
    void SetLotFactor(int lotFactor) { m_lotFactor = lotFactor; }

    void SetTrailingStop(EnTrailingStop trailingStop) {m_trailingStop = trailingStop;}
    void UseTheStratExit(bool useTheStratExit)
    {
        m_useTheStratExit = useTheStratExit;
    }
    
    void UseTargetTimeframe(EnTakeProfitType takeProfitType, ENUM_TIMEFRAMES timeFrame)  
    {
      m_takeProfitType = takeProfitType;
      m_targetTimeframe = timeFrame;
    }

    void UseVolumeAVG(int volumeAvgAmount) {
      m_volumeAvgAmount = volumeAvgAmount;
    }
 
    void UseReversal_22(bool enable)  { m_useReversal_22 = enable; }
    void UseReversal_312(bool enable)  { m_useReversal_312 = enable; }
    void UseReversal_3112(bool enable)  { m_useReversal_3112 = enable; }
    void UseReversal_322(bool enable)  { m_useReversal_322 = enable; }
    void UseReversal_212(bool enable)  { m_useReversal_212 = enable; }
    void UseReversal_32(bool enable)  { m_useReversal_32 = enable; }
    void UseReversal_122(bool enable)  { m_useReversal_122 = enable; }
    void UseContinuation_212(bool enable)  { m_useContinuation_212 = enable; }
    void UseContinuation_222(bool enable)  { m_useContinuation_222 = enable; }





protected:
    bool InitCheckParameters();
    bool InitIndicators(void);
    bool LongClosed(void);
    bool ShortClosed(void);
    bool LongModified(void);
    bool ShortModified(void);
    bool LongOpened(void);
    bool ShortOpened(void);

    bool BuyMarket(double stopLoss, string comment);
    bool SellMarket(double stopLoss, string comment);
    double TradeSizeOptimized(double stopLoss);
    double CalculateNormalizedDigits();

    bool IsNewBar();
    
    double FindTargetPrice(double stopLoss);
    
    bool IsVolumeToLow();
    bool IsInTime();
    
    bool CheckTrailingStopLong(CPositionInfo *position,double &sl);
    bool CheckTrailingStopShort(CPositionInfo *position,double &sl);
    
    double Round(double price);

};

CTheStratExpert::CTheStratExpert(ENUM_TIMEFRAMES exitTF,
                                 ENUM_TIMEFRAMES entryTF,
                                 ENUM_TIMEFRAMES lowHigherTF,
                                 ENUM_TIMEFRAMES midHigherTF,
                                 ENUM_TIMEFRAMES bigHigherTF)
    : m_adjusted_point(0)
    , m_useMoneyInsteadOfPercentage(false)
    , m_useEquityInsteadOfBalance(true)
    , m_fixedBalance(0.0)
    , m_moneyRisk(0.0)
    , m_risk(1.0)
    , m_lotFactor(1)
    , m_c_cur_0(entryTF, 0)
    , m_c_cur_1(entryTF, 1)
    , m_c_cur_2(entryTF, 2)
    , m_c_cur_3(entryTF, 3)
    , m_c_htf1(lowHigherTF, 0)
    , m_c_htf2(midHigherTF, 0)
    , m_c_htf3(bigHigherTF, 0)
    , m_useTheStratExit(false)
    , m_exitTimeframe(exitTF)
    , m_entryTimeframe(entryTF)
    , m_lastBar(0)
    , m_isBarBurned(false)
    , m_volumeAvgAmount(0)
   , m_startHour(0)
   , m_startMin(0)
   , m_endHour(0)
   , m_endMin(0)

{
}

CTheStratExpert::~CTheStratExpert(void)
{
}

bool CTheStratExpert::Init(void)
{
    //--- initialize common information
    m_symbol.Name(Symbol()); // symbol

    if (!InitCheckParameters())
        return (false);

    if(!InitIndicators())
      return false;

    return true;
}

void CTheStratExpert::Deinit(void)
{
}

bool CTheStratExpert::Processing(void)
{
    //--- refresh rates
    if (!m_symbol.RefreshRates())
        return (false);

    if (!m_c_cur_0.RefreshRates())
        return (false);
    if (!m_c_cur_1.RefreshRates())
        return (false);
    if (!m_c_cur_2.RefreshRates())
        return (false);
    if (!m_c_cur_3.RefreshRates())
        return (false);
    if (!m_c_htf1.RefreshRates())
        return (false);
    if (!m_c_htf2.RefreshRates())
        return (false);
    if (!m_c_htf3.RefreshRates())
        return (false);


     m_sar.Refresh();

    if (IsNewBar())
    {
        m_isBarBurned = false;
    }

    //--- it is important to enter the market correctly,
    //--- but it is more important to exit it correctly...
    //--- first check if position exists - try to select it
    if (m_position.Select(Symbol()))
    {
        if (m_position.PositionType() == POSITION_TYPE_BUY)
        {
            //--- try to close or modify long position
            if (LongClosed())
                return (true);

            if (LongModified())
                return (true);
        }

        else
        {
            //--- try to close or modify short position
            if (ShortClosed())
                return (true);

            if (ShortModified())
                return (true);
        }
    }
    //--- no opened position identified
    else if (m_isBarBurned == false)
    {
        //--- check for long position (BUY) possibility
        if (LongOpened())
            return (true);

        //--- check for short position (SELL) possibility
        if (ShortOpened())
            return (true);
    }
    //--- exit without position processing
    return (false);
}

bool CTheStratExpert::InitCheckParameters()
{
    //--- initial data checks

    //--- succeed
    return (true);
}

bool CTheStratExpert::InitIndicators(void)
{
   double m_psarStep = 0.02;
   double m_psarMaximum = 0.2;
     if(!m_sar.Create(m_symbol.Name(),m_entryTimeframe, m_psarStep, m_psarMaximum))
     {
        printf(__FUNCTION__+": error initializing object");
      return(false);
     }

    return true;
}

bool CTheStratExpert::LongClosed(void)
{
    //--- should it be closed?
    m_position.Select(_Symbol);

    if (m_useTheStratExit)
    {
        Candle c_exit0(m_exitTimeframe, 0);
        c_exit0.RefreshRates();

        if (c_exit0.TwoDown() || c_exit0.Three())
        {
            m_trade.PositionClose(m_position.Ticket());
        }
    }


    //--- result
    return (false);
}

bool CTheStratExpert::ShortClosed(void)
{
    //--- should it be closed?
    m_position.Select(_Symbol);

    if (m_useTheStratExit)
    {
        Candle c_exit0(m_exitTimeframe, 0);
        if (c_exit0.TwoUp() || c_exit0.Three())
        {
            m_trade.PositionClose(m_position.Ticket());
        }
        return (false);
    }


    //--- result
    return (false);
}

bool CTheStratExpert::LongModified(void)
{
    bool result = false;

    //--- check for trailing stop
    if(m_trailingStop == EnTrailingStop::Use_PSAR)
    {
       double new_sl=0.0;
       if( CheckTrailingStopLong(&m_position, new_sl) )
       { 
           double old_sl = m_position.StopLoss();
           if(old_sl < new_sl)
           {
               double tp = m_position.TakeProfit();
               m_trade.PositionModify(m_position.Ticket(), Round(new_sl), Round(tp));
           }
       }
    }
    else if(m_trailingStop == EnTrailingStop::Use_Bar2Bar)
    {
       if(m_c_cur_1.One())
       { return result; }
         
       double newStopLoss = Round( m_c_cur_1.GetLow() );
          
       if (m_position.StopLoss() < newStopLoss)
       {
           // result = true;
           double tp = m_position.TakeProfit();
           m_trade.PositionModify(m_position.Ticket(), Round(newStopLoss), Round(tp));
       }
    }
    //--- result
    return result;
}

bool CTheStratExpert::ShortModified(void)
{
    bool result = false;

    if(m_trailingStop == EnTrailingStop::Use_PSAR)
    {
       double new_sl=0.0;
       if( CheckTrailingStopShort(&m_position, new_sl) )
       {
           double old_sl = m_position.StopLoss();
           if( old_sl > new_sl)
           {
              double tp = m_position.TakeProfit();
              m_trade.PositionModify(m_position.Ticket(), Round(new_sl), Round(tp));
           }
       }
    }
    else
    {
       if(m_c_cur_1.One())
       { return result; }
    
       //--- check for trailing stop
       double shortStopLoss = Round( m_c_cur_1.GetHigh() ); //  + CalculateNormalizedDigits() + m_symbol.Spread();
   
       if (m_position.StopLoss() != shortStopLoss)
       {
           // result = true;
           double tp = m_position.TakeProfit();
           m_trade.PositionModify(m_position.Ticket(), Round(shortStopLoss), Round(tp));
       }
   }
    //--- result
    return result;
}

bool CTheStratExpert::LongOpened(void)
{
    bool result = false;
    double longStopLoss = Round(m_c_cur_1.GetLow()); //  - CalculateNormalizedDigits() - m_symbol.Spread();

    //--- check for long position (BUY) possibility
    if ((m_c_htf1.TwoUp() || m_c_htf1.Three()) && m_c_htf1.IsGreen() &&
        (m_c_htf2.TwoUp() || m_c_htf2.Three()) && m_c_htf2.IsGreen() &&
        (m_c_htf3.TwoUp() || m_c_htf3.Three()) && m_c_htf3.IsGreen())
    {

        if (m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() &&
            m_c_cur_1.TwoDown() && ( m_c_cur_1.IsRed() || m_c_cur_1.IsShooterUp() ) )
        {
            if (m_useReversal_22)
                result = BuyMarket(longStopLoss, "2-2 Bullish Reversal");
        }
        else if (m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() && 
                 m_c_cur_1.One()   && 
                 m_c_cur_2.Three() && m_c_cur_2.IsRed() )
        {
            if (m_useReversal_312)
                result = BuyMarket(longStopLoss, "3-1-2 Bullish Reversal");
        }
        else if (m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() && 
                 m_c_cur_1.One() && 
                 m_c_cur_2.One() && 
                 m_c_cur_3.Three() && m_c_cur_3.IsRed() )
        {
            if (m_useReversal_3112)
                result = BuyMarket(longStopLoss, "3-1-1-2 Bullish Reversal");
        }
        else if (m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() &&
                 m_c_cur_1.TwoDown() && m_c_cur_1.IsGreen() &&
                 m_c_cur_2.Three() && m_c_cur_2.IsRed())
        {
            if (m_useReversal_322)
                result = BuyMarket(longStopLoss, "3-2-2  Bullish Reversal");
        }
        else if (m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() &&
                 m_c_cur_1.One() &&
                 m_c_cur_2.TwoDown() && m_c_cur_2.IsRed())
        {
            if(m_useReversal_212)
                result = BuyMarket(longStopLoss, "2-1-2  Bullish Reversal");
        }
        else if (m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() &&
                 m_c_cur_1.Three() && m_c_cur_1.IsRed())
        {
            if(m_useReversal_32)
                result = BuyMarket(longStopLoss, "3-2 Bullish Reversal");
        }
        else if (m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() &&
                 m_c_cur_1.TwoDown() && m_c_cur_1.IsRed() &&
                 m_c_cur_2.One())
        {
            if(m_useReversal_122)
                result = BuyMarket(longStopLoss, "1-2-2 Bullish RevStrat");
        }
        else if (m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() &&
                 m_c_cur_1.One() &&
                 m_c_cur_2.TwoUp() && m_c_cur_2.IsGreen())
        {
            if(m_useContinuation_212)
                result = BuyMarket(longStopLoss, "2-1-2 Bullish Continuation");
        }
        else if (m_c_cur_0.IsGreen() && m_c_cur_0.TwoUp() &&
                 m_c_cur_1.IsGreen() && m_c_cur_1.TwoUp() &&
                 m_c_cur_2.IsGreen() && m_c_cur_2.TwoUp())
        {
            if(m_useContinuation_222)
                result = BuyMarket(longStopLoss, "2-2-2 Bullish Continuation");
        }
    }
    else
    {
        // Print("NO UPSIDE FTFC OR LONG POSITION ALREADY OPEN");
    }

    //--- result
    return result;
}

bool CTheStratExpert::ShortOpened(void)
{
    double shortStopLoss = Round( m_c_cur_1.GetHigh() ); // + CalculateNormalizedDigits() + m_symbol.Spread();

    bool result = false;
    //--- check for short position (SELL) possibility
    if ((m_c_htf1.TwoDown() || m_c_htf1.Three()) && m_c_htf1.IsRed() &&
        (m_c_htf2.TwoDown() || m_c_htf2.Three()) && m_c_htf2.IsRed() &&
        (m_c_htf3.TwoDown() || m_c_htf3.Three()) && m_c_htf3.IsRed())
    {

        if (m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() &&
            m_c_cur_1.TwoUp() && (m_c_cur_1.IsGreen() || m_c_cur_1.IsShooterDown() ) )
        {
            if(m_useReversal_22)
                result = SellMarket(shortStopLoss, "2-2 Bearish Reversal");
        }
        else if (m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() && 
                 m_c_cur_1.One() && 
                 m_c_cur_2.Three() && m_c_cur_2.IsGreen())
        {
            if(m_useReversal_312)
                result = SellMarket(shortStopLoss, "3-1-2  Bearish Reversal");
        }
        else if (m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() && 
                 m_c_cur_1.One() && 
                 m_c_cur_2.One() && 
                 m_c_cur_3.Three() && m_c_cur_3.IsGreen())
        {
            if(m_useReversal_3112)
                result = SellMarket(shortStopLoss, "3-1-1-2  Bearish Reversal");
        }
        else if (m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() &&
                 m_c_cur_1.TwoUp() && m_c_cur_1.IsRed() &&
                 m_c_cur_2.Three() && m_c_cur_2.IsGreen())
        {
            if(m_useReversal_322)
                result = SellMarket(shortStopLoss, "3-2-2  Bearish Reversal");
        }
        else if (m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() &&
                 m_c_cur_1.One() &&
                 m_c_cur_2.TwoUp() && m_c_cur_2.IsGreen())
        {
            if(m_useReversal_212)
                result = SellMarket(shortStopLoss, "2-1-2  Bearish Reversal");
        }
        else if (m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() &&
                 m_c_cur_1.Three() && m_c_cur_1.IsGreen())
        {
            if(m_useReversal_32)
                result = SellMarket(shortStopLoss, "3-2  Bearish Reversal");
        }
        else if (m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() &&
                 m_c_cur_1.TwoUp() && m_c_cur_1.IsGreen() &&
                 m_c_cur_2.One())
        {
            if(m_useReversal_122)
                result = SellMarket(shortStopLoss, "1-2-2 Bearish RevStrat");
        }
        else if (m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() &&
                 m_c_cur_1.One() &&
                 m_c_cur_2.TwoDown() && m_c_cur_2.IsRed())
        {
            if(m_useContinuation_212)
                result = SellMarket(shortStopLoss, "2-1-2 Bearish Continuation");
        }
        else if (m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() &&
                 m_c_cur_1.TwoDown() && m_c_cur_1.IsRed() &&
                 m_c_cur_2.TwoDown() && m_c_cur_2.IsRed())
        {
            if(m_useContinuation_222)
                result = SellMarket(shortStopLoss, "2-2-2 Bearish Continuation");
        }
    }
    else
    {
        // Print("NO DOWNSIDE FTFC OR LONG POSITION ALREADY OPEN");
    }

    //--- result
    return result;
}

//+------------------------------------------------------------------+
//| Buy                                                              |
//+------------------------------------------------------------------+
bool CTheStratExpert::BuyMarket(double stopLoss, string comment)
{
    // printf("Sending buy order for %s", Symbol());
    if(IsVolumeToLow() || !IsInTime())
      return (false);


    double price = m_symbol.Ask();
    
    //  Ist der Preis zu weit vom letztem Tief entfernt?
    double range = m_symbol.TickSize();
    double lastHigh = m_c_cur_1.GetHigh();
    if(price > (lastHigh +(range*5) ))
    {
       //m_isBarBurned = true;
       return (false);
    }

    
    double lots = TradeSizeOptimized(price - stopLoss);
    double takeProfit = FindTargetPrice(stopLoss);
    
    //--- check for free money
    if (m_account.FreeMarginCheck(_Symbol, ORDER_TYPE_BUY, lots, price) < 0.0)
    {
        printf("We have no money. Free Margin = %f", m_account.FreeMargin());
    }
    else
    {
        //--- open position
        if (m_trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lots, Round(price), Round(stopLoss), Round(takeProfit), comment))
        {
            m_isBarBurned = true;
            printf("Position by %s to be opened", Symbol());
        }
        else
        {
            printf("Error opening BUY position by %s : '%s'", Symbol(), m_trade.ResultComment());
            printf("Open parameters : price=%f,SL=%f", price, stopLoss);
        }
    }

    return (false);
}

//+------------------------------------------------------------------+
//| Sell                                                             |
//+------------------------------------------------------------------+
bool CTheStratExpert::SellMarket(double stopLoss, string comment)
{
    // Print("Sending sell order for ", Symbol());
    if(IsVolumeToLow() || !IsInTime())
      return (false);
      
    double price = m_symbol.Bid();
    
    //  Ist der Preis zu weit vom letztem Tief entfernt?
    double range = m_symbol.TickSize();
    double lastLow = m_c_cur_1.GetLow();
    if(price < (lastLow -(range*5) ))
    {
       // m_isBarBurned = true;
       return (false);
    }
    
    
    double lots = TradeSizeOptimized(stopLoss - price);
    double takeProfit = FindTargetPrice(stopLoss);

    //--- check for free money
    if (m_account.FreeMarginCheck(_Symbol, ORDER_TYPE_SELL, lots, Round(price)) < 0.0)
    {
        printf("We have no money. Free Margin = %f", m_account.FreeMargin());
    }
    else
    {
        //--- open position
        if (m_trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lots, Round(price), Round(stopLoss), Round(takeProfit), comment))
        {
            m_isBarBurned = true;
            printf("Position by %s to be opened", Symbol());
        }
        else
        {
            printf("Error opening BUY position by %s : '%s'", Symbol(), m_trade.ResultComment());
            printf("Open parameters : price=%f,SL=%f", price, stopLoss);
        }
    }
    
    return (false);
}



//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double CTheStratExpert::TradeSizeOptimized(double stopLoss)
{

    double Size, RiskMoney, PositionSize = 0;

    if (m_symbol.CurrencyBase() == "")
        return (0);

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

    return (PositionSize);
}

double CTheStratExpert::CalculateNormalizedDigits()
{
    // If there are 3 or fewer digits (JPY, for example), then return 0.01, which is the pip value.
    if (_Digits <= 3)
    {
        return (0.01);
    }
    // If there are 4 or more digits, then return 0.0001, which is the pip value.
    else if (_Digits >= 4)
    {
        return (0.0001);
    }
    // In all other cases, return 0.
    else
        return (0);
}

bool CTheStratExpert::IsNewBar()
{

    datetime currBar = iTime(Symbol(), m_entryTimeframe, 0);

    if (m_lastBar != currBar)
    {
        m_lastBar = currBar;
        return (true);
    }
    else
    {
        return (false);
    }
}

double CTheStratExpert::FindTargetPrice(double stopLoss)
{
   double price = m_symbol.Ask();
   bool isLong = (price > stopLoss);
   
   if(m_takeProfitType == EnTakeProfitType::Reward2 ||
      m_takeProfitType == EnTakeProfitType::Reward3 ||
      m_takeProfitType == EnTakeProfitType::Reward4 ||
      m_takeProfitType == EnTakeProfitType::Reward5 )
   {
      double diff = MathAbs( (price - stopLoss)*((int)m_takeProfitType));
      if(isLong)   
         return Round( NormalizeDouble(price + diff, m_symbol.Digits()) );
      else
         return Round( NormalizeDouble(price - diff, m_symbol.Digits()) );
   }
   
   else if(m_takeProfitType == EnTakeProfitType::TargetTF || 
           m_takeProfitType == EnTakeProfitType::TargetTF_R1)
   {
       
       double spread    = m_symbol.Ask()-m_symbol.Bid();

       int shift = 1;
       if(isLong)
       {
          
          double hight = 0.0;
          double minTarget = price + (spread*3);
          if(m_takeProfitType == EnTakeProfitType::TargetTF_R1)
          {
            minTarget = (price + MathAbs(price - stopLoss));
          }
          
          do
          {
             hight = iHigh(m_symbol.Name(), m_targetTimeframe, shift++);
             if(hight == 0.0)
               return 0.0;
                
          }
          while(hight <minTarget );
          
          return Round( hight );
       }
       else
       {
          double low = 0.0;
          double minTarget = price - (spread*2);
          if(m_takeProfitType == EnTakeProfitType::TargetTF_R1)
          {
            minTarget = price - MathAbs(stopLoss - price);
          }

          do
          {
             low = iLow(m_symbol.Name(), m_targetTimeframe, shift++);
             if(low == 0.0)
               return 0.0;
                
          }
          while(low > minTarget );
          
          return Round( low );
       }
   }
   
   
   return 0.0;
}


bool CTheStratExpert::IsVolumeToLow()
{
   if(m_volumeAvgAmount <= 0)
      return false;
      
   int amount = MathMax(1, m_volumeAvgAmount);
   long volumeAVG=0.0;
   long volumesBuffer[];
   ENUM_APPLIED_VOLUME inpVolumeType=VOLUME_TICK; // Volumes
   if(CopyTickVolume(_Symbol, m_entryTimeframe, 0, amount, volumesBuffer)>0)
   {
      for(int i=0; i<amount; ++i)
      {
         volumeAVG += volumesBuffer[i];
      }
      volumeAVG = volumeAVG / amount;
   }
   
   if(volumeAVG < volumesBuffer[0]) {
      // zuwenig volumen
      return true;
   }
   
   return false;
}


bool CTheStratExpert::IsInTime()
{
   if(m_startHour == 0 && m_startMin == 0
     && m_endHour == 0 && m_endMin == 0)
     {
      return true;
     }


   MqlDateTime timeLocal;
   TimeCurrent(timeLocal);
   

   int curr = (timeLocal.hour * 1000) + (timeLocal.min);
   int start = (m_startHour * 1000) + (m_startMin);
   int end = (m_endHour * 1000) + (m_endMin);
   
   if( curr > start && curr < end)
   {
      return true;
   }
   

   return false;
}



//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for long position.          |
//+------------------------------------------------------------------+
bool CTheStratExpert::CheckTrailingStopLong(CPositionInfo *position,double &sl)
  {
  // PSAR
//--- check
   if(position==NULL)
      return(false);
      
     
//---
    double unitCost = m_symbol.TickValue();
    double tickSize = m_symbol.TickSize();

   double level =NormalizeDouble(m_symbol.Bid()-m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
   double new_sl=Round( m_sar.Main(0) );
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
//---
   sl=EMPTY_VALUE;
   
   if(new_sl>base && new_sl<level)
      sl=new_sl;
//---
   return(sl!=EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for short position.         |
//+------------------------------------------------------------------+
bool CTheStratExpert::CheckTrailingStopShort(CPositionInfo *position,double &sl)
  {
  /// PSAR
  
  
//--- check
   if(position==NULL)
      return(false);
      
//---
  // NormalizeDouble(RiskMoney / (stopLoss * UnitCost / TickSize), m_symbol.Digits());
    double unitCost = m_symbol.TickValue();
    double tickSize = m_symbol.TickSize();
   double sarMain = m_sar.Main(0);
   double spread= m_symbol.Spread();
   double point = m_symbol.Point();
   int digits = m_symbol.Digits();
   
   double level =NormalizeDouble(m_symbol.Ask()+m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
   double new_sl= Round( (sarMain + spread * point) );
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
//---
   sl=EMPTY_VALUE;
   
   if(new_sl<base && new_sl>level)
      sl=new_sl;
//---
   return(sl!=EMPTY_VALUE);
  }
  
  
double CTheStratExpert::Round(double price)
{
    double tick_size = m_symbol.TickSize();

   return NormalizeDouble( round( price / tick_size ) * tick_size, m_symbol.Digits() );    
   
}