//+------------------------------------------------------------------+
//|                                              PriceComparator.mqh |
//|                                  Copyright 2022, Stupenkov Anton |
//|                                     https://github.com/stupenkov |
//+------------------------------------------------------------------+
#property copyright "Stupenkov Anton"
#property link      "https://github.com/stupenkov"
#property version   "1.00"

enum ENUM_COMPARE_PRICE_CONDITION
{
    COMPARE_PRICE_CONDITION_HIGHER = 0,
    COMPARE_PRICE_CONDITION_LOWER = 1
};
enum ENUM_BAR_HORIOZONTAL_DIRECTION
{
    BAR_HORIOZONTAL_DIRECTION_LEFT = -1,
    BAR_HORIOZONTAL_DIRECTION_RIGHT = 1
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPriceComparator
{
private:
    double           m_price[];
    int              m_priceSize;
    bool             m_isExcluldeSamePrice;
    bool             ComparePrice(ENUM_COMPARE_PRICE_CONDITION condition,
                                  ENUM_BAR_HORIOZONTAL_DIRECTION direction,
                                  int barIndex,
                                  int countBar);
public:
                     CPriceComparator();
                    ~CPriceComparator();

    void             Init(const double & price[]);
    void             ExcludeSamePrice(bool value);
    bool             IsPriceHigherThanRight(int barIndex, int countBar);
    bool             IsPriceHigherThanLeft(int barIndex, int countBar);
    bool             IsPriceLowerThanRight(int barIndex, int countBar);
    bool             IsPriceLowerThanLeft(int barIndex, int countBa);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPriceComparator::CPriceComparator(void):
    m_priceSize(0),
    m_isExcluldeSamePrice(false)
{
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPriceComparator::~CPriceComparator()
{
}
//+------------------------------------------------------------------+
void CPriceComparator::Init(const double &price[])
{
    m_priceSize = ArraySize(price);
    ArrayResize(m_price, m_priceSize);
    ArrayCopy(m_price, price);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CPriceComparator::ExcludeSamePrice(bool value)
{
    m_isExcluldeSamePrice = value;
}
//+------------------------------------------------------------------+
bool CPriceComparator::ComparePrice(
    ENUM_COMPARE_PRICE_CONDITION condition,
    ENUM_BAR_HORIOZONTAL_DIRECTION direction,
    int barIndex,
    int countBar)
{
    int counter = 0;
    int skip = 0;
    while(counter < countBar)
    {
        int compareBarIndex = barIndex + ((counter + 1 + skip) * direction);

        if(compareBarIndex < 0 || compareBarIndex > m_priceSize - 1)
            return (false);

        double diff = m_price[barIndex] - m_price[compareBarIndex];
        if(diff == 0 && m_isExcluldeSamePrice && direction == BAR_HORIOZONTAL_DIRECTION_LEFT)
        {
            skip++;
            continue;
        }

        if((condition == COMPARE_PRICE_CONDITION_LOWER && diff >= 0)
                || (condition == COMPARE_PRICE_CONDITION_HIGHER && diff <= 0))
        {
            return (false);
        }

        counter++;
    }

    return (true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPriceComparator::IsPriceHigherThanRight(int barIndex, int countBar)
{
    return (ComparePrice(COMPARE_PRICE_CONDITION_HIGHER, BAR_HORIOZONTAL_DIRECTION_RIGHT, barIndex, countBar));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPriceComparator::IsPriceHigherThanLeft(int barIndex, int countBar)
{
    return (ComparePrice(COMPARE_PRICE_CONDITION_HIGHER, BAR_HORIOZONTAL_DIRECTION_LEFT, barIndex, countBar));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPriceComparator::IsPriceLowerThanRight(int barIndex, int countBar)
{
    return (ComparePrice(COMPARE_PRICE_CONDITION_LOWER, BAR_HORIOZONTAL_DIRECTION_RIGHT, barIndex, countBar));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPriceComparator::IsPriceLowerThanLeft(int barIndex, int countBar)
{
    return (ComparePrice(COMPARE_PRICE_CONDITION_LOWER, BAR_HORIOZONTAL_DIRECTION_LEFT, barIndex, countBar));
}
//+------------------------------------------------------------------+
