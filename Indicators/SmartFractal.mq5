//+------------------------------------------------------------------+
//|                                                 SmartFractal.mq5 |
//|                                  Copyright 2022, Stupenkov Anton |
//|                                     https://github.com/stupenkov |
//+------------------------------------------------------------------+
#property copyright "Stupenkov Anton"
#property link      "https://github.com/stupenkov"
#property version   "1.00"

#include <PriceComparator.mqh>

#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6
#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW
#property indicator_type4   DRAW_ARROW
#property indicator_type5   DRAW_ARROW
#property indicator_type6   DRAW_ARROW
#property indicator_color1  Gray
#property indicator_color2  Gray
#property indicator_color3  clrAqua
#property indicator_color4  clrRed
#property indicator_color5  clrYellow
#property indicator_color6  clrViolet

#property indicator_label1  "Fractal Up"
#property indicator_label2  "Fractal Down"
#property indicator_label3  "Bos Up"
#property indicator_label4  "Bos Down"
#property indicator_label5  "Signal Buy"
#property indicator_label6  "Signal Sell"

//--- input parameters
input int BarCount = 5;

//--- indicator buffers
double ExtUpperBuffer[];
double ExtLowerBuffer[];
double BosUp[];
double BosDown[];
double SignalBuy[];
double SignalSell[];
//--- 10 pixels upper from high price
int ExtArrowShift = -10;
int SignalArrowShift = -5;

CPriceComparator *highComparator;
CPriceComparator *lowComparator;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    highComparator = new CPriceComparator;
    highComparator.ExcludeSamePrice(true);
    lowComparator = new CPriceComparator;
    lowComparator.ExcludeSamePrice(true);
//--- indicator buffers mapping
    SetIndexBuffer(0, ExtUpperBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, ExtLowerBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, BosUp, INDICATOR_DATA);
    SetIndexBuffer(3, BosDown, INDICATOR_DATA);
    SetIndexBuffer(4, SignalBuy, INDICATOR_DATA);
    SetIndexBuffer(5, SignalSell, INDICATOR_DATA);
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//--- sets first bar from what index will be drawn
    PlotIndexSetInteger(0, PLOT_ARROW, 217);
    PlotIndexSetInteger(1, PLOT_ARROW, 218);
    PlotIndexSetInteger(2, PLOT_ARROW, 158);
    PlotIndexSetInteger(3, PLOT_ARROW, 158);
    PlotIndexSetInteger(4, PLOT_ARROW, 117);
    PlotIndexSetInteger(5, PLOT_ARROW, 117);
//--- arrow shifts when drawing
    PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, ExtArrowShift);
    PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, -ExtArrowShift);
//--- sets drawing line empty value--
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
    PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
    PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
    PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, EMPTY_VALUE);
    PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, EMPTY_VALUE);
    PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, EMPTY_VALUE);

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                            |
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
    highComparator.Init(high);
    lowComparator.Init(low);

    if(!HasEnoughBars(rates_total))
        return(0);

    int start;

    if(prev_calculated < GetMinimumBars() + BarCount)
    {
        start = BarCount;
        ArrayInitialize(ExtUpperBuffer, EMPTY_VALUE);
        ArrayInitialize(ExtLowerBuffer, EMPTY_VALUE);
        ArrayInitialize(BosUp, EMPTY_VALUE);
        ArrayInitialize(BosDown, EMPTY_VALUE);
        ArrayInitialize(SignalBuy, EMPTY_VALUE);
        ArrayInitialize(SignalSell, EMPTY_VALUE);
    }
    else
    {
        start = rates_total - GetMinimumBars();
    }

    for(int i = start; i < rates_total && !IsStopped(); i++)
    {
        if(IsUpFractal(i, BarCount, high))
            ExtUpperBuffer[i] = high[i];
        else
            ExtUpperBuffer[i] = EMPTY_VALUE;

        if(IsDownFractal(i, BarCount, low))
            ExtLowerBuffer[i] = low[i];
        else
            ExtLowerBuffer[i] = EMPTY_VALUE;
    }

    ProcessUpBos(rates_total, close);
    ProcessDownBos(rates_total, close);

    return(rates_total);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessUpBos(int rates_total, const double &close[])
{
    int lastIndex = FindLastIndexWithValue(ExtUpperBuffer, rates_total);

    int foundResult = FindBrakeOfUpStructure(lastIndex, rates_total, close);
    if(foundResult > -1)
    {
        lastIndex = -1;
        SignalBuy[foundResult] = close[foundResult];
    }

    if(lastIndex > -1)
    {
        ArrayFill(BosUp, lastIndex, rates_total - lastIndex, ExtUpperBuffer[lastIndex]);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessDownBos(int rates_total, const double &close[])
{
    int lastIndex = FindLastIndexWithValue(ExtLowerBuffer, rates_total);

    int foundResult = FindBrakeOfDownStructure(lastIndex, rates_total, close);
    if(foundResult > -1)
    {
        lastIndex = -1;
        SignalSell[foundResult] = close[foundResult];
    }

    if(lastIndex > -1)
    {
        ArrayFill(BosDown, lastIndex, rates_total - lastIndex, ExtLowerBuffer[lastIndex]);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int FindBrakeOfUpStructure(int fractalIndex, int rates_total, const double &close[])
{
    if(fractalIndex < 0)
        return (-1);

    for(int i = fractalIndex; i < rates_total - 1; i++)
    {
        if(close[i] > ExtUpperBuffer[fractalIndex])
            return (i);
    }

    return (-1);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int FindBrakeOfDownStructure(int fractalIndex, int rates_total, const double &close[])
{
    if(fractalIndex < 0)
        return (-1);

    for(int i = fractalIndex; i < rates_total - 1; i++)
    {
        if(close[i] < ExtLowerBuffer[fractalIndex])
            return (i);
    }

    return (-1);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int FindLastIndexWithValue(double &buffer[], int rates_total)
{
    for(int i = rates_total - 2; i > 0; i--)
    {
        if(buffer[i] != EMPTY_VALUE)
            return i;
    }

    return (-1);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HasEnoughBars(int ratesTotal)
{
    return (ratesTotal > GetMinimumBars());
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetMinimumBars()
{
    return (BarCount * 2 + 1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsUpFractal(int barIndex, int countBar, const double &high[])
{
    if(!highComparator.IsPriceHigherThanRight(barIndex, countBar))
    {
        return (false);
    }

    if(highComparator.IsPriceHigherThanLeft(barIndex, countBar))
    {
        return (true);
    }

    return (false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsDownFractal(int barIndex, int countBar, const double &high[])
{
    if(!lowComparator.IsPriceLowerThanRight(barIndex, countBar))
    {
        return (false);
    }

    if(lowComparator.IsPriceLowerThanLeft(barIndex, countBar))
    {
        return (true);
    }

    return (false);
}
//+------------------------------------------------------------------+
