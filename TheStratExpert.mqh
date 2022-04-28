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
    double m_adjusted_point;  // point value adjusted for 3 or 5 points
    double m_lots;            // Initial position size
    CTrade m_trade;           // trading object
    CSymbolInfo m_symbol;     // symbol info object
    CPositionInfo m_position; // trade position object
    CAccountInfo m_account;   // account info wrapper
    bool m_useMoneyInsteadOfPercentage;
    bool m_useEquityInsteadOfBalance; // Eigenkapital statt Balance
    double m_fixedBalance;            // If greater than 0, position size calculator will use it instead of actual account balance.
    double m_moneyRisk;               // Risk tolerance in base currency
    double m_risk;                    // Risk tolerance in percentage points
    int m_lotFactor;
    bool m_useFixLots; // Use fix lots
    bool m_useTargets;
    bool m_useExitTimeFrame;
    bool m_useTargetTimeframe;
    ENUM_TIMEFRAMES m_exitTimeframe;
    ENUM_TIMEFRAMES m_entryTimeframe;
    ENUM_TIMEFRAMES m_targetTimeframe;
    datetime m_lastBar;
    bool m_isBarBurned;
    double m_riskRatio;
    double m_rewardRatio;
    int m_volumeAvgAmount;
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
public:
   int m_startHour;
   int m_startMin;
   int m_endHour;
   int m_endMin;


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

    void UseFixLots(bool useFixLots)
    {
        m_useFixLots = useFixLots;
    }

    void UseExitTimeFrame(bool useExitTimeFrame)
    {
        m_useExitTimeFrame = useExitTimeFrame;
    }
    
    void UseTargetTimeframe(bool useit, ENUM_TIMEFRAMES timeFrame)  
    {
      m_useTargetTimeframe = useit;
      m_targetTimeframe = timeFrame;
    }
    
    void SetRR(double riskRatio, double rewardRatio)
    {
        m_riskRatio = riskRatio;
        m_rewardRatio = rewardRatio;
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
    , m_c_htf1(lowHigherTF, 0)
    , m_c_htf2(midHigherTF, 0)
    , m_c_htf3(bigHigherTF, 0)
    , m_useExitTimeFrame(false)
    , m_exitTimeframe(exitTF)
    , m_entryTimeframe(entryTF)
    , m_lastBar(0)
    , m_isBarBurned(false)
    , m_riskRatio(1)
    , m_rewardRatio(1.7)
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

    //--- check for right lots amount
    if (m_lots < m_symbol.LotsMin() || m_lots > m_symbol.LotsMax())
    {
        printf("Lots amount must be in the range from %f to %f", m_symbol.LotsMin(), m_symbol.LotsMax());
        return (false);
    }

    if (MathAbs(m_lots / m_symbol.LotsStep() - MathRound(m_lots / m_symbol.LotsStep())) > 1.0E-10)
    {
        printf("Lots amount is not corresponding with lot step %f", m_symbol.LotsStep());
        return (false);
    }

    //--- succeed
    return (true);
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

    if (m_useExitTimeFrame)
    {
        Candle c_exit0(m_exitTimeframe, 0);
        c_exit0.RefreshRates();

        if (c_exit0.TwoDown() || c_exit0.Three())
        {
            m_isBarBurned = true;
            m_trade.PositionClose(m_position.Ticket());
        }
    }

    double prof = m_position.Profit();
    double comm = m_position.Commission();
    double balance = 0.01 * m_account.Balance();

    // m_rewardRatio 1.7 / 100
    bool closeWithLost = false;
    bool closeWithProfit = (m_position.Profit() - m_position.Commission()) > (m_rewardRatio / 100.0) * m_account.Balance();
    // closeWithLost = (m_position.Profit() + m_position.Commission()) < ((m_riskRatio / 100.0) * m_account.Balance() * -1.0);

    if (closeWithProfit || closeWithLost)
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
    if (m_useExitTimeFrame)
    {
        Candle c_exit0(m_exitTimeframe, 0);
        if (c_exit0.TwoUp() || c_exit0.Three())
        {
            m_isBarBurned = true;
            m_trade.PositionClose(m_position.Ticket());
        }
        return (false);
    }

    double prof = m_position.Profit();
    double comm = m_position.Commission();
    double balance = 0.01 * m_account.Balance();

    bool closeWithLost = false;
    bool closeWithProfit = (m_position.Profit() - m_position.Commission()) > (m_rewardRatio / 100.0) * m_account.Balance();
    
    // closeWithLost = (m_position.Profit() + m_position.Commission()) < ((m_riskRatio / 100.0) * m_account.Balance() * -1.0);

    if (closeWithProfit || closeWithLost)
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

    double newStopLoss = m_c_cur_1.GetLow();
    ; //  - CalculateNormalizedDigits() - m_symbol.Spread();
    
    if (m_position.StopLoss() != newStopLoss)
    {
        // result = true;
        double tp = m_position.TakeProfit();
        m_trade.PositionModify(m_position.Ticket(), newStopLoss, tp);
    }

    //--- result
    return result;
}

bool CTheStratExpert::ShortModified(void)
{
    bool result = false;
    //--- check for trailing stop
    double shortStopLoss = m_c_cur_1.GetHigh(); //  + CalculateNormalizedDigits() + m_symbol.Spread();

    if (m_position.StopLoss() != shortStopLoss)
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
    double longStopLoss = m_c_cur_1.GetLow(); //  - CalculateNormalizedDigits() - m_symbol.Spread();

    //--- check for long position (BUY) possibility
    if ((m_c_htf1.TwoUp() || m_c_htf1.Three()) && m_c_htf1.IsGreen() &&
        (m_c_htf2.TwoUp() || m_c_htf2.Three()) && m_c_htf2.IsGreen() &&
        (m_c_htf3.TwoUp() || m_c_htf3.Three()) && m_c_htf3.IsGreen())
    {

        if (m_c_cur_0.TwoUp() && m_c_cur_0.IsGreen() &&
            m_c_cur_1.TwoDown() && m_c_cur_1.IsRed())
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
    double shortStopLoss = m_c_cur_1.GetHigh(); // + CalculateNormalizedDigits() + m_symbol.Spread();

    bool result = false;
    //--- check for short position (SELL) possibility
    if ((m_c_htf1.TwoDown() || m_c_htf1.Three()) && m_c_htf1.IsRed() &&
        (m_c_htf2.TwoDown() || m_c_htf2.Three()) && m_c_htf2.IsRed() &&
        (m_c_htf3.TwoDown() || m_c_htf3.Three()) && m_c_htf3.IsRed())
    {

        if (m_c_cur_0.TwoDown() && m_c_cur_0.IsRed() &&
            m_c_cur_1.TwoUp() && m_c_cur_1.IsGreen())
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

    bool res = false;
    double price = m_symbol.Ask();
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
        if (m_trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lots, price, stopLoss, takeProfit, comment))
        {
            printf("Position by %s to be opened", Symbol());
        }
        else
        {
            printf("Error opening BUY position by %s : '%s'", Symbol(), m_trade.ResultComment());
            printf("Open parameters : price=%f,SL=%f", price, stopLoss);
        }
    }

    return (res);
}

//+------------------------------------------------------------------+
//| Sell                                                             |
//+------------------------------------------------------------------+
bool CTheStratExpert::SellMarket(double stopLoss, string comment)
{
    // Print("Sending sell order for ", Symbol());
    if(IsVolumeToLow() || !IsInTime())
      return (false);
      
      
    bool res = false;
    double price = m_symbol.Bid();
    double lots = TradeSizeOptimized(stopLoss - price);

    double takeProfit = FindTargetPrice(stopLoss);

    //--- check for free money
    if (m_account.FreeMarginCheck(_Symbol, ORDER_TYPE_SELL, lots, price) < 0.0)
    {
        printf("We have no money. Free Margin = %f", m_account.FreeMargin());
    }
    else
    {
        //--- open position
        if (m_trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lots, price, stopLoss, takeProfit, comment))
        {
            printf("Position by %s to be opened", Symbol());
        }
        else
        {
            printf("Error opening BUY position by %s : '%s'", Symbol(), m_trade.ResultComment());
            printf("Open parameters : price=%f,SL=%f", price, stopLoss);
        }
    }
    return (res);
}



//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double CTheStratExpert::TradeSizeOptimized(double stopLoss)
{

    // Print("Stop Loss in points : ", stopLoss);
    if (m_useFixLots)
        return (m_lots);

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
   
   if(m_useTargetTimeframe == false)
      return 0.0;
   
   
   double price = m_symbol.Ask();
   bool isLong = (price > stopLoss);
   int shift = 1;
   if(isLong)
   {
      double hight = 0.0;
      double minTarget = price + MathAbs(price - stopLoss);
      
      do
      {
         hight = iHigh(m_symbol.Name(), m_targetTimeframe, shift++);
         if(hight == 0.0)
           return 0.0;
            
      }
      while(hight <minTarget );
      
      return hight;
   }
   else
   {
      double low = 0.0;
      double minTarget = price - MathAbs(stopLoss - price);
      
      do
      {
         low = iLow(m_symbol.Name(), m_targetTimeframe, shift++);
         if(low == 0.0)
           return 0.0;
            
      }
      while(low > minTarget );
      
      return low;
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