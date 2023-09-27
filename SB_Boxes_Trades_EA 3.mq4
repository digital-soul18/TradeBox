//+------------------------------------------------------------------+
//|                                           SB_Boxes_Trades_EA.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+



/*

Instructions and notes -
- When you set this up for the first time on a single currency across multiple time frames then you need to ensure that each chart has its own Magic number.
You meed to manutally insert the magic number which is unique to that chart. Otherwise the EA's will clash with each other. One will delete the other's trades.
- Remember to draw out a red box and then change the description. The description is the number of lots you wish to trade.
- If you wish to trade 1 lot then edit the description and put in '1'. Alternatively if you wish to trade 1% then type '1%' of trade.
- When a trade closes the entry box will remain there to show you which trades it has taken so you can learn from your mistakes.

Updates required in order of priority -

DONE - Once a second trade has gone to TP, the first one needs to move to break even. Right now its not.
 - Make the trade have its own SL lines rather then disable the box.
 - If the trade disables second trade code the logic so that it puts the SL to BE halfway point.
 - Once trade is entered then need to take screenshot of the trade.
 - Consider using a pennant/flag indicator on HTF to find squeezes.
 - Should we allow the second trade stop loss to be adjustable for percentage of first trade's entry and stop loss (lines 802) ie. I want to enter my second trade stop loss as 50% between the first trades trade entry and stop loss.
 - Upon confluence between the three levels - supply on all three timeframes then a judgement system must be in place
 - Judgement system has the last call to make on if to allow this trade to continue.
 - If price is approaching the 'buffer zone' of the pending order then we must check the next high TF level and see how far away that is (use the supcount)
 - For example, if it is still 2:1 risk to reward ratio then its worth retaining the order
 - If not, we need to delete the order. Otherwise retain the order.
 - Retained order must readjust the TP price to closest SD level.
DONE - Must improve the look of the levels - 1H levels to be long dashes with no fill
DONE - The text of 'H1' should show further away
CANCELLED - Need historical view of levels in indicator
DONE - Multi time frame SD levels - 1H,15M,1M
DONE - Add in 1M SD levels


Defect Log -
- When a second order is entered there are like three or four changes to the TP/SL which is weird.
- Remove all the implicit conversion from number to string and possible loss of data due to type conversion.
- If you open more then one chart with this EA on it then it will remove your trade. Need to figure out how to prevent this from happening.
  Need to setup a checker for all other EA's and their magic number. If another Magic number exsits that is the same then notice needs to be given.
- If you put a box in then inert the lots into the box THEN change the height of the box the yellow TP does not follow.


//Next feature -
//Click to view chart position -
//Use the "ObjectFind()" to get a specified named object and then use "ObjectGetTimeByValue()" to get its date/time.
//Get the Charts Symbol and Period with the functions "ChartSymbol()" and "ChartPeriod()".
//With the date and time (from step 1), find the bar shift with the "iBarShift()" function for the specified symbol and period obtained in the step 2.
//Disable the auto scrolling of the chart with the "ChartSetInteger()" function and the CHART_AUTOSCROLL property with a value of "0" equivalent to "false".
//Obtain the chart's current bar positioning, using the "ChartGetInteger()" function and the properties CHART_FIRST_VISIBLE_BAR and CHART_VISIBLE_BARS.
//Calculate the required bar positioning offset and then use the function "ChartNavigate()" to position the chart according to your requirements.

//Test date - 15/09/2019 EURUSD


*/


#include <stdlib.mqh>
//#include <debug_inc.mqh>


#property copyright "Copyright 2016"
#property link      ""
#property version   "1.00"
#property strict
#include <WinUser32.mqh>
#include <stderror.mqh>
#include <stdlib.mqh>
#include <stdlib.mqh>

extern bool    allowed_2nd_trade=true;
extern color   activate_colour=clrRed;
extern int     magic_number=929161;
extern int     slippage = 5;   //Allowed slippage of open/close order
extern int     bar1size = 5;   // local variable required to avoid a flat market
//extern int     minZoneThickness = 10; // local variable required to avoid a flat market
extern color   virginSupplyLevelColour                        = C'67,78,92';
extern color   firstPenetrationSupplyLevelColour              = clrPink;
extern color   secondPenetrationSupplyLevelColour             = clrPink;
extern color   thirdPenetrationSupplyLevelColour              = clrPink;
extern color   whoredOutSupplyLevelColour                     = C'142,37,52';
extern color   virginDemandLevelColour                        = clrGreen;
extern color   firstPenetrationDemandLevelColour              = clrAqua;
extern color   secondPenetrationDemandLevelColour             = clrAqua;
extern color   thirdPenetrationDemandLevelColour              = clrAqua;
extern color   whoredOutDemandLevelColour                     = C'142,37,52';
extern int     firstPenetrationsMaxCandles=5;        //The number of candles that penetrate a level before the level's 'freshness'.
extern int     secondPenetrationsMaxCandles             = 10;        //The number of candles that penetrate a level before the level's 'freshness'.
extern int     thirdPenetrationsMaxCandles              = 10;        //The number of candles that penetrate a level before the level's 'freshness'.
extern int     whoredOutMaxCandles                      = 10;        //The number of candles that penetrate a level before the level's 'freshness'.
extern int     maxPenetrationToExpireLevel              = 3;         //The max number of full candle penetrations before level is expired.

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double take_profit=0;                     //Fixed takeprofit in pips (0=no takeprofit)
double stop_loss=0;                       //Fixed stoploss in pips (0=no stoploss)

int timeframe=0;
int number_retry_open_trade=10;

double     myPoint,mySpread,myStopLevel,myTickValue,myTickSize,myLotValue;
double       myDigits;
datetime   TradeBarTime,refreshcharttime;
bool       enable_ea;
double     my_lots;
int        digit_lot;

//Variables for candleIdentifier
double _bar1size;                // local variable required to avoid a flat market
datetime timeBUOVB_BEOVB=NULL;   // time of a bar when pattern orders were opened, to avoid re-opening
string CandleFinder,arrayOut[17];
int SupplyLevelCounter,DemandLevelCounter,ZZLevelCounter;

int signal;
int signalclose;
int myBars;
double last_history_check;
string TradeCode="SB00";

//Variables to define screenshot width and height
#define Screenshot_Width 1024
#define Screenshot_Height 768

int err;
string strsuffix;
double ratio=1000000,CurrentSupDem,H1SupDem,M15SupDem,H4SupDem;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   SetPoint();
   if(Digits==3 || Digits==5)
      slippage*=10;
   if(MarketInfo(Symbol(),MODE_LOTSTEP)>=0.01)
      digit_lot=2;
   if(MarketInfo(Symbol(),MODE_LOTSTEP)>=0.1)
      digit_lot=1;
   if(MarketInfo(Symbol(),MODE_LOTSTEP)>=1)
      digit_lot=0;
   TradeBarTime=Time[0];
   SupplyLevelCounter = 1;
   DemandLevelCounter = 1;
   strsuffix="_"+Symbol()+IntegerToString(Period())+"_"+TradeCode+"_"+IntegerToString(magic_number);
//---
//--- enable object create events
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_CREATE,true);
//--- enable object delete events
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_DELETE,true);
//--- Remove grid
   ChartSetInteger(ChartID(),CHART_SHOW_GRID,0,false);
//--Chart should be candlesticks
   ChartSetInteger(ChartID(),CHART_MODE,0,CHART_CANDLES);
//--Chart to set shift
   ChartSetInteger(ChartID(),CHART_SHIFT,0,true);
//--Chart scale
   ChartSetInteger(ChartID(),CHART_SCALE,0,2);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double setTP(double open, double tp_pips) { if(tp_pips==0) return(0); else return(NormalizeDouble(open+(tp_pips*myPoint),Digits)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double setSL(double open, double sl_pips) { if(sl_pips==0) return(0); else return(NormalizeDouble(open-(sl_pips*myPoint),Digits)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isAlreadyEnter(string strcomment)
  {
   int i;
   for(i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number)
           {
            if(StringFind(OrderComment(),strcomment)!=-1)
               return(true);
           }
        }
     }
   for(i=OrdersHistoryTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==True)
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number)
           {
            if(StringFind(OrderComment(),strcomment)!=-1)
               return(true);
           }
        }
     }

   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBoxes()
  {
   int i;
   int x;
   int status;
   for(i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number && OrderType()>1)
           {
            string str1=StringSubstr(OrderComment(),0,StringFind(OrderComment(),"_"+TradeCode));
            string str2=StringSubstr(str1,StringFind(str1,"_")+1);
            if((ObjectFind(str2)==-1) || ObjectFind(str2)!=-1)
              {
               color objcolor = ObjectGet(str2,OBJPROP_COLOR);
               if(objcolor!=activate_colour && objcolor!=clrGreenYellow)
                 {
                  status=0;
                  for(x = 5; x!= 0; x--)
                    {
                     while(IsTradeContextBusy() || !IsTradeAllowed())
                        Sleep(5000);
                     status=OrderDelete(OrderTicket());
                     if(status==1)
                       {
                        break;
                       }
                    }
                  ObjectDelete("vvOP2_"+IntegerToString(OrderTicket()));
                  ObjectDelete("vOP2_"+IntegerToString(OrderTicket()));
                  ObjectDelete("vTP1_"+IntegerToString(OrderTicket()));
                  ObjectDelete("vTP2_"+IntegerToString(OrderTicket()));
                  ObjectDelete("vSL2_"+IntegerToString(OrderTicket()));
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FindClosedTrades()
  {
   int i;
   for(i=OrdersHistoryTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==True)
        {
         int orderticket=OrderTicket();
         int ordertype=OrderType();
         string ordersymbol=OrderSymbol();
         int ordermagic=OrderMagicNumber();
         string ordercomment=OrderComment();
         double orderlots=OrderLots();
         if(ordersymbol==Symbol() && ordermagic==magic_number && ordertype<=1)
           {
            int ind=StringFind(ordercomment,"_"+TradeCode);
            string str1=StringSubstr(ordercomment,0,ind);
            string str2=StringSubstr(str1,StringFind(str1,"_")+1);
            ObjectSet(str2,OBJPROP_COLOR,clrBlue);
            ObjectSet("vTP1_"+IntegerToString(orderticket),OBJPROP_WIDTH,1);
            ObjectSet("vTP1_"+IntegerToString(orderticket),OBJPROP_STYLE,STYLE_DASH);
            if(allowed_2nd_trade)
              {
               DeletePending2(str2);
              }
            ObjectDelete("vvOP2_"+IntegerToString(orderticket));
            ObjectDelete("vOP2_"+IntegerToString(orderticket));
            ObjectDelete("vTP2_"+IntegerToString(orderticket));
            ObjectDelete("vSL2_"+IntegerToString(orderticket));
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteTradeAfterBox()
  {
   int i;
   int x;
   int status;
   for(i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number && OrderType()>1)
           {
            string str1=StringSubstr(OrderComment(),0,StringFind(OrderComment(),"_"+TradeCode));
            string str2=StringSubstr(str1,StringFind(str1,"_")+1);
            datetime time1=StrToInteger(DoubleToString(GetRectTime(str2,OBJPROP_TIME1)));
            datetime time2=StrToInteger(DoubleToString(GetRectTime(str2,OBJPROP_TIME2)));
            datetime timex=MathMax(time1,time2);

            if(TimeCurrent()>=timex+(Period()*60))
              {
               status=0;
               for(x = 5; x!= 0; x--)
                 {
                  while(IsTradeContextBusy() || !IsTradeAllowed())
                     Sleep(5000);
                  status=OrderDelete(OrderTicket());
                  if(status==1)
                    {
                     break;
                    }
                 }
               ObjectDelete("vvOP2_"+IntegerToString(OrderTicket()));
               ObjectDelete("vOP2_"+IntegerToString(OrderTicket()));
               ObjectDelete("vTP1_"+IntegerToString(OrderTicket()));
               ObjectDelete("vTP2_"+IntegerToString(OrderTicket()));
               ObjectDelete("vSL2_"+IntegerToString(OrderTicket()));
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TPLinesMoved()
  {
   int i;
   for(i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number)
           {

            double tpprice=NormalizeDouble(ObjectGet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1),Digits);
            if(tpprice!=OrderTakeProfit() && StringFind(OrderComment(),"T01_")!=-1)
              {
               //logb("----tplinesmoved1");
               ModifyProfitTarget(OrderTicket(),tpprice,OrderStopLoss());
              }
            double tpprice2=NormalizeDouble(ObjectGet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1),Digits);
            if(tpprice2!=OrderTakeProfit() && StringFind(OrderComment(),"T02_")!=-1)
              {
               //logb("----tplinesmoved1");
               ModifyProfitTarget(OrderTicket(),tpprice2,OrderStopLoss());
              }

            double slprice2=NormalizeDouble(ObjectGet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1),Digits);
            if(slprice2!=OrderStopLoss() && StringFind(OrderComment(),"T02_")!=-1)
              {
               //logb("----tplinesmoved3");
               ModifyProfitTarget(OrderTicket(),OrderTakeProfit(),slprice2);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BoxMoved()
  {
   int i;
   for(i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number)
           {
            string str1=StringSubstr(OrderComment(),0,StringFind(OrderComment(),"_"+TradeCode));
            string str2=StringSubstr(str1,StringFind(str1,"_")+1);
            double price1=NormalizeDouble(GetRectPrice(str2,OBJPROP_PRICE1),Digits);
            double price2=NormalizeDouble(GetRectPrice(str2,OBJPROP_PRICE2),Digits);
            double upperline=MathMax(price1,price2);
            double lowerline=MathMin(price1,price2);
            datetime time1=StrToInteger(DoubleToString(GetRectTime(str2,OBJPROP_TIME1)));
            datetime time2=StrToInteger(DoubleToString(GetRectTime(str2,OBJPROP_TIME2)));
            color boxColor=ObjectGet(str2,OBJPROP_COLOR);
            int ret=0;

            if(StringFind(OrderComment(),"T01_")!=-1 && boxColor==activate_colour)
              {
               if(OrderType()==OP_BUYLIMIT && Bid>upperline)
                 {
                  if(OrderOpenPrice()!=upperline || OrderStopLoss()!=lowerline)
                    {
                     ret=OrderModify(OrderTicket(),NormalizeDouble(upperline,Digits),NormalizeDouble(lowerline,Digits),OrderTakeProfit(),OrderExpiration());
                     if(ret>0)
                       {
                        ObjectSet("vOP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,upperline+upperline-lowerline);
                        ObjectSet("vOP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,upperline+upperline-lowerline);
                        ObjectSet("vOP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vOP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                        ObjectSet("vvOP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,upperline+upperline-lowerline);
                        ObjectSet("vvOP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,upperline+upperline-lowerline);
                        ObjectSet("vvOP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vvOP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,upperline-0.5*(upperline-lowerline));
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,upperline-0.5*(upperline-lowerline));
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,upperline+upperline-lowerline+upperline-lowerline);
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,upperline+upperline-lowerline+upperline-lowerline);
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                        TextMove(0,"InfoBox_"+str2,MathMin(time1,time2),lowerline);
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                       }
                    }
                 }
               else
                  if(OrderType()==OP_SELLLIMIT && Bid<lowerline)
                    {
                     if(OrderOpenPrice()!=lowerline || OrderStopLoss()!=upperline)
                       {
                        ret=OrderModify(OrderTicket(),NormalizeDouble(lowerline,Digits),NormalizeDouble(upperline,Digits),OrderTakeProfit(),OrderExpiration());
                        if(ret>0)
                          {
                           ObjectSet("vOP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,lowerline-(upperline-lowerline));
                           ObjectSet("vOP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,lowerline-(upperline-lowerline));
                           ObjectSet("vOP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                           ObjectSet("vOP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                           ObjectSet("vvOP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,lowerline-(upperline-lowerline));
                           ObjectSet("vvOP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,lowerline-(upperline-lowerline));
                           ObjectSet("vvOP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                           ObjectSet("vvOP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                           ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,lowerline-0.5*(lowerline-upperline));
                           ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,lowerline-0.5*(lowerline-upperline));
                           ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                           ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                           ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,lowerline-(upperline-lowerline)-(upperline-lowerline));
                           ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,lowerline-(upperline-lowerline)-(upperline-lowerline));
                           ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                           ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                           TextMove(0,"InfoBox_"+str2,MathMin(time1,time2),upperline);
                           ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                           ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                          }
                       }
                    }
              }


            //Ok so even though this function is meant to be for Box moved here is the Stop loss to break even code for the second trade
            if(allowed_2nd_trade)
              {

               //Initiate variables as required for second trade.
               int    Orderticket = OrderTicket();
               string Ordercomment = OrderComment();
               double Ordertakeprofit = OrderTakeProfit();
               double Orderclose = OrderClosePrice();
               double Orderopenprice = OrderOpenPrice();
               double Orderstoploss = OrderStopLoss();

               //See if this is order is a second trade
               if(StringFind(Ordercomment,"T02_") != -1)
                 {

                  //Find the Order ID of the original order based off the name of the rectangle
                  int FirstTradeID = OrderFind("T01_"+str2);

                  //Find the first order's TP and SL
                  if(OrderSelect(FirstTradeID, SELECT_BY_TICKET)==true)
                    {
                     double FirstTradeTP = OrderTakeProfit();
                     double FirstSL =  OrderStopLoss();
                     double FirstOpenPrice = OrderOpenPrice();

                     //---------------- BUY ----------------------------------
                     if(OrderType()==0 && Bid>=Orderopenprice)
                       {
                        //Calculate the BE point of the second trade by it being halfway from the TP to the Entry
                        double SecondTradeBreakevenPrice = NormalizeDouble(ObjectGet("vOP2_"+IntegerToString(Orderticket),OBJPROP_PRICE1),Digits);

                        if(FirstSL != FirstOpenPrice)
                          {
                           //Change the color of the Rectangle so that it disables it from auto updating price back to price within the rectangle and allows to override.
                           ObjectSet(str2,OBJPROP_COLOR,clrGreenYellow);

                           //Modify the order to move the Stop loss to break even point but keep take profit as is.
                           //logb("---BUY first trade now moved SL to BE");
                           ModifyProfitTarget(FirstTradeID,NULL,price1);

                          }

                        /*
                        logb("Reached. Ordercomment ", OrderComment()) ;// demo showing how to add paramters
                        logb("   Ordercom var: ",Ordercomment);
                        logb("   SecondTradeBreakevenPrice:", SecondTradeBreakevenPrice);
                        //logb("   OrderTakeProfit():",OrderTakeProfit());
                        logb("   OrderTakeProfit var:", Ordertakeprofit);
                        //logb("   OrderOpenPrice():", OrderOpenPrice());
                        logb("   Orderopenprice:", Orderopenprice);
                        logb("   FirstSL:", FirstSL);
                        logb("   FirstOpenPrice:", FirstOpenPrice);
                        */

                        //Alert("Second OrderComment: "+OrderComment()+" "+StringFind(OrderComment(),"T02_")+" Trade:"+OrderTicket()+" OrderTakeProfit"+OrderTakeProfit()+" OrderOpen: "+OrderOpenPrice()+" Price1:"+price1+" SecondTradeBreak:"+SecondTradeBreakevenPrice);

                        double slprice2=NormalizeDouble(ObjectGet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE1),Digits);

                        //Change the second trade SL to the top of the rectangle
                        if(Bid>=SecondTradeBreakevenPrice && slprice2 != price1)
                          {
                           //logb("---- BUY second trade now moved SL to BE");

                           //Move the SL line so the TPLinesMoved() doesn't override this
                           ObjectSet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE1,price1);
                           ObjectSet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE2,price1);

                           if(slprice2 != Orderstoploss)
                             {
                              //logb("---- BUY second trade SL changed");
                              ModifyProfitTarget(Orderticket,NULL,price1);
                             }
                          }
                       }

                     //----------------- SELL ------------------------------
                     if(OrderType()==1 && Ask<=Orderopenprice)
                       {
                        //Calculate the BE point of the second trade by it being halfway from the TP to the Entry
                        double SecondTradeBreakevenPrice = NormalizeDouble(ObjectGet("vOP2_"+IntegerToString(Orderticket),OBJPROP_PRICE1),Digits);

                        if(FirstSL != FirstOpenPrice)
                          {
                           //Change the color of the Rectangle so that it disables it from auto updating price back to price within the rectangle and allows to override.
                           ObjectSet(str2,OBJPROP_COLOR,clrGreenYellow);

                           //Modify the order to move the Stop loss to break even point but keep take profit as is.
                           //logb("---SELL first trade now moved SL to BE");
                           ModifyProfitTarget(FirstTradeID,NULL,price1); //This might have a bug in it. Need to look at original order first

                          }


                        //Alert("Second OrderComment: "+OrderComment()+" "+StringFind(OrderComment(),"T02_")+" Trade:"+OrderTicket()+" OrderTakeProfit"+OrderTakeProfit()+" OrderOpen: "+OrderOpenPrice()+" Price1:"+price1+" SecondTradeBreak:"+SecondTradeBreakevenPrice);

                        double slprice2=NormalizeDouble(ObjectGet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE1),Digits);

                        //Change the second trade SL to the top of the rectangle
                        if(Ask<=SecondTradeBreakevenPrice && slprice2 != price1)
                          {
                           //logb("---- SELL second trade now moved SL to BE");

                           //Move the SL line so the TPLinesMoved() doesn't override this
                           ObjectSet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE1,price1);
                           ObjectSet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE2,price1);

                           if(slprice2 != Orderstoploss)
                             {
                              //logb("---- SELL 2nd trade SL changed");
                              ModifyProfitTarget(Orderticket,NULL,price1);
                             }
                          }

                       }
                    }

                  else
                     Print("OrderSelect returned the error of ",GetLastError());
                 }
              }
            else      //if second trade not allowed
              {



              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetPending2()
  {
   if(allowed_2nd_trade)
     {
      int i;
      for(i=OrdersTotal()-1; i>=0; i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
           {
            int orderticket=OrderTicket();
            int ordertype=OrderType();
            string ordersymbol=OrderSymbol();
            int ordermagic=OrderMagicNumber();
            string ordercomment=OrderComment();
            double orderlots=OrderLots();
            int cmd=-1;

            //Read prices off the indicators on the chart
            double price=ObjectGet("vvOP2_"+IntegerToString(orderticket),OBJPROP_PRICE1);
            double sl=ObjectGet("vSL2_"+IntegerToString(orderticket),OBJPROP_PRICE1);
            double tp=ObjectGet("vTP2_"+IntegerToString(orderticket),OBJPROP_PRICE1);
            if(ordersymbol==Symbol() && ordermagic==magic_number && ordertype<=1 && StringFind(ordercomment,"T01_")!=-1)
              {
               if(ObjectFind("vvOP2_"+IntegerToString(orderticket))!=-1)
                 {
                  if(ordertype==OP_BUY)
                     cmd=OP_BUYSTOP;
                  else
                     if(ordertype==OP_SELL)
                        cmd=OP_SELLSTOP;
                  string strname;
                  string str1=StringSubstr(ordercomment,0,StringFind(ordercomment,"_"+TradeCode));
                  string str2=StringSubstr(str1,StringFind(str1,"_")+1);
                  strname=str2;
                  datetime time1=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME1)));
                  datetime time2=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME2)));
                  datetime frontline=MathMax(time1,time2);
                  datetime backline=MathMin(time1,time2);
                  int openticket=Open_Trade(Symbol(),cmd,price,orderlots,sl,tp,"T02_"+strname+"_"+TradeCode);
                  //what is this below?
                  if(openticket>0)
                    {
                     ObjectDelete("vvOP2_"+IntegerToString(orderticket));
                     ObjectDelete("vOP2_"+IntegerToString(orderticket));
                     //ObjectDelete("vTP1_"+IntegerToString(orderticket));
                     ObjectDelete("vTP2_"+IntegerToString(orderticket));
                     ObjectDelete("vSL2_"+IntegerToString(orderticket));
                     DrawTL("vOP2_"+IntegerToString(openticket),price,backline,price,frontline,clrGreen,STYLE_SOLID,1);
                     DrawTL("vSL2_"+IntegerToString(openticket),sl,backline,sl,frontline,clrGray,STYLE_SOLID,1);
                     DrawTL("vTP2_"+IntegerToString(openticket),tp,backline,tp,frontline,clrYellow,STYLE_SOLID,2);

                    }

                 }

               //As the price goes down and triggers the first trade then the second trade must initiate inbetween the TP and Entry. Once the Price goes above the entry of the second trade then the
               //first trade must move SL to Entry.

               //In order to do this I need to create a new line for SL once trade has been entered so that the doesn't shrink or is over-ridden OR once the trade is entered then the box will not change the values.

               //If order a buy or sell then once price goes above or below it then move initial order's stop loss to breakeven.
               /*
               string CurrentComment = OrderComment();
               string result[];
               int k=StringSplit(CurrentComment,StringGetCharacter("_",0),result);

               //Get the price of the original box.
               double BEPrice=NormalizeDouble(ObjectGet(result[1],OBJPROP_PRICE1),Digits);
               Alert("Note+ -Price:"+price+" Ticket:"+OrderTicket()+" comment:"+OrderComment()+" result:"+result[1]+" BEPrice:"+BEPrice);


               if(ordertype==OP_BUYSTOP && Bid>price && OrderStopLoss()<=OrderOpenPrice())
                 {
                    //Strip the name of the order to find the original name of the rectangle which owns the order

                     //Move price to breakeven
                     //ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,BEPrice);
                     //ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,BEPrice);
                     Alert("Buy Reached - "+OrderOpenPrice()+" Price:"+price+" Ticket:"+OrderTicket()+" comment:"+OrderComment()+" BEprice:"+BEPrice);
                 }

               if(ordertype==OP_SELLSTOP && Ask>price && OrderStopLoss()>=OrderOpenPrice())
                 {
                   //Move price to breakeven

                   Alert("Sell Reached - "+OrderOpenPrice());
                 }
               */
              }
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrderFind(string OrderCommentry)
  {
   int i;
   int orderID;
   for(i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number)
           {
            if(OrderType()<=1 && StringFind(OrderComment(),OrderCommentry)!=-1)
              {
               orderID = OrderTicket();

              }
           }
        }
     }
   if(orderID!=NULL)
     {
      return(orderID);
     }
   else
     {
      return(NULL);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeletePending2(string strcomment)
  {
   int i;
   int x;
   int status;
   for(i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number && OrderType()>1)
           {
            if(StringFind(OrderComment(),"T02_"+strcomment)!=-1)
              {
               for(x=5; x!=0; x--)
                 {
                  while(IsTradeContextBusy() || !IsTradeAllowed())
                     Sleep(5000);
                  status=OrderDelete(OrderTicket());
                  if(status==1)
                    {
                     ObjectDelete("vOP2_"+IntegerToString(OrderTicket()));
                     ObjectDelete("vSL2_"+IntegerToString(OrderTicket()));
                     ObjectDelete("vTP1_"+IntegerToString(OrderTicket()));
                     ObjectDelete("vTP2_"+IntegerToString(OrderTicket()));
                     ObjectDelete("vvOP2_"+IntegerToString(OrderTicket()));
                     ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_WIDTH,1);
                     ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_STYLE,STYLE_DASH);
                     break;
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CandleIdentifier(string SymbolCheck,
                        int PeriodCheck,
                        int FirstCandlePosition,
                        int SecondCandlePosition,
                        int ThirdCandlePosition,
                        color LevelColour, //This is now redundtant since its coloured using the global external settings. Should delete this.
                        const ENUM_LINE_STYLE LineStyle,
                        color HighTFLevelColour,//If this is a High TF then add a background of the following.
                        string &outArray[17])
  {
   string result=NULL;

//--- define prices of necessary bars
   double open_1        = NormalizeDouble(iOpen(SymbolCheck, PeriodCheck, FirstCandlePosition), Digits);
   double open_2        = NormalizeDouble(iOpen(SymbolCheck, PeriodCheck, SecondCandlePosition), Digits);
   double open_3        = NormalizeDouble(iOpen(SymbolCheck, PeriodCheck, ThirdCandlePosition), Digits);
   double close_1       = NormalizeDouble(iClose(SymbolCheck, PeriodCheck, FirstCandlePosition), Digits);
   double close_2       = NormalizeDouble(iClose(SymbolCheck, PeriodCheck, SecondCandlePosition), Digits);
   double close_3       = NormalizeDouble(iClose(SymbolCheck, PeriodCheck, ThirdCandlePosition), Digits);
   double low_1         = NormalizeDouble(iLow(SymbolCheck, PeriodCheck, FirstCandlePosition), Digits);
   double low_2         = NormalizeDouble(iLow(SymbolCheck, PeriodCheck, SecondCandlePosition), Digits);
   double low_3         = NormalizeDouble(iLow(SymbolCheck, PeriodCheck, ThirdCandlePosition), Digits);
   double high_1        = NormalizeDouble(iHigh(SymbolCheck, PeriodCheck, FirstCandlePosition), Digits);
   double high_2        = NormalizeDouble(iHigh(SymbolCheck, PeriodCheck, SecondCandlePosition), Digits);
   double high_3        = NormalizeDouble(iHigh(SymbolCheck, PeriodCheck, ThirdCandlePosition), Digits);
   datetime time_1      = iTime(SymbolCheck, PeriodCheck, FirstCandlePosition);
   datetime time_2      = iTime(SymbolCheck, PeriodCheck, SecondCandlePosition);

   double _point=MarketInfo(SymbolCheck,MODE_POINT);
   _bar1size=NormalizeDouble(((high_1-low_1)/_point),0);
//double _minZoneThickness = NormalizeDouble((MathMax(open_2,close_2)-low_2)/_point,0);
   double pip_buffer=7*_point;
   double bar_midpoint=MathAbs(open_1-close_1)/2+MathMin(open_1,close_1);

   bool SetAsBack; // used to make backgrounds hollow for High TF levels
   if(HighTFLevelColour!=NULL)
      SetAsBack=false;
   else
      SetAsBack=true; //if HighTF color set then make it hollow.

//--- Finding bullish Engulfing
   if(
      MathAbs(close_1-open_1)/2>MathAbs(open_2-close_2) && //Ensure that the body size of bar 2 is half the body size of bar 1
      high_1>high_2 && //Ensure the height of bar 2 isn't greater then bar 1.
      close_1>open_1 && //Ensure bull candle and prevent bearish candles.
      open_1 - pip_buffer< close_2 && //Ensure the bottom body of bar 2 is approximately around the bottom body of bar 1. Added a buffer to for small variences.
      low_1 - 2*pip_buffer < low_2 && //Ensure the wick of bar 2 is approximately close to wick of bar 2 with a built in buffer.
      MathAbs(1.5*(open_1-bar_midpoint))>MathAbs(low_1-bar_midpoint) && //Ensure the bottom wick of the bar 1 isn't overly large compared to the body.
      timeBUOVB_BEOVB!=iTime(SymbolCheck,PeriodCheck,1) &&
      _bar1size > bar1size
//&& _minZoneThickness > minZoneThickness //thickness of bar 2 must be above minimum threshold
   )
     {
      if(result==NULL)
        {
         result="Bullish_Engulfing";
         //Print(_minZoneThickness);
         //--- once pattern found create a rectangle to identify the level.
         if(!RectangleCreate(0,"Demand_"+IntegerToString(DemandLevelCounter),0,time_2,MathMax(open_2,close_2),time_1+6*PeriodCheck*60,low_2,virginDemandLevelColour,LineStyle,1,true,SetAsBack))
           {
            Print("Can't make Demand level");
           }
         else
           {
            TextCreate(0,"Txt_Demand_"+IntegerToString(DemandLevelCounter),0,time_2,low_2,"text"); //time_1+10*Period()*60
            DemandLevelCounter++;
           }
        }
      else
        {
         Print("Result isn't null so can't set. Current result is "+result+" "+timeBUOVB_BEOVB);
        }
      timeBUOVB_BEOVB=iTime(SymbolCheck,PeriodCheck,1); //indicate that orders are already placed on this pattern

     }

//--- Finding bearish Engulfing
   if(
      MathAbs(open_1-close_1)/2>MathAbs(open_2-close_2) &&
      low_1<low_2 && //High_1 must be double the height of high 2
      open_1>close_1 && //signifies bull candle and prevents bearish candles here.
      open_1+pip_buffer>open_2 && //implement bottom buffer
      high_1+2*pip_buffer>high_2 &&
      MathAbs(1.5*(close_1-bar_midpoint))>MathAbs(high_1-bar_midpoint) &&
      timeBUOVB_BEOVB!=iTime(SymbolCheck,Period(),1) &&
      _bar1size > bar1size
//&& _minZoneThickness > minZoneThickness //thickness of bar 2 must be above threshold
      /* old method to define engulfing
      low_1 < low_2 &&          //First bar's Low is below second bar's Low
      high_1 > high_2 &&        //First bar's High is above second bar's High
      close_1 < open_2 &&       //First bar's Close price is lower than second bar's Open price
      open_1 > close_1 &&       //First bar is a bearish bar
      open_2<close_2 &&
      */
   )
     {
      if(result==NULL)
        {
         result="Bearish_Engulfing";
         //Print(_minZoneThickness);
         //--- once pattern found create a rectangle to identify the level.
         if(!RectangleCreate(0,"Supply_"+IntegerToString(SupplyLevelCounter),0,time_2,MathMin(open_2,close_2),time_1+10*Period()*60,high_2,virginSupplyLevelColour,LineStyle,1,true,SetAsBack))
           {
            Print("Can't make Supply level");
           }
         else
           {
            TextCreate(0,"Txt_Supply_"+IntegerToString(SupplyLevelCounter),0,time_2,low_2,"text"); //time_1+10*Period()*60
            //TextCreate(0,"Txt_Supply_"+IntegerToString(SupplyLevelCounter),0,time_1+10*Period()*60,high_2,"text");
            SupplyLevelCounter++;
           }
        }
      else
        {
         Print("Result isn't null so can't set. Current result is "+result+" "+timeBUOVB_BEOVB);
        }
      timeBUOVB_BEOVB=iTime(SymbolCheck,PeriodCheck,1);
     }

//Print(timeBUOVB_BEOVB);
//--- output the result
   if(result!=NULL)
     {
      //Output the full data set of the find into a array.
      //outArray 1 - Name of symbol
      outArray[1]=result;
      //outArray 2 - Period
      outArray[2]=PeriodCheck;
      //outArray 3 - Open 1
      outArray[3]=DoubleToStr(open_1);
      //outArray 4 - Open 2
      outArray[4]=DoubleToStr(open_2);
      //outArray 5 - Open 3
      outArray[5] = DoubleToStr(open_3);
      outArray[6] = DoubleToStr(close_1);
      outArray[7] = DoubleToStr(close_2);
      outArray[8] = DoubleToStr(close_3);
      outArray[9] = DoubleToStr(low_1);
      outArray[10] = DoubleToStr(low_2);
      outArray[11] = DoubleToStr(low_3);
      outArray[12] = DoubleToStr(high_1);
      outArray[13] = DoubleToStr(high_2);
      outArray[14] = DoubleToStr(high_3);
      outArray[15] = TimeToStr(time_1);
      outArray[16] = TimeToStr(time_2);
      return(result);
     }
   else
     {
      return(NULL);

     }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int i;
   double sl=0;
   double tp=0;
   double tp2=0;
   int openticket1=0;
   int openticket2=0;
   double openprice1=0;
   double openprice2=0;
   double stoploss2=0;
   double stop=0;

   bool enableopen=true;

   string strname;
   string strlots;
   string infobox;
   double upperline;
   double lowerline;
   datetime backline;
   datetime frontline;

   CheckBoxes();  //Delete limit trades if Box is deleted or change its colour
   FindClosedTrades(); //Change closed trades box to blue and tp line to dashes
   DeleteTradeAfterBox(); //Delete Limit trades that is outside box
   TPLinesMoved();   //Check if TP line is moved
   BoxMoved();       //Check if Box is moved
   SetPending2();  //Set second order trade

//--- Bullish and Bearish engulfing pattern find
   /*
   CandleFinder=CandleIdentifier(Symbol(),PERIOD_M5,1,2,3,clrBlue,STYLE_SOLID,NULL,arrayOut);
   ModifySDLevels(DemandLevelCounter,"Demand_",NULL,NULL,iTime(Symbol(), 0, 2),NULL,NULL); //Stretch all levels to reach the current time.
   ModifySDLevels(SupplyLevelCounter,"Supply_",NULL,NULL,iTime(Symbol(), 0, 2),NULL,NULL); //Stretch all levels to reach the current time.
   CleanAbsorbedLevels(Symbol(),Period(),DemandLevelCounter,"Demand_"); //Calculate the amount of penetrated levels for all Demand levels and adjust the size.
   CleanAbsorbedLevels(Symbol(),Period(),SupplyLevelCounter,"Supply_"); //Calculate the amount of penetrated levels for all Supply levels
   */

   if(enableopen)
     {
      for(i=0; i<ObjectsTotal(); i++)
        {
         strname=ObjectName(0,i);
         if(ObjectType(strname)==OBJ_RECTANGLE)
           {
            if(ObjectGet(strname,OBJPROP_COLOR)==activate_colour)
              {
               strlots=ObjectDescription(strname);

               double price1=GetRectPrice(strname,OBJPROP_PRICE1);
               double price2=GetRectPrice(strname,OBJPROP_PRICE2);
               datetime time1=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME1)));
               datetime time2=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME2)));
               upperline=MathMax(price1,price2);
               lowerline=MathMin(price1,price2);
               frontline=MathMax(time1,time2);
               backline=MathMin(time1,time2);
               double draft_vTP1_price=0;
               double tp_in_pips=0;
               double RvR=0;

               int cmd=-1;

               if(Bid>upperline)
                 {
                  cmd=OP_BUYLIMIT;
                  openprice1=upperline;
                  sl=lowerline;
                  stop=(openprice1-sl)/myPoint;
                  tp=setTP(openprice1,2*stop);
                 }
               else
                  if(Bid<lowerline)
                    {
                     cmd=OP_SELLLIMIT;
                     openprice1=lowerline;
                     sl=upperline;
                     stop=(sl-openprice1)/myPoint;
                     tp=setTP(openprice1,-2*stop);
                    }

               if(ObjectFind("vTP1_"+strname)==-1 && isAlreadyEnter("_"+strname+"_")==false)
                 {
                  DrawTL("vTP1_"+strname,tp,backline,tp,frontline,clrYellow,STYLE_DASH,1);
                  TextCreate(0,"InfoBox_"+strname,0,time1,sl,infobox,"Ariel",9,clrYellow,0.0,ANCHOR_LEFT_UPPER);
                 }

               // Check if V_Rectangle line exists
               //bool vRectFound = ObjectFind("blueBoxTPName") != -1;
               //double vRectPrice;

               if(ObjectFind("blueBoxTPName") != -1 && ObjectFind("vTP1_"+strname) != -1)
                 {
                  // Get V_Rectangle price
                  double vRectPrice = ObjectGet("blueBoxTPName",OBJPROP_PRICE1);
                  ObjectSet("vTP1_"+strname,OBJPROP_PRICE1,vRectPrice);
                  ObjectSet("vTP1_"+strname,OBJPROP_PRICE2,vRectPrice);

                  // Delete V_Rectangle
                  ObjectDelete("blueBoxTPName");
                 }

               tp=ObjectGet("vTP1_"+strname,OBJPROP_PRICE1);

               if(isAlreadyEnter("_"+strname+"_")==false && TimeCurrent()<=frontline)
                 {

                  draft_vTP1_price=ObjectGet("vTP1_"+strname,OBJPROP_PRICE1);
                  if(cmd==OP_BUYLIMIT)
                     tp_in_pips=NormalizeDouble((draft_vTP1_price-openprice1)/myPoint,Digits);
                  else
                     if(cmd==OP_SELLLIMIT)
                        tp_in_pips=NormalizeDouble((openprice1-draft_vTP1_price)/myPoint,Digits);
                  if(cmd>0)
                     RvR=tp_in_pips/stop;

                  if(StringFind(strlots,"%")!=-1)
                    {
                     double percent=StrToDouble(StringSubstr(strlots,0,StringFind(strlots,"%")));
                     double my_lots2;
                     if(Digits==3 || Digits==5)
                        my_lots2=(AccountBalance()*percent*0.01)/(stop*myTickValue*10);
                     else
                        my_lots2=(AccountBalance()*percent*0.01)/(stop*myTickValue);
                     my_lots=NormalizeDouble(my_lots2,digit_lot);
                    }
                  else
                     if(StringFind(strlots,"%")==-1)
                        my_lots=StrToDouble(strlots);
                  if(my_lots<MarketInfo(Symbol(),MODE_MINLOT))
                     my_lots=MarketInfo(Symbol(),MODE_MINLOT);
                  if(my_lots>MarketInfo(Symbol(),MODE_MAXLOT))
                     my_lots=MarketInfo(Symbol(),MODE_MAXLOT);

                  //Open the trade
                  if(strlots!="")
                     openticket1=Open_Trade(Symbol(),cmd,openprice1,my_lots,sl,tp,"T01_"+strname+"_"+TradeCode);

                  infobox="SL: "+DoubleToStr(NormalizeDouble(stop,2),1)+" | TP: "+DoubleToStr(tp_in_pips,1)+" | RvR: "+DoubleToStr(RvR,1);

                  if(openticket1>0)
                    {
                     if(cmd==OP_BUYLIMIT)
                        Alert("BUY LIMIT "+Symbol()+" "+strtf(Period())+" Date & Time: "+TimeToStr(TimeCurrent(),TIME_DATE)+" "+TimeToStr(TimeCurrent(),TIME_MINUTES)+" - "+WindowExpertName());
                     else
                        if(cmd==OP_SELLLIMIT)
                           Alert("SELL LIMIT "+Symbol()+" "+strtf(Period())+" Date & Time: "+TimeToStr(TimeCurrent(),TIME_DATE)+" "+TimeToStr(TimeCurrent(),TIME_MINUTES)+" - "+WindowExpertName());

                     DrawTL("vTP1_"+IntegerToString(openticket1),tp,backline,tp,frontline,clrYellow,STYLE_SOLID,2);

                     ObjectDelete("vTP1_"+strname);

                     if(allowed_2nd_trade)
                       {
                        int cmd2=-1;
                        if(cmd==OP_BUYLIMIT)
                          {
                           openprice2=openprice1+(stop*myPoint);
                           tp2=setTP(openprice1,2*stop);
                           //If we want halfway between the TP and the entry then use this-
                           //tp=ObjectGet("vTP1_"+strname,OBJPROP_PRICE1);
                           //openprice2=tp-(tp_in_pips*0.5*myPoint);
                           stoploss2=openprice1-(0.5*stop*myPoint);
                          }
                        else
                           if(cmd==OP_SELLLIMIT)
                             {
                              openprice2=openprice1-(stop*myPoint);
                              tp2=setTP(openprice1,-2*stop);
                              //If we want halfway between the TP and the entry then use this-
                              //tp=ObjectGet("vTP1_"+strname,OBJPROP_PRICE1);
                              //openprice2=tp+(tp_in_pips*0.5*myPoint);
                              stoploss2=openprice1+(0.5*stop*myPoint);
                             }
                        DrawTL("vOP2_"+IntegerToString(openticket1),openprice2,backline,openprice2,frontline,clrGreen,STYLE_SOLID,1);
                        DrawTL("vvOP2_"+IntegerToString(openticket1),openprice2,backline,openprice2,frontline,clrNONE,STYLE_SOLID,1);
                        DrawTL("vSL2_"+IntegerToString(openticket1),stoploss2,backline,stoploss2,frontline,clrBrown,STYLE_SOLID,2);
                        DrawTL("vTP2_"+IntegerToString(openticket1),tp2,backline,tp2,frontline,clrBrown,STYLE_SOLID,2);

                        ObjectSet("vTP1_"+IntegerToString(openticket1),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vTP1_"+IntegerToString(openticket1),OBJPROP_TIME2,MathMax(time1,time2));

                       }
                    }
                  TextChange(0,"InfoBox_"+strname,infobox);
                  TextMove(0,"InfoBox_"+strname,time1,sl);
                  ObjectSet("vTP1_"+strname,OBJPROP_TIME1,MathMin(time1,time2));
                  ObjectSet("vTP1_"+strname,OBJPROP_TIME2,MathMax(time1,time2));
                  ObjectSet("vSL2_"+strname,OBJPROP_TIME1,MathMin(time1,time2));
                  ObjectSet("vSL2_"+strname,OBJPROP_TIME2,MathMax(time1,time2));

                 }
              }
            if(ObjectGet(strname,OBJPROP_COLOR)==clrGold)
              {
               strlots=ObjectDescription(strname);
               //TO DO - Look for a box that is gold and within that box if it detects any new engulfing candles form then enter that trade automatically.
               //Useful to trade when in HTF levels and you want to enter upon the formation of a short TF supply or demand level to enter at the very LOWEST RISK / Highest reward
               //Also useful when there is a key maximum point and there is a supply on the HTF as well as LTF and you don't want to be caught with SL going a few pips above the max then dropping.
               //"SUP,0.5" entered in description should only look for supply levels and enter 0.5 lots per trade
               //What abot RvR? Forced at double? For now yes, then we can optimise it later.
               //Max loss trades?
               //

              }
           }
         if(StringFind(strname,"InfoBox_")!=-1)
           {
            if(ObjectFind(0,StringSubstr(strname,8,StringLen(strname)))==-1)
              {
               TextDelete(0,strname);
              }
           }
         if(StringFind(strname,"vTP1_Rectangle")!=-1)
           {
            if(ObjectFind(0,StringSubstr(strname,5,StringLen(strname)))==-1)
              {
               ObjectDelete(strname);
              }
           }
        }
     }

/// Blue box trading ---------------------------------------------------
   string TargetBoxName;
// Loop through all objects on chart
   for(int i=ObjectsTotal()-1; i>=0; i--)
     {
      string objectName = ObjectName(i);

      // Check if current object color is blue
      if(ObjectGetInteger(0, objectName, OBJPROP_COLOR) == clrBlue && ObjectGetInteger(0, objectName, OBJPROP_TYPE) == OBJ_RECTANGLE)
        {
         // Object is blue

         //initiaize the 1M chart
         CurrentSupDem=iCustom(Symbol(),PERIOD_M1,"II_SupDemMOD_DarkBG_SolidFill_Sow",
                               //---- iCustom values ---
                               // ENUM_TIMEFRAMES forced_tf=
                               PERIOD_CURRENT,
                               //bool draw_zones=
                               true,
                               //bool solid_zones=
                               true,
                               //bool solid_retouch=
                               true,
                               //bool recolor_retouch=
                               true,
                               //bool recolor_weak_retouch =
                               true,
                               //bool zone_strength =
                               true,
                               //bool no_weak_zones =
                               true,
                               //bool draw_edge_price=
                               false,
                               //int zone_width =
                               1,
                               //bool zone_fibs =
                               false,
                               //int fib_style=
                               0,
                               //bool HUD_on=
                               false,
                               //bool timer_on=
                               true,
                               //int layer_zone=
                               0,
                               //int layer_HUD =
                               20,
                               //int corner_HUD=
                               2,
                               //int pos_x =
                               100,
                               //int pos_y =
                               20,
                               //bool alert_on=
                               false,
                               //bool alert_popup=
                               false,
                               //string alert_sound=
                               "radar1.wav",
                               //color color_sup_strong=
                               C'67,78,92',
                               //color color_sup_weak=
                               C'74,74,74',
                               //color color_sup_retouch=
                               C'35,43,50',
                               //color color_dem_strong =
                               C'67,78,92',
                               //color color_dem_weak=
                               C'29,47,88',
                               //color color_dem_retouch=
                               C'29,47,88',
                               //color color_fib=
                               DodgerBlue,
                               //color color_HUD_tf=
                               Navy,
                               //color color_arrow_up =
                               SeaGreen,
                               //color color_arrow_dn =
                               Crimson,
                               //color color_timer_back=
                               DarkGray,
                               //color color_timer_bar =
                               Red,
                               //color color_shadow=
                               DarkSlateGray,

                               //bool limit_zone_vis=
                               false,
                               //bool same_tf_vis=
                               true,
                               //bool show_on_m1 =
                               false,
                               //bool show_on_m5 =
                               false,
                               //bool show_on_m15 =
                               false,
                               //bool show_on_m30 =
                               false,
                               //bool show_on_h1 =
                               false,
                               //bool show_on_h4 =
                               false,
                               //bool show_on_d1 =
                               false,
                               //bool show_on_w1 =
                               false,
                               //bool show_on_mn =
                               false,

                               //int Price_Width=
                               1,
                               //int time_offset=
                               0,
                               //bool globals=
                               false,
                               //string BoxSuffix=
                               "M1",
                               //bool show_hollow=
                               false,
                               //OBJPROP_STYLE dash_style=
                               STYLE_DASHDOT,
                               0,// iCustom line index

                               0  // iCustom shift
                              );

         // Get coordinates
         double blueBoxLeft = ObjectGet(objectName, OBJPROP_TIME1);
         double blueBoxTop = ObjectGet(objectName, OBJPROP_PRICE1);
         double blueBoxRight = ObjectGet(objectName, OBJPROP_TIME2);
         double blueBoxBottom = ObjectGet(objectName, OBJPROP_PRICE2);

         double blueBoxHeight = MathAbs(blueBoxTop - blueBoxBottom);



         if(Bid < blueBoxBottom)
           {
            TargetBoxName = "a|II_Logo_0_M1_UPZONE1";
            double lineDistance = blueBoxBottom - (blueBoxHeight * 2);
            double lineLeft = blueBoxLeft;
            double lineRight = blueBoxRight;

            DrawTL("blueBoxTPName",lineDistance,lineLeft,lineDistance,lineRight,clrBlue,STYLE_DASH,1);

           }

         if(Bid > blueBoxBottom)
           {
            TargetBoxName = "a|II_Logo_0_M1_DNZONE1";
            double lineDistance = blueBoxBottom + (blueBoxHeight * 2);
            double lineLeft = blueBoxLeft;
            double lineRight = blueBoxRight;

            DrawTL("blueBoxTPName",lineDistance,lineLeft,lineDistance,lineRight,clrBlue,STYLE_DASH,1);

           }
         
         // Loop through objects again to find TargetBoxName
         for(int j=ObjectsTotal()-1; j>=0; j--)
           {
            string innerObjectName = ObjectName(j);

            // Check if current inner object is TargetBoxName
            if(innerObjectName == TargetBoxName)
              {
               // Get coordinates of TargetBoxName

               //datetime time1=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME1)));
               //datetime time2=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME2)));

               double targetBoxLeft = ObjectGet(innerObjectName, OBJPROP_TIME1);
               double targetBoxTop = ObjectGet(innerObjectName, OBJPROP_PRICE1);
               double targetBoxRight = ObjectGet(innerObjectName, OBJPROP_TIME2);
               double targetBoxBottom = ObjectGet(innerObjectName, OBJPROP_PRICE2);

               // Check if TargetBoxName is within blue box
               if(targetBoxLeft >= blueBoxLeft &&
                  targetBoxTop <= blueBoxTop &&
                  targetBoxRight <= blueBoxRight &&
                  targetBoxBottom >= blueBoxBottom)
                 {
                  // Target box is within blue box

                  // Create new red box over TargetBoxName

                  RectangleCreate(0, "RedBox", 0, targetBoxLeft, targetBoxTop, blueBoxRight, targetBoxBottom, clrRed, 0, true, false, false);

                  // Get description of blue box
                  string blueBoxDesc = ObjectDescription(objectName);

                  // Set red box description to match blue box
                  ObjectSetString(0, "RedBox", OBJPROP_TEXT, blueBoxDesc);

                  // Change blue box to transparent dashed line
                  ObjectSetInteger(0, objectName, OBJPROP_COLOR, clrViolet);
                  ObjectSetInteger(0, objectName, OBJPROP_BACK, false);
                  ObjectSetInteger(0, objectName, OBJPROP_FILL, false);
                  //ObjectSetInteger(0, objectName, OBJPROP_BORDER_COLOR, clrViolet);
                  //ObjectSetInteger(0, objectName, OBJPROP_STYLE, STYLE_DASHDOTDOT);

                  //TODO -Take the blue dashed line and replace value with value for yellow

                  // Remove blue dashed line object
                  //ObjectDelete(0, "DashLine");

                  Alert("Box Found!");




                 }
              }
           }
        }
     }
   if(TimeCurrent()>=refreshcharttime)
     {
      //refresh chart every minute
      refreshcharttime=TimeCurrent()+60;

      CurrentSupDem=iCustom(Symbol(),PERIOD_M15,"II_SupDemMOD_DarkBG_SolidFill_Sow",
                            //---- iCustom values ---
                            // ENUM_TIMEFRAMES forced_tf=
                            PERIOD_CURRENT,
                            //bool draw_zones=
                            true,
                            //bool solid_zones=
                            true,
                            //bool solid_retouch=
                            true,
                            //bool recolor_retouch=
                            true,
                            //bool recolor_weak_retouch =
                            true,
                            //bool zone_strength =
                            true,
                            //bool no_weak_zones =
                            true,
                            //bool draw_edge_price=
                            false,
                            //int zone_width =
                            1,
                            //bool zone_fibs =
                            false,
                            //int fib_style=
                            0,
                            //bool HUD_on=
                            false,
                            //bool timer_on=
                            true,
                            //int layer_zone=
                            0,
                            //int layer_HUD =
                            20,
                            //int corner_HUD=
                            2,
                            //int pos_x =
                            100,
                            //int pos_y =
                            20,
                            //bool alert_on=
                            false,
                            //bool alert_popup=
                            false,
                            //string alert_sound=
                            "radar1.wav",
                            //color color_sup_strong=
                            C'67,78,92',
                            //color color_sup_weak=
                            C'74,74,74',
                            //color color_sup_retouch=
                            C'35,43,50',
                            //color color_dem_strong =
                            C'67,78,92',
                            //color color_dem_weak=
                            C'29,47,88',
                            //color color_dem_retouch=
                            C'29,47,88',
                            //color color_fib=
                            DodgerBlue,
                            //color color_HUD_tf=
                            Navy,
                            //color color_arrow_up =
                            SeaGreen,
                            //color color_arrow_dn =
                            Crimson,
                            //color color_timer_back=
                            DarkGray,
                            //color color_timer_bar =
                            Red,
                            //color color_shadow=
                            DarkSlateGray,

                            //bool limit_zone_vis=
                            false,
                            //bool same_tf_vis=
                            true,
                            //bool show_on_m1 =
                            false,
                            //bool show_on_m5 =
                            false,
                            //bool show_on_m15 =
                            false,
                            //bool show_on_m30 =
                            false,
                            //bool show_on_h1 =
                            false,
                            //bool show_on_h4 =
                            false,
                            //bool show_on_d1 =
                            false,
                            //bool show_on_w1 =
                            false,
                            //bool show_on_mn =
                            false,

                            //int Price_Width=
                            1,
                            //int time_offset=
                            0,
                            //bool globals=
                            false,
                            //string BoxSuffix=
                            "15M",
                            //bool show_hollow=
                            false,
                            //OBJPROP_STYLE dash_style=
                            STYLE_DASHDOT,
                            0,// iCustom line index

                            0  // iCustom shift
                           );

      H1SupDem=iCustom(Symbol(),PERIOD_H1,"II_SupDemMOD_DarkBG_SolidFill_Sow",
                       //---- iCustom values ---
                       // ENUM_TIMEFRAMES forced_tf=
                       PERIOD_CURRENT,//in order to draw indi right this must be set to period curret despite the icustom calling the Period_1H
                       //bool draw_zones=
                       true,
                       //bool solid_zones=
                       true,
                       //bool solid_retouch=
                       true,
                       //bool recolor_retouch=
                       true,
                       //bool recolor_weak_retouch =
                       true,
                       //bool zone_strength =
                       true,
                       //bool no_weak_zones =
                       true,

                       //bool draw_edge_price=
                       false,
                       //int zone_width =
                       1,

                       //bool zone_fibs =
                       false,
                       //int fib_style=
                       0,

                       //bool HUD_on=
                       false,
                       //bool timer_on=
                       true,
                       //int layer_zone=
                       0,
                       //int layer_HUD =
                       20,
                       //int corner_HUD=
                       2,
                       //int pos_x =
                       100,
                       //int pos_y =
                       20,

                       //bool alert_on=
                       false,
                       //bool alert_popup=
                       false,

                       //string alert_sound=
                       "radar1.wav",
                       //color color_sup_strong=
                       C'53,63,74',
                       //color color_sup_weak=
                       C'74,74,74',
                       //color color_sup_retouch=
                       C'35,43,50',
                       //color color_dem_strong =
                       C'53,63,74',
                       //color color_dem_weak=
                       C'29,47,88',
                       //color color_dem_retouch=
                       C'29,47,88',
                       //color color_fib=
                       DodgerBlue,
                       //color color_HUD_tf=
                       Navy,
                       //color color_arrow_up =
                       SeaGreen,
                       //color color_arrow_dn =
                       Crimson,
                       //color color_timer_back=
                       DarkGray,
                       //color color_timer_bar =
                       Red,
                       //color color_shadow=
                       DarkSlateGray,

                       //bool limit_zone_vis=
                       false,
                       //bool same_tf_vis=
                       true,
                       //bool show_on_m1 =
                       false,
                       //bool show_on_m5 =
                       false,
                       //bool show_on_m15 =
                       false,
                       //bool show_on_m30 =
                       false,
                       //bool show_on_h1 =
                       false,
                       //bool show_on_h4 =
                       false,
                       //bool show_on_d1 =
                       false,
                       //bool show_on_w1 =
                       false,
                       //bool show_on_mn =
                       false,
                       //int Price_Width=
                       1,
                       //int time_offset=
                       0,
                       //bool globals=
                       false,
                       //string BoxSuffix=
                       "H1",
                       //bool show_hollow=
                       true,
                       //OBJPROP_STYLE dash_style=
                       STYLE_DASHDOT,
                       // iCustom line index
                       0,
                       // iCustom shift
                       1
                      );

      H4SupDem=iCustom(Symbol(),PERIOD_H4,"II_SupDemMOD_DarkBG_SolidFill_Sow",
                       //---- iCustom values ---
                       // ENUM_TIMEFRAMES forced_tf=
                       PERIOD_CURRENT,//in order to draw indi right this must be set to period curret despite the icustom calling the Period_1H
                       //bool draw_zones=
                       true,
                       //bool solid_zones=
                       true,
                       //bool solid_retouch=
                       true,
                       //bool recolor_retouch=
                       true,
                       //bool recolor_weak_retouch =
                       true,
                       //bool zone_strength =
                       true,
                       //bool no_weak_zones =
                       true,

                       //bool draw_edge_price=
                       false,
                       //int zone_width =
                       1,

                       //bool zone_fibs =
                       false,
                       //int fib_style=
                       0,

                       //bool HUD_on=
                       false,
                       //bool timer_on=
                       true,
                       //int layer_zone=
                       0,
                       //int layer_HUD =
                       20,
                       //int corner_HUD=
                       2,
                       //int pos_x =
                       100,
                       //int pos_y =
                       20,

                       //bool alert_on=
                       false,
                       //bool alert_popup=
                       false,

                       //string alert_sound=
                       "radar1.wav",
                       //color color_sup_strong=
                       C'53,63,74',
                       //color color_sup_weak=
                       C'74,74,74',
                       //color color_sup_retouch=
                       C'35,43,50',
                       //color color_dem_strong =
                       C'53,63,74',
                       //color color_dem_weak=
                       C'29,47,88',
                       //color color_dem_retouch=
                       C'29,47,88',
                       //color color_fib=
                       DodgerBlue,
                       //color color_HUD_tf=
                       Navy,
                       //color color_arrow_up =
                       SeaGreen,
                       //color color_arrow_dn =
                       Crimson,
                       //color color_timer_back=
                       DarkGray,
                       //color color_timer_bar =
                       Red,
                       //color color_shadow=
                       DarkSlateGray,

                       //bool limit_zone_vis=
                       false,
                       //bool same_tf_vis=
                       true,
                       //bool show_on_m1 =
                       false,
                       //bool show_on_m5 =
                       false,
                       //bool show_on_m15 =
                       false,
                       //bool show_on_m30 =
                       false,
                       //bool show_on_h1 =
                       false,
                       //bool show_on_h4 =
                       false,
                       //bool show_on_d1 =
                       false,
                       //bool show_on_w1 =
                       false,
                       //bool show_on_mn =
                       false,
                       //int Price_Width=
                       1,
                       //int time_offset=
                       0,
                       //bool globals=
                       false,
                       //string BoxSuffix=
                       "H4",
                       //bool show_hollow=
                       true,
                       //OBJPROP_STYLE dash_style=
                       STYLE_DASH,
                       // iCustom line index
                       0,
                       // iCustom shift
                       1
                      );

     }


//----

  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+-------------------------General Functions------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifySDLevels(int Counter,string LevelPrefix,datetime time_1,double price_1,datetime time_2,double price_2,color SD_level_colour) //function to increase the length of valid SD levels.
  {
   int i=1;
//if counter is zero then modify a single level using the LevelPrefix as the full name of level to modify.
   if(Counter==0)
     {
      if(time_1!=NULL)
         if(!ObjectSet(LevelPrefix,OBJPROP_TIME1,time_1))
            Print("Error in ObjectSet: "+IntegerToString(GetLastError())+" Count: "+IntegerToString(i)+" ObjectName: "+LevelPrefix);
      if(time_2!=NULL)
         if(!ObjectSet(LevelPrefix,OBJPROP_TIME2,time_2))
            Print("Error in ObjectSet: "+IntegerToString(GetLastError())+" Count: "+IntegerToString(i)+" ObjectName: "+LevelPrefix);
      if(price_1!=NULL)
         if(!ObjectSet(LevelPrefix,OBJPROP_PRICE1,price_1))
            Print("Error in ObjectSet: "+IntegerToString(GetLastError())+" Count: "+IntegerToString(i)+" ObjectName: "+LevelPrefix);
      if(price_2!=NULL)
         if(!ObjectSet(LevelPrefix,OBJPROP_PRICE2,price_2))
            Print("Error in ObjectSet: "+IntegerToString(GetLastError())+" Count: "+IntegerToString(i)+" ObjectName: "+LevelPrefix);
      if(SD_level_colour!=NULL)
         if(!ObjectSet(LevelPrefix,OBJPROP_COLOR,SD_level_colour))
            Print("Error in ObjectSet: "+IntegerToString(GetLastError())+" Count: "+IntegerToString(i)+" ObjectName: "+LevelPrefix);
     }
   else
      //otherwise if counter is not zero then go through each level and modify as required.
     {
      while(i<=Counter)
        {
         //if object is found and its not either the whored out supply colour or demand colour
         if(ObjectFind(StringConcatenate(LevelPrefix,IntegerToString(i)))!=-1 && (ObjectGet(StringConcatenate(LevelPrefix,IntegerToString(i)),OBJPROP_COLOR)!=whoredOutSupplyLevelColour || ObjectGet(StringConcatenate(LevelPrefix,IntegerToString(i)),OBJPROP_COLOR)!=whoredOutDemandLevelColour))
           {
            if(time_1!=NULL)
               if(!ObjectSet(LevelPrefix+IntegerToString(i),OBJPROP_TIME1,time_1))
                  Print("Error in ObjectSet: "+IntegerToString(GetLastError())+" Count: "+IntegerToString(i));
            if(time_2!=NULL)
               if(!ObjectSet(LevelPrefix+IntegerToString(i),OBJPROP_TIME2,time_2))
                  Print("Error in ObjectSet: "+IntegerToString(GetLastError())+" Count: "+IntegerToString(i));
            if(price_1!=NULL)
               if(!ObjectSet(LevelPrefix+IntegerToString(i),OBJPROP_PRICE1,price_1))
                  Print("Error in ObjectSet: "+IntegerToString(GetLastError())+" Count: "+IntegerToString(i));
            if(price_2!=NULL)
               if(!ObjectSet(LevelPrefix+IntegerToString(i),OBJPROP_PRICE2,price_2))
                  Print("Error in ObjectSet: "+IntegerToString(GetLastError())+" Count: "+IntegerToString(i));
            if(SD_level_colour!=NULL)
               if(!ObjectSet(LevelPrefix+IntegerToString(i),OBJPROP_COLOR,SD_level_colour))
                  Print("Error in ObjectSet: "+IntegerToString(GetLastError())+" Count: "+IntegerToString(i));
           }
         i++;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CleanAbsorbedLevels(string SymbolCheck,
                         int PeriodCheck,
                         int Counter,
                         string LevelPrefix) //change the color and end time of the tables
  {
   int i=1,
       EntryBar,
       PartialPenetrationCounter=0, //counter for the number of times the level has been partially penetrated.
       FullPenetrationCounter=0,    //counter for the number of times the level has been fully penetrated
       AllPenetrationsCount=0;
   double price_1,
          price_2,
          price_top,     //The top price of the level
          price_bottom;  //The bottom price of the level
   datetime time_1;
//go through each level
   while(i<=Counter)
     {
      //check to see if the level exists
      if(ObjectFind(StringConcatenate(LevelPrefix,IntegerToString(i)))!=-1)
        {
         //if so check to see their colour is not one of the whoredOut colors
         if(ObjectGet(StringConcatenate(LevelPrefix,IntegerToString(i)),OBJPROP_COLOR)!=whoredOutDemandLevelColour || ObjectGet(StringConcatenate(LevelPrefix,IntegerToString(i)),OBJPROP_COLOR)!=whoredOutSupplyLevelColour) //Check to see if the level is the entry colour of Blue showing fresh level
           {
            //Get the top left price of level
            price_1=ObjectGet(StringConcatenate(LevelPrefix,IntegerToString(i)),OBJPROP_PRICE1);
            //Get the bottom right price of the level
            price_2=ObjectGet(StringConcatenate(LevelPrefix,IntegerToString(i)),OBJPROP_PRICE2);
            //Out of the two prices find the top of the level
            price_top=MathMax(price_1,price_2);
            //Out of the two prices find the bottom of the level
            price_bottom=MathMin(price_1,price_2);
            //Find the initial time of the box (left hand side)
            time_1=ObjectGet(StringConcatenate(LevelPrefix,IntegerToString(i)),OBJPROP_TIME1);
            //Find the bar position of the beginning of the level
            EntryBar=iBarShift(SymbolCheck,PeriodCheck,time_1);
            //Reset the PartialPenetrationCounter for each loop
            PartialPenetrationCounter=0;
            //Reset the FullPenetrationCounter for each loop
            FullPenetrationCounter=0;

            //loop through each candle starting from the second bar missing bar 1 when the level started right up to current price bar
            for(int x=EntryBar-2; x>1; x--)
              {

               //Defines how to detect and calculate penetrations
               //For any candles that poke from the bottom but dont pierce through
               if(iHigh(SymbolCheck,PeriodCheck,x)>price_bottom && iLow(SymbolCheck,PeriodCheck,x)<price_bottom && iHigh(SymbolCheck,PeriodCheck,x)<price_top)
                 {
                  //Draw an arrow showing the point of penetration
                  //ArrowCreate(OBJ_ARROW_DOWN,0,LevelPrefix+IntegerToString(i)+"_"+TimeToStr(Time[x])+"_"+DoubleToStr(price_top),0,Time[x],High[x],ANCHOR_BOTTOM,clrYellow);
                  //ArrowCreate(OBJ_ARROW_DOWN,0,LevelPrefix+IntegerToString(i)+"_"+TimeToStr(Time[x])+"_"+DoubleToStr(price_bottom),0,Time[x],High[x]);
                  PartialPenetrationCounter++;
                 }
               //For any candles that poke from the top but dont pierce through
               if(iHigh(SymbolCheck,PeriodCheck,x)>price_top && iLow(SymbolCheck,PeriodCheck,x)<price_top && iLow(SymbolCheck,PeriodCheck,x)>price_bottom) //For any candles with pierce the top but dont pierce through
                 {
                  //ArrowCreate(OBJ_ARROW_DOWN,0,LevelPrefix+IntegerToString(i)+"_"+TimeToStr(Time[x])+"_"+DoubleToStr(price_top),0,Time[x],High[x],ANCHOR_BOTTOM,clrYellow);
                  PartialPenetrationCounter++;
                 }
               //For any candles that slice through the level whole
               if(iHigh(SymbolCheck,PeriodCheck,x)>price_top && iLow(SymbolCheck,PeriodCheck,x)<price_bottom) //For any candles that break through the level completely
                 {
                  //ArrowCreate(OBJ_ARROW_UP,0,LevelPrefix+IntegerToString(i)+"_"+TimeToStr(Time[x])+"_"+DoubleToStr(price_top)+" "+DoubleToStr(price_bottom),0,Time[x],Low[x],ANCHOR_TOP,clrWhite);
                  FullPenetrationCounter++;
                 }
               //For any candles that gradually slice through the level - found that this was really hard to get right.
               if(iHigh(SymbolCheck,PeriodCheck,x+3)> price_top && //Check 3 candles prior and make sure it's high is above the top of the level.
                  iLow(SymbolCheck,PeriodCheck,x)< price_bottom && //Check the current candle and ensure its bottom is below the top of the level.
                  (
                     (iLow(SymbolCheck,PeriodCheck,x+2) > price_bottom && iHigh(SymbolCheck,PeriodCheck,x+2) > price_top) ||  //Check if bar 2 is enclosed within the top and bottom
                     (iLow(SymbolCheck,PeriodCheck,x+1) > price_bottom && iHigh(SymbolCheck,PeriodCheck,x+1) > price_top)     //OR Check if bar 1 is enclosed within the top and bottom
                  )
                 ) //For any candles that break through the level completely
                 {
                  //ArrowCreate(OBJ_ARROW_UP,0,LevelPrefix+IntegerToString(i)+"_"+TimeToStr(Time[x])+"_"+DoubleToStr(price_top)+" "+DoubleToStr(price_bottom),0,Time[x],Low[x],ANCHOR_TOP,clrBlueViolet);
                  FullPenetrationCounter++;
                 }

               TextChange(0,"Txt_"+LevelPrefix+IntegerToString(i),PartialPenetrationCounter+FullPenetrationCounter);
               if(!ObjectSetText(LevelPrefix+IntegerToString(i),"Counter:"+IntegerToString(PartialPenetrationCounter)+" Full Penetration:"+IntegerToString(FullPenetrationCounter)))
                  Print("crap");
               AllPenetrationsCount=FullPenetrationCounter+PartialPenetrationCounter;

               //Define what to do to the SD level once the penetration count is complete
               //If the counter is between the firstpenetrationMax candles and secondPenetrationsMaxCandles
               if(AllPenetrationsCount>firstPenetrationsMaxCandles && AllPenetrationsCount<secondPenetrationsMaxCandles)
                 {
                  //Print(LevelPrefix+i+": "+price_1+"Price2:"+price_2+"time_1"+time_1+" EntryBar:"+EntryBar);
                 }
               //else if the penetrationcounter is greater then whoredOutMaxCandles and not the whoredOut Demand or Supply Level Colour
               if(AllPenetrationsCount>=whoredOutMaxCandles || FullPenetrationCounter >= maxPenetrationToExpireLevel)
                 {
                  //modify the level so that at the point of most penetrations the box stops pulling to the right.
                  if(LevelPrefix=="Supply_")
                    {
                     ModifySDLevels(0,"Supply_"+i,NULL,NULL,iTime(SymbolCheck,PeriodCheck,x),NULL,whoredOutSupplyLevelColour);
                     //break the for loop early to save processing power
                     x=1;
                    }
                  else
                     if(LevelPrefix=="Demand_")
                       {
                        ModifySDLevels(0,"Demand_"+i,NULL,NULL,iTime(SymbolCheck,PeriodCheck,x),NULL,whoredOutDemandLevelColour);
                        //break the for loop early to save processing power
                        x=1;
                       }
                 }

              }

           }

        }
      else
        {
         //Print("Error2: "+IntegerToString(GetLastError())+" "+StringConcatenate(LevelPrefix,IntegerToString(i)));
        }
      i++;
     }
  }
//+------------------------------------------------------------------+
//| Create rectangle by the given coordinates                        |
//+------------------------------------------------------------------+
bool RectangleCreate(const long            chart_ID=0,        // chart's ID
                     const string          name="Rectangle",  // rectangle name
                     const int             sub_window=0,      // subwindow index
                     datetime              time_1=0,           // first point time
                     double                price_1=0,          // first point price
                     datetime              time_2=0,           // second point time
                     double                price_2=0,          // second point price
                     const color           clr=clrRed,        // rectangle color
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // style of rectangle lines
                     const int             width=1,           // width of rectangle lines
                     const bool            fill=true,// filling rectangle with color - this doesn't do anything in code...
                     const bool            back=false,// in the background
                     const bool            selection=false,// highlight to move
                     const bool            hidden=false,// hidden in the object list
                     const long            z_order=0) // priority for mouse click
  {
//--- set anchor points' coordinates if they are not set
//--- reset the error value
   ResetLastError();
//--- create a rectangle by the given coordinates
   if(ObjectFind(name)==-1)
     {
      // create object
      if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,time_1,price_1,time_2,price_2))
        {
         Print(__FUNCTION__,
               ": failed to create a rectangle! Error code = ",GetLastError());
         return(false);
        }
      //--- set rectangle color
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      //--- set the style of rectangle lines
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
      //--- set width of the rectangle lines
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
      //--- display in the foreground (false) or background (true)
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      //--- enable (true) or disable (false) the mode of highlighting the rectangle for moving
      //--- when creating a graphical object using ObjectCreate function, the object cannot be
      //--- highlighted and moved by default. Inside this method, selection parameter
      //--- is true by default making it possible to highlight and move the object
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      //--- hide (true) or display (false) graphical object name in the object list
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      //--- set the priority for receiving the event of a mouse click in the chart
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
      //--- successful execution
      return(true);
     }
   else
     {
      return(false);
     }
  }
//+------------------------------------------------------------------+
//| Check the values of rectangle's anchor points and set default    |
//| values for empty ones                                            |
//+------------------------------------------------------------------+
void ChangeRectangleEmptyPoints(datetime &time_1,double &price_1,
                                datetime &time_2,double &price_2)
  {
   datetime time1=iTime(Symbol(),0,1);
//--- if the first point's time is not set, it will be on the current bar
   if(!time_1)
      time_1=TimeCurrent();
//--- if the first point's price is not set, it will have Bid value
   if(!price_1)
      price_1=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- if the second point's time is not set, it is located 9 bars left from the second one
   if(!time_2)
     {
      //--- array for receiving the open time of the last 10 bars
      datetime temp[10];
      CopyTime(Symbol(),Period(),time1,10,temp);
      //--- set the second point 9 bars left from the first one
      time_2=temp[0];
     }
//--- if the second point's price is not set, move it 300 points lower than the first one
   if(!price_2)
      price_2=price_1-300*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
  }
//+------------------------------------------------------------------+
//| Delete the rectangle                                             |
//+------------------------------------------------------------------+
bool RectangleDelete(const long   chart_ID=0,       // chart's ID
                     const string name="Rectangle") // rectangle name
  {
//--- reset the error value
   ResetLastError();
//--- delete rectangle
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete rectangle! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create Array Down sign                                           |
//+------------------------------------------------------------------+
bool ArrowCreate(const ENUM_OBJECT       direction=OBJ_ARROW_DOWN,//Arrow direction
                 const long              chart_ID=0,           // chart's ID
                 const string            name="ArrowDown",     // sign name
                 const int               sub_window=0,         // subwindow index
                 datetime                time=0,               // anchor point time
                 double                  price=0,              // anchor point price
                 const ENUM_ARROW_ANCHOR anchor=ANCHOR_BOTTOM, // anchor type
                 const color             clr=clrRed,           // sign color
                 const ENUM_LINE_STYLE   style=STYLE_SOLID,    // border line style
                 const int               width=3,              // sign size
                 const bool              back=false,           // in the background
                 const bool              selection=false,       // highlight to move
                 const bool              hidden=true,          // hidden in the object list
                 const long              z_order=0)            // priority for mouse click
  {
//--- set anchor point coordinates if they are not set
//ChangeArrowEmptyPoint(time,price);
//--- reset the error value
   ResetLastError();
//--- create the sign
   if(ObjectFind(name)==-1)
     {
      // create object
      if(!ObjectCreate(chart_ID,name,direction,sub_window,time,price))
        {
         Print(__FUNCTION__,
               ": failed to create \"Arrow Down\" sign! Error code = ",GetLastError());
         return(false);
        }
      //--- anchor type
      ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
      //--- set a sign color
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      //--- set the border line style
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
      //--- set the sign size
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
      //--- display in the foreground (false) or background (true)
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      //--- enable (true) or disable (false) the mode of moving the sign by mouse
      //--- when creating a graphical object using ObjectCreate function, the object cannot be
      //--- highlighted and moved by default. Inside this method, selection parameter
      //--- is true by default making it possible to highlight and move the object
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      //--- hide (true) or display (false) graphical object name in the object list
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      //--- set the priority for receiving the event of a mouse click in the chart
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
      //--- successful execution
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetPoint()
  {

   myPoint     =  MarketInfo(Symbol(),MODE_POINT);
   mySpread    =  MarketInfo(Symbol(),MODE_SPREAD);
   myDigits    =  MarketInfo(Symbol(),MODE_DIGITS);
   myStopLevel =  MarketInfo(Symbol(),MODE_STOPLEVEL);
   myTickValue = MarketInfo(Symbol(),MODE_TICKVALUE);
   myTickSize = MarketInfo(Symbol(),MODE_TICKSIZE);
   myLotValue = myTickValue/myTickSize;

   if(
      myDigits==3    ||
      myDigits==5
   )
     {
      myPoint     =  myPoint  *  10;
      mySpread    =  mySpread /  10;
      myStopLevel =  myStopLevel / 10;
      myDigits    =  myDigits -1;
     }

  }
//+------------------------------------------------------------------+
//+------------------Count Number of Open Orders---------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountOpenOrders(int direction)
  {
   int i,j;

   j=0;

   for(i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {
         if(OrderType()==direction &&
            OrderSymbol()        == Symbol()          &&
            OrderMagicNumber()   == magic_number
           )
            j++;
        }
      else
         Print("Could not SELECT trade");
     }

   return(j);
  }
//+------------------------------------------------------------------+
//+-------------------Close Trades by Symbol()-------------------------+
/*
int CloseTrades(int direction)
  {
   int j;
//double ClosePrice;

   j=0;
   int x;
   int status;

   if(direction==-1)
      return(0);

   for(int cnt=OrdersTotal()-1;cnt>=0;cnt--)
     {
      if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES)==True)
        {
         if(OrderSymbol()==Symbol() &&
            OrderMagicNumber()==magic_number)
            if(OrderType()==direction)
              {
               if(OrderType()==OP_BUY)
                 {
                  for(x=5; x!=0; x--)
                    {
                     while(IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                     status=OrderClose(OrderTicket(),OrderLots(),Bid,0);
                     printf("order auto closed");
                     if(status==1) { j++; break; }
                    }
                 }
               else
               if(OrderType()==OP_BUYLIMIT)
                 {
                  for(x=5; x!=0; x--)
                    {
                     while(IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                     status=OrderDelete(OrderTicket());
                     if(status==1) { j++; break; }
                    }
                 }
               else
               if(OrderType()==OP_BUYSTOP)
                 {
                  for(x=5; x!=0; x--)
                    {
                     while(IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                     status=OrderDelete(OrderTicket());
                     if(status==1) { j++; break; }
                    }
                 }

               if(OrderType()==OP_SELL)
                 {
                  for(x=5; x!=0; x--)
                    {
                     while(IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                     status=OrderClose(OrderTicket(),OrderLots(),Ask,0);
                     if(status==1) { j++; break; }
                    }
                 }
               else
               if(OrderType()==OP_SELLLIMIT)
                 {
                  for(x=5; x!=0; x--)
                    {
                     while(IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                     status=OrderDelete(OrderTicket());
                     if(status==1) { j++; break; }
                    }
                 }
               else
               if(OrderType()==OP_SELLSTOP)
                 {
                  for(x=5; x!=0; x--)
                    {
                     while(IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                     status=OrderDelete(OrderTicket());
                     if(status==1) { j++; break; }
                    }
                 }
              }
        }
     }

   return(j);
  }
  */
//+------------------------------------------------------------------+
//+----------------Modify Profit Target and Stop Loss----------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ModifyProfitTarget(int myTicket,double ProfitTarget,double StopLoss)
  {
   int try;
   string strerr="";

   /*
   logb("myTicket: ",myTicket);
   logb("ProfitTarget: ",ProfitTarget);
   logb("StopLoss: ",StopLoss);
   */


   if(OrderSelect(myTicket,SELECT_BY_TICKET,MODE_TRADES)==False)
      return(false);

//If either SL or TP not set then set as their original amounts
   if(ProfitTarget==NULL || ProfitTarget=="")
      ProfitTarget = OrderTakeProfit();
   if(StopLoss==NULL || StopLoss=="")
      StopLoss = OrderStopLoss();

   /*
   logb("OrderTicket(): ",OrderTicket());
   logb("OrderComment(): ",OrderComment());
   logb("ProfitTarget2: ",ProfitTarget);
   logb("StopLoss2: ",StopLoss);
   */

   if(ProfitTarget != OrderTakeProfit() || StopLoss != OrderClosePrice())
     {

      if(
         (
            MathRound(ProfitTarget/Point)!=MathRound(OrderTakeProfit()/Point)
            ||
            MathRound(StopLoss/Point)!=MathRound(OrderStopLoss()/Point)
         )
      )
        {
         //RefreshRates();
         for(try
                =1; try
                   <=5; try
                      ++)
                    {
                     if(OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(StopLoss,Digits),NormalizeDouble(ProfitTarget,Digits),OrderExpiration()))
                       {
                        //logb("-----Order successfully modified-----");
                        return(true);
                       }
                     else
                       {
                        err=GetLastError();
                        strerr=IntegerToString(err);
                        Print("OrderModify Error # "+strerr+" : ",ErrorDescription(err));
                       }
                    }
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   return(false);
  }
//+------------------------------------------------------------------+
//+----------------------OPEN TRADE----------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Open_Trade(string curr,int cmd,double price,double lot,double sl,double tp,string comm)
  {
   string strerr="";
   int ticket=0;
   int retry=0;
   color colour=CLR_NONE;

   sl=NormalizeDouble(sl,Digits);
   tp=NormalizeDouble(tp,Digits);
   price=NormalizeDouble(price,Digits);

   if(cmd==0)
      colour=Blue;
   if(cmd==1)
      colour=Red;

   if(Digits==3 || Digits==5)
     {
      for(retry=1; retry<=number_retry_open_trade; retry++)
        {
         RefreshRates();
         //if(ChartScreenShot(0,curr+" "+TimeGMT()+" "+Day()+" "+Year(),Screenshot_Width,Screenshot_Height,ALIGN_LEFT)) Print("We've saved the screenshot");
         ticket=OrderSend(curr,cmd,lot,price,slippage,0,0,comm,magic_number,0,colour);
         if(ticket>0)
            break;
         else
           {
            err=GetLastError();
            strerr=IntegerToString(err);
            Print("OrderSend Error # "+strerr+" : ",ErrorDescription(err));
           }
        }
     }
   else
     {
      for(retry=1; retry<=number_retry_open_trade; retry++)
        {
         RefreshRates();
         //if(ChartScreenShot(0,curr+" "+TimeGMT()+" "+Day()+" "+Year(),Screenshot_Width,Screenshot_Height,ALIGN_LEFT)) Print("We've saved the screenshot");
         ticket=OrderSend(curr,cmd,lot,price,slippage,sl,tp,comm,magic_number,0,colour);
         if(ticket>0)
            break;
         else
           {
            err=GetLastError();
            strerr=IntegerToString(err);
            Print("OrderSend Error # "+strerr+" : ",ErrorDescription(err));
           }
        }
     }

   if(ticket>0)
     {
      if(Digits==3 || Digits==5)
        {
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
            for(retry=1; retry<=number_retry_open_trade; retry++)
              {
               //logb("     tradeopened");
               if(ModifyProfitTarget(ticket,tp,sl))
                  break;
              }
        }
      TradeBarTime=Time[0];
      return(ticket);
     }
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawTL(string sName,double dPrice1,datetime dtTime1,double dPrice2,datetime dtTime2,color cLineClr=CLR_NONE,int style=STYLE_SOLID,int size=2)
  {
   string sObjName=sName;

   if(ObjectFind(sObjName)==-1)
     {
      // create object
      ObjectCreate(sObjName,OBJ_TREND,0,0,0,0,0);
     }

   ObjectSet(sObjName,OBJPROP_PRICE1,dPrice1);
   ObjectSet(sObjName,OBJPROP_TIME1,dtTime1);
   ObjectSet(sObjName,OBJPROP_PRICE2,dPrice2);
   ObjectSet(sObjName,OBJPROP_TIME2,dtTime2);
   ObjectSet(sObjName,OBJPROP_COLOR,cLineClr);
   ObjectSet(sObjName,OBJPROP_WIDTH,size);
   ObjectSet(sObjName,OBJPROP_STYLE,style);
   ObjectSet(sObjName,OBJPROP_RAY,false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLine(string sName,double dPrice,color cLineClr=CLR_NONE,int iWidth=1)
  {
   string sObjName=sName;

   if(ObjectFind(sObjName)==-1)
     {
      // create object
      ObjectCreate(sObjName,OBJ_HLINE,0,0,0);
     }

   ObjectSet(sObjName,OBJPROP_PRICE1,dPrice);
   ObjectSet(sObjName,OBJPROP_COLOR,cLineClr);
   ObjectSet(sObjName,OBJPROP_WIDTH,iWidth);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetHLineValue(string name)
  {

   if(ObjectFind(name)==-1)
      return(-1);
   else
      return(ObjectGet(name,OBJPROP_PRICE1));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetRectPrice(string name,ENUM_OBJECT_PROPERTY_DOUBLE type)
  {
   if(ObjectFind(name)==-1)
      return(-1);
   else
      return(ObjectGet(name,type));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetRectTime(string name,ENUM_OBJECT_PROPERTY_INTEGER type)
  {
   if(ObjectFind(name)==-1)
      return(-1);
   else
      return(ObjectGet(name,type));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string strtf(int tf)
  {
   switch(tf)
     {
      case PERIOD_M1:
         return("M1");
      case PERIOD_M5:
         return("M5");
      case PERIOD_M15:
         return("M15");
      case PERIOD_M30:
         return("M30");
      case PERIOD_H1:
         return("H1");
      case PERIOD_H4:
         return("H4");
      case PERIOD_D1:
         return("D1");
      case PERIOD_W1:
         return("W1");
      case PERIOD_MN1:
         return("MN1");
      default:
         return("Unknown timeframe");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TextCreate(const long              chart_ID=0,               // chart's ID
                const string            name="Text",              // object name
                const int               sub_window=0,             // subwindow index
                datetime                time=0,                   // anchor point time
                double                  price=0,                  // anchor point price
                const string            text="Text",              // the text itself
                const string            font="Arial",             // font
                const int               font_size=10,             // font size
                const color             clr=clrRed,               // color
                const double            angle=0.0,                // text slope
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                const bool              back=false,               // in the background
                const bool              selection=false,          // highlight to move
                const bool              hidden=true,              // hidden in the object list
                const long              z_order=0)                // priority for mouse click
  {
//--- set anchor point coordinates if they are not set
   ChangeTextEmptyPoint(time,price);
//--- reset the error value
   ResetLastError();
//--- create Text object
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": failed to create \"Text\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the object by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Move the anchor point                                            |
//+------------------------------------------------------------------+
bool TextMove(const long   chart_ID=0,  // chart's ID
              const string name="Text", // object name
              datetime     time=0,      // anchor point time coordinate
              double       price=0)     // anchor point price coordinate
  {
//--- if point position is not set, move it to the current bar having Bid price
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- move the anchor point
   if(!ObjectMove(chart_ID,name,0,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Change the object text                                           |
//+------------------------------------------------------------------+
bool TextChange(const long   chart_ID=0,  // chart's ID
                const string name="Text", // object name
                const string text="Text") // text
  {
//--- reset the error value
   ResetLastError();
//--- change object text
   if(!ObjectSetString(chart_ID,name,OBJPROP_TEXT,text))
     {
      Print(__FUNCTION__,
            ": failed to change the text! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Delete Text object                                               |
//+------------------------------------------------------------------+
bool TextDelete(const long   chart_ID=0,  // chart's ID
                const string name="Text") // object name
  {
//--- reset the error value
   ResetLastError();
//--- delete the object
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete \"Text\" object! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Check anchor point values and set default values                 |
//| for empty ones                                                   |
//+------------------------------------------------------------------+
void ChangeTextEmptyPoint(datetime &time,double &price)
  {
//--- if the point's time is not set, it will be on the current bar
   if(!time)
      time=TimeCurrent();
//--- if the point's price is not set, it will have Bid value
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Event identifier
                  const long& lparam,   // Event parameter of long type
                  const double& dparam, // Event parameter of double type
                  const string& sparam) // Event parameter of string type
  {

   datetime lvlStartTime;
   int barShift,currentVisibleBar;
   string LvlName;

//--- the mouse has been clicked on the graphic object
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      //Print("The mouse has been clicked on the object with name '"+sparam+"'");
      //if clicked then look for the term "Viewer" in the object.
      if(StringFind(sparam,"ZONE")!=-1)
        {
         //Get the level's object Name from the by stripping out 'Viewer_'
         //LvlName = StringSubstr(sparam,7,0);
         LvlName=sparam;
         if(ObjectFind(0,LvlName)!=-1)
           {
            //Get the first time of the level
            lvlStartTime = ObjectGet(LvlName,OBJPROP_TIME1);
            //Calculate how many bars the time is away from current bar.
            barShift = iBarShift(Symbol(),Period(),lvlStartTime,false);
            //Disable chartautoscroll
            ChartSetInteger(0,CHART_AUTOSCROLL,false);
            //Enable Chart Shift
            ChartSetInteger(0,CHART_SHIFT,true);
            //Find what is the first visible bar user is looking at.
            currentVisibleBar = ChartGetInteger(ChartID(),CHART_FIRST_VISIBLE_BAR);
            //Move chart to new location
            bool res=ChartNavigate(0,CHART_END,-barShift+50);
            if(!res)
               Print("Navigate failed. Error = ",GetLastError());
            ChartRedraw();
           }
        }
     }
  }

//+------------------------------------------------------------------+

/*
//+------------------------------------------------------------------+
void CaptureScreenshot(string filename)
  {
   if(ChartScreenShot(0,"something.gif",Screenshot_Width,Screenshot_Height,ALIGN_LEFT))
     {
      Print("We've saved the screenshot");
      logb("Screenshot pumped");
     }
   else
     {
      err=GetLastError();
      string strerr=IntegerToString(err);
      Print("ChartScreenshot Error # "+strerr+" : ",ErrorDescription(err));
      logb("ChartScreenshot Error # "+strerr+" : ",ErrorDescription(err));
     }
  }
//+------------------------------------------------------------------+
*/
