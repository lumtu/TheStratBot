//+------------------------------------------------------------------+
//|                                               TheStratExpert.mqh |
//|                                          Copyright , Udo köller  |
//|                                              http://www.lumtu.de |
//+------------------------------------------------------------------+

enum CandleType {
    Unset,
    One,
    TwoUp,
    TwoDown,
    Three
};

class Candle 
{
private:
    ENUM_TIMEFRAMES m_period;
    int m_index;
    double m_open;
    double m_high;
    double m_low;
    double m_close;
    double m_popen;
    double m_phigh;
    double m_plow;
    double m_pclose;
      
public:
    Candle();
    Candle(ENUM_TIMEFRAMES period, int index);
    
    bool RefreshRates();

    double GetHigh();
    double GetLow();
    double IsGreen();
    double IsRed();
    CandleType GetType();

    bool TwoUp();
    bool TwoDown();
    bool Three();
    bool One();
    bool HigherHigh();
    bool HigherLow();
    bool LowerHigh();
    bool LowerLow();
    
    string ToString();
};



Candle::Candle() 
{

}

Candle::Candle(ENUM_TIMEFRAMES period, int index) 
{
   m_period = period;
   m_index  = index;
   RefreshRates();
}

bool Candle::RefreshRates()
{
    m_open   = iOpen (_Symbol, m_period, m_index);
    m_high   = iHigh (_Symbol, m_period, m_index);
    m_low    = iLow  (_Symbol, m_period, m_index);
    m_close  = iClose(_Symbol, m_period, m_index);

    m_popen  = iOpen (_Symbol, m_period, m_index+1);
    m_phigh  = iHigh (_Symbol, m_period, m_index+1);
    m_plow   = iLow  (_Symbol, m_period, m_index+1);
    m_pclose = iClose(_Symbol, m_period, m_index+1);
    
    return (true);
}

double Candle::GetHigh() 
{ return m_high; }

double Candle::GetLow() 
{ return m_low; }

double Candle::IsGreen() 
{ return m_close >= m_open; }

double Candle::IsRed() 
{ return m_close <= m_open; }

CandleType Candle::GetType()
{
    if(m_high < m_phigh && m_low > m_plow) return CandleType::One;
    if(m_high > m_phigh && m_low > m_plow) return CandleType::TwoUp;
    if(m_high < m_phigh && m_low < m_plow) return CandleType::TwoDown;
    if(m_high > m_phigh && m_low < m_plow) return CandleType::Three;
    return Unset;
}

bool Candle::TwoUp() 
{ return GetType() == CandleType::TwoUp; }

bool Candle::TwoDown() 
{ return GetType() == CandleType::TwoDown; }

bool Candle::Three() 
{ return GetType() == CandleType::Three; }

bool Candle::One() 
{ return GetType() == CandleType::One; }

bool Candle::HigherHigh() 
{ return m_high > m_phigh; }

bool Candle::HigherLow() 
{ return m_low > m_plow; }

bool Candle::LowerHigh() 
{ return m_high < m_phigh; }

bool Candle::LowerLow()
{ return m_low < m_plow; }
      
string Candle::ToString() 
{
    return StringFormat("%f|%f|%f|%f|%f|%f|%f|%f"
        , m_open 
        , m_popen 
        , m_high 
        , m_phigh 
        , m_low  
        , m_plow  
        , m_close  
        , m_pclose);
}
