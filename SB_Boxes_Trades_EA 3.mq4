//+------------------------------------------------------------------+
//|                                           SB_Boxes_Trades_EA.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+



/* Instructions to load -
- Copy comment.mqh , common.mqh, json.mqh, Telegram.mqh to /includes directory
- Copy II_SupDemMOD_DarkBG_SolidFill_Sow.mql4 to /indicator directory
- Setup bot on Telegram by watching the video Telegram Setup Video.mp4
- Put the API key into this EA
- Goto Tool > Option > Exper Advisor in MT4 and ensure 'Allow automated trading' is ticked.
- Under 'Allow webrequest for listed URL' add in the following 'https://api.telegram.com' and 'https://api.telegram.org'

Instructions and notes -
- When you set this up for the first time on a single currency across multiple time frames then you need to ensure that each chart has its own Magic number.
You meed to manutally insert the magic number which is unique to that chart. Otherwise the EA's will clash with each other. One will delete the other's trades.
- Remember to draw out a red box and then change the description. The description is the number of lots you wish to trade.
- If you wish to trade 1 lot then edit the description and put in '1'. Alternatively if you wish to trade 1% then type '1%' of trade.
- When a trade closes the entry box will remain there to show you which trades it has taken so you can learn from your mistakes.

Updates required in order of priority -

TODO - Readjust the greenline to the greenbox
TODO - Support multiple greenbox orders
TODO - If Greenbox is removed then remove the Greenline too
TODO - If greenbox is removed then remove the M1 chart also
GOLIVE - If there is an existing order without box then the journal goes crazy trying to Delete something and captures tradedelete alot
GOLIVE - Exotic currencies / instruments are not working.
TODO - Set the state off the buttons off the globalvariables if set on the OnInit() fucntion

BUG - If second order is disabled then all orders go fucked up and do not work. Needs a deep review of why this happens. Some logic missing to ignore if second trade is live.
BUG - Stop creating a folder everytime we want to take screenshot
BUG - Need a new line for the SL of TP1 to be moveable once the trade has been entered
BUG - Fix all the console errors when compliling
BUG - If second trade is entered and SL1 and SL2 go to BE but then if I move the location of the SL lower then evertime price crosses the entry price of 2nd trade then it moves SL1 and SL2 to BE again.
FEATURE - Rewrite whole EA into MT5
FEATURE - The InfoBox should move a bit higher when selling so that its a bit easier to read.
FEATURE - Once price comes into the box and rebounds then detect a low. Put the SL1 and SL2 into the low of that price rather then directly to the BE point.
FEATURE - Show trade history. Once trade is closed then show a line connecting the start and end points.
FEATURE (NICE TO HAVE) - Record all new trades in a TEXT file and their history and show graphically on screen when adding the EA.
FEATURE - Draw a box over large candles to trade their liqiudity gaps. Create a series of orders inside that box when you know that there will be a significant drop from a previously fast moving candle.
FEATURE (NICE TO HAVE) - Consider using a pennant/flag indicator on HTF to find squeezes.
FEATURE - Restore our engulfing pattern detector and find out englufing patterns to exit from if they go against the trade.
FEATURE - Upon confluence between the three levels - supply on all three timeframes then a judgement system must be in place. Judgement system has the last call to make on if to allow this trade to continue.
BUG - Remove all the implicit conversion from number to string and possible loss of data due to type conversion.
 - Would be good to put in the InfoBox which was a winning trade and losing.
 - When a trade wins/loses sometimes the TP line remains as solid...
- If the box runs out then an alarm should go off.
- Prevent Margin Call...?
- Need to cater for spread as it makes a big impact on the trade.
 - Add in rules for how to handle TP to BE if second trade not enabled.
ALREADY DONE? - Investigate and codify best methods to manage trading risk.
 - If the trade disables second trade code the logic so that it puts the SL to BE halfway point.
GOLIVE - Should we allow the second trade stop loss to be adjustable for percentage of first trade's entry and stop loss (lines 802) ie. I want to enter my second trade stop loss as 50% between the first trades trade entry and stop loss.

 - If price is approaching the 'buffer zone' of the pending order then we must check the next high TF level and see how far away that is (use the supcount)
 - For example, if it is still 2:1 risk to reward ratio then its worth retaining the order
 - If not, we need to delete the order. Otherwise retain the order.
 - Retained order must readjust the TP price to closest SD level.
 - Make the trade have its own SL lines rather then disable the box. [Need good reasons for this.]
DONE - Green TP is not movable
DONE - You can turn the indicators off but you can't turn them back on.
DONE - Get the mobile notifications going
DONE - Send screenshots notifications to the mobile
DONE - Take screenshots of HTF - W,D,4H,1H everytime before taking a trade
DONE - Must improve the look of the levels - 1H levels to be long dashes with no fill
DONE - The text of 'H1' should show further away
CANCELLED - Need historical view of levels in indicator
DONE - Multi time frame SD levels - 1H,15M,1M
DONE - Add in 1M SD levels
CANCELLED - Consider using a pennant/flag indicator on HTF to find squeezes. (Need to find another way to implement this)
DONE - Once a second trade has gone to TP, the first one needs to move to break even. Right now its not.
DONE - Once trade is entered then need to take screenshot of the trade.
DONE - But a button to disable all the charts on the screen for better visibility.
CANCELLED - Support pure dollar size risk. ie. Risk $50 on a trade. - Not doing this as it will make it more around the money win and loss and in the long run this is bad for trading psychology especially when more money is on the line.
DONE - Need a floating text that reminds me of trading rules
DONE - Right now its taking a screenshot for every tick cycle which needs to be fixed.
DONE - If I have an order in and then readjust the entry sqaure then the TP does not readjust properly. Can't figure out which is the TP (Yellow or Green)
DONE - Once trade is entered then create a new folder and then take screenshots for entry, trade modificationd and close. Also change folder name once trade is closed.BUG
DONE - IF trade is entered and then the indicator crashes then there is no new box to replace it
DONE - Need screenshot upon trade being filled. Maybe ideally around trade entry.
DONE - Once trade filled both TP lines should NOT be Yellow! They should be different colour to make it easy to differentiate
DONE - Once trade is complete the box length should resize such that the end of the box should be where the trade ended otherwise there are alot of boxes on the screen after a day trade.
DONE - Moving the second trade entry line doesn't update the trade
ALREADY DONE? - Once trade is entered and then the box goes
DONE - Need to remove buttons and labels if removing the chart
DONE - Turning indicator back online doesn't bring it back on the charts.
DONE - If MT4 is closed then this EA will not take over existing orders because it will lose its Magic ID from setting into the global variable.
DONE - If you put a box in then inert the lots into the box THEN change the height of the box the yellow TP does not follow.
DONE - If you open more then one chart with this EA on it then it will remove your trade. Need to figure out how to prevent this from happening.
DONE - Need to setup a checker for all other EA's and their magic number. If another Magic number exsits that is the same then notice needs to be given.
DONE - If a box is changed around then the info box does not update.
CANT REPRODUCE - When Second order hits TP then original box goes blue. This is not right. [Tested in Strategy tester and it doesn't happen]
CANT REPRODUCE - When a second order is entered there are like three or four changes to the TP/SL which is weird. [Tested in Strategy tester and seems to work fine. Can't repo]
DONE - Buy orders are all fucked.
DONE - when doing market order, the calculation of TP2, SL2 are not correct.
DONE - When trading AUDUSD the second trade auto closes a few moments after but the first trade remains. When trading EUDUSD the second trade stay on and doesn't close upon opening. This was caused because there were two AUDUSD screens open and the magic number was shared between the two. Need to find a way that the magic number isn't shared between pairs.
DONE - When market order taken then the logs fill with errors. Not sure why.
DONE - If a order is entered at market execution then the box should take over and assign the TP and SL - Draw red box then if price is inside the red box then the TP should update. Create a button on the box to enter the trade.
DONE - When box is above the entry price and TP is also above the entry price it considers that a sell order still.
DONE - Infobox is now deleted upon trade entry
IGNORED - When market order is created and finished then the blue box draws backwards. Not sure why
    - I think this is if the time of the trade is not within the box dimensions.
DONE - When market order is taken but the trade is closed manually then the lines for the TP2 and the middle lines still remain.
DONE - Upon trade closure infobox should display the correct amount of TP/SL and RvR for chart history.
DONE - ASX200 - Even if I put 0.01 as the lot size it replaces that with 1 lot size order with no errors.
DONE - AXS200 doesn't work for trade management. Box goes huge.
DONE - Changing TF when current pending order is in place triggers the EA to create a rescue box

Two strategies -
- Trade on 3:1 RvR
- Trade on compression zones
- Trade grid style on liquaity gaps.
- Hunt for large candles with low volume behind them on their reversal



//Next feature -
//Click to view chart position -
//Use the "ObjectFind()" to get a specified named object and then use "ObjectGetTimeByValue()" to get its date/time.
//Get the Charts Symbol and Period with the functions "ChartSymbol()" and "ChartPeriod()".
//With the date and time (from step 1), find the bar shift with the "iBarShift()" function for the specified symbol and period obtained in the step 2.
//Disable the auto scrolling of the chart with the "ChartSetInteger()" function and the CHART_AUTOSCROLL property with a value of "0" equivalent to "false".
//Obtain the chart's current bar positioning, using the "ChartGetInteger()" function and the properties CHART_FIRST_VISIBLE_BAR and CHART_VISIBLE_BARS.
//Calculate the required bar positioning offset and then use the function "ChartNavigate()" to position the chart according to your requirements.



*/


#include <stdlib.mqh>
//#include <debug_inc.mqh>
//#include <Telegram.mqh>
//CCustomBot bot;

#property copyright "Copyright Sow Behl 2020"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//|                   Trade Rules                                    |
//+------------------------------------------------------------------+


string Rule1 = "- If not right, leave it. There will always be another trade.";
string Rule2 = "- You don't need to control the market. 50% win is good enough.";
string Rule3 = "- Don't marry one side of the trade.";
string Rule4 = "- If you miss a trade, dont worry. There will always be another.";
string Rule5 = "- Video each trade.";
string Rule6 = "- Trust the system in the long run.";
string Rule7 = "- Don't enter highly correlated trades. You can lose double.";
string Rule8 = "- Expenses are inevitable. Just make them manageable.";
//Cancel all 1M trades when London opens
//Leave sufficient room for spread in SL and TP
//Opening Asian session and closing are the highest trend setters.
//Between


extern bool    allowed_2nd_trade=true;
extern color   activate_colour=clrRed;
//extern int     magic_number=929161;  //taken this out so that its autogenerated
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
extern int     firstPenetrationsMaxCandles                    =5;          //The number of candles that penetrate a level before the level's 'freshness'.
extern int     secondPenetrationsMaxCandles                   = 10;        //The number of candles that penetrate a level before the level's 'freshness'.
extern int     thirdPenetrationsMaxCandles                    = 10;        //The number of candles that penetrate a level before the level's 'freshness'.
extern int     whoredOutMaxCandles                            = 10;        //The number of candles that penetrate a level before the level's 'freshness'.
extern int     maxPenetrationToExpireLevel                    = 3;         //The max number of full candle penetrations before level is expired.
extern int     magic_number                                   = 0;
extern string  logfile                                        ="trade.csv";

sinput string   t_tlg = "TELEGRAM";  // ================================
sinput string            InpToken="5253416211:AAHq3YF1wTfV0k2DC0TMTR9TeM23ShVRmY0";//Token
sinput ulong channeltlg =-727963640; //Telegram group code
sinput int differenceinsecondforsendphot=60;//
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double take_profit=0;                     //Fixed takeprofit in pips (0=no takeprofit)
double stop_loss=0;                       //Fixed stoploss in pips (0=no stoploss)

int timeframe=0;
int number_retry_open_trade=10;
//int magic_number;  /Disabling to test if magic_number can be removed so EA resumes trades upon closing

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
#define Screenshot_Width 1920
#define Screenshot_Height 1280

int err;
string strsuffix;
double ratio=1000000,CurrentSupDem,H1SupDem,M15SupDem,H4SupDem;

string magic_id;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   if(!FileIsExist(logfile))
     {
      WriteHeader();
     }

//bot.Token(InpToken);
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

//--- Put each magic number in the global variables so as not to clash with other EA's
// Disabling magic_number feature so EA can resume orders that have closed
// Unique sting id.
   magic_id = WindowExpertName() + Symbol();

// If there isn't already a Global Variable with the id in wich search for the MagicNumber create it
   if(!GlobalVariableCheck(magic_id) || GlobalVariableGet(magic_id)==0)
     {
      GlobalVariableSet(magic_id,magic_number);
     }
   else // Just get the MagicNumber for the unique id
     {
      Alert(Symbol()+": You have a clash with another EA with same EA number. Remove that please or change your EA number.");
     }

//--------


//----------- START - SET UP CHART FURNISHING -------------
   SetTemplate(ChartID());
//----------- END SET UP CHART FURNISHING -------------

//----------- START SET UP CHART BUTTONS -------------
//--- create the button
//--- chart window size
   long x_distance;
   long y_distance;
//--- set window size
   if(!ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance))
     {
      Print("Failed to get the chart width! Error code = ",ErrorDescription(GetLastError()));

     }
   if(!ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,y_distance))
     {
      Print("Failed to get the chart height! Error code = ",ErrorDescription(GetLastError()));

     }

   int x=(int)x_distance/32;
   int y=(int)y_distance/32;


   bool temp; //record temporary state of global varibles

   if(ObjectFind(0,"Button-ShowLevels")==-1)
     {
      //Create button if it doesn't exist. If button can't be created then set an error
      if(!ButtonCreate(0,"Button-ShowLevels",0,10,y+2,x+50,y+10,CORNER_LEFT_UPPER,"Indicators ON","Arial",10,
                       clrWhite,clrNONE,clrNONE,false,true,false,true,0))
        {
         Print("Error creating Button");
        }
      //set the button to be the state of the global variable so that if the TF changes then at least the buttons will be in the same state as it once was.
      if(GlobalVariableCheck(magic_id+"Button-ShowLevels")==true)
        {
         temp=GlobalVariableGet(magic_id+"Button-ShowLevels");
         ObjectSetInteger(0,"Button-ShowLevels",OBJPROP_STATE,temp);
        }
      //ObjectSetInteger(0,"Button-ShowLevels",OBJPROP_STATE,Button_ShowLevels_State);

     }

   if(ObjectFind(0,"Button-EnableRules")==-1)
     {
      if(!ButtonCreate(0,"Button-EnableRules",0,125,y+2,x+30,y+10,CORNER_LEFT_UPPER,"Rules ON","Arial",10,
                       clrWhite,clrNONE,clrNONE,false,true,false,true,0))
        {
         Print("Error creating Button");
        }
      if(GlobalVariableCheck(magic_id+"Button-EnableRules")==true)
        {
         temp=GlobalVariableGet(magic_id+"Button-EnableRules");
         ObjectSetInteger(0,"Button-EnableRules",OBJPROP_STATE,temp);
        }
     }

   if(ObjectFind(0,"Button-15M")==-1)
     {
      if(!ButtonCreate(0,"Button-15M",0,220,y+2,x-20,y+10,CORNER_LEFT_UPPER,"15M","Arial",10,
                       clrWhite,clrNONE,clrNONE,false,true,false,true,0))
        {
         Print("Error creating Button");
        }
      if(GlobalVariableCheck(magic_id+"Button-15M")==true)
        {
         temp=GlobalVariableGet(magic_id+"Button-15M");
         ObjectSetInteger(0,"Button-15M",OBJPROP_STATE,temp);
        }
     }

   if(ObjectFind(0,"Button-H1")==-1)
     {
      if(!ButtonCreate(0,"Button-H1",0,266,y+2,x-20,y+10,CORNER_LEFT_UPPER,"H1","Arial",10,
                       clrWhite,clrNONE,clrNONE,false,true,false,true,0))
        {
         Print("Error creating Button");
        }
      if(GlobalVariableCheck(magic_id+"Button-H1")==true)
        {
         temp=GlobalVariableGet(magic_id+"Button-H1");
         ObjectSetInteger(0,"Button-H1",OBJPROP_STATE,temp);
        }
     }

   if(ObjectFind(0,"Button-H4")==-1)
     {
      if(!ButtonCreate(0,"Button-H4",0,310,y+2,x-20,y+10,CORNER_LEFT_UPPER,"H4","Arial",10,
                       clrWhite,clrNONE,clrNONE,false,true,false,true,0))
        {
         Print("Error creating Button");
        }
      if(GlobalVariableCheck(magic_id+"Button-H4")==true)
        {
         temp=GlobalVariableGet(magic_id+"Button-H4");
         ObjectSetInteger(0,"Button-H4",OBJPROP_STATE,temp);
        }
     }

   if(ObjectFind(0,"Button-D1")==-1)
     {
      if(!ButtonCreate(0,"Button-D1",0,355,y+2,x-20,y+10,CORNER_LEFT_UPPER,"D1","Arial",10,
                       clrWhite,clrNONE,clrNONE,false,true,false,true,0))

        {
         Print("Error creating Button");
        }
      if(GlobalVariableCheck(magic_id+"Button-D1")==true)
        {
         temp=GlobalVariableGet(magic_id+"Button-D1");
         ObjectSetInteger(0,"Button-D1",OBJPROP_STATE,temp);
        }
     }
//----------- END SET UP CHART BUTTONS -------------

//--------------- SETUP RULES ----------------------
   DrawRulesOnScreen();
//--------------- SETUP RULES ---------------------

//----- If open orders found but without box then create them -------

   int i;
   for(i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {

         //Check the order belongs to this Symbol but also check that the trade has 'T01_' this also avoids the pyramid trade from having to enter a box for that.
         if(OrderSymbol()==Symbol() && StringLen(OrderComment()) == 0)
            //StringFind(OrderComment(),"T01_")!=-1)
           {
            printf("order found without box");
            string str1=StringSubstr(OrderComment(),0,StringFind(OrderComment(),"_"+TradeCode));  //If the tradecode is found from the ordercomment then extract it's name without the "_SB002" trade code.
            int replaced = StringReplace(str1,"T01_","");

            //If Object can't be found with the same name as the found order comment for T01_Rectange ... then create a new rectangle with red box and the same name.
            //Infobox should show up once the rectangle is drawn
            if(ObjectFind(str1)==-1) // && ObjectFind(OrderComment())=-1)  //StringFind(OrderComment(),"_"+TradeCode)!=-1
              {
               Alert(Symbol()+ ": Trade without a related box found. Adding one in.");
               if(RectangleCreate(0,str1,0,Time[10],OrderStopLoss(),Time[0]+5000,OrderOpenPrice(),activate_colour,0,1,true,true,true,false)>0)
                 {
                  Print("Can't make box for level - "+GetLastError());
                 }

              }
           }
        }
     }

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
                         STYLE_DOT,
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
                    STYLE_DOT,
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
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   string id = WindowExpertName() + Symbol();
   GlobalVariableDel(id);

   /*
   int i;
   for(i=0; i<ObjectsTotal(); i++)
     {
      string strname=ObjectName(i);
      if(StringFind(strname,"Button-")!=-1 || StringFind(strname,"TradeRules")!=-1)
        {
            ObjectDelete(0,strname);
            Print("Deleted "+strname);
        }
     }
     */
   TextDelete(0,"TradeRules1");
   TextDelete(0,"TradeRules2");
   TextDelete(0,"TradeRules3");
   TextDelete(0,"TradeRules4");
   TextDelete(0,"TradeRules5");
   TextDelete(0,"TradeRules6");
   TextDelete(0,"TradeRules7");
   ObjectDelete("Button-ShowLevels");
   ObjectDelete("Button-EnableRules");
   ObjectDelete("Button-15M");
   ObjectDelete("Button-H1");
   ObjectDelete("Button-H4");
   ObjectDelete("Button-D1");

  }


//+------------------------------------------------------------------+
//| Delete any extra 'greenBoxTPName' which doesn't have any related green boxes|
//+------------------------------------------------------------------+
void DeleteExcessGreenTPLines()
  {
   if(ObjectFind("greenBoxTPName") != -1)
     {
      int totalGreenBoxes = 0;

      // Loop through all objects on chart
      for(int i=0; i<ObjectsTotal(); i++)
        {
         string objName = ObjectName(i);
         // Check if object is a rectangle
         if(ObjectGetInteger(0,objName,OBJPROP_TYPE) == OBJ_RECTANGLE && ObjectGetInteger(0, objName, OBJPROP_COLOR) == clrGreen)
           {
            totalGreenBoxes++;
           }
        }
      // If no green boxes found, delete greenBoxTPName line
      if(totalGreenBoxes == 0 && ObjectFind("greenBoxTPName") != -1)
        {
         ObjectDelete("greenBoxTPName");
        }
     }
  }





//+------------------------------------------------------------------+
//| Checks to see if a trade already exists that has a certain comment  -
//| SB 22 Feb - Not sure if this is relevant anymore. Could be replaced by a built in function I'm pretty sure.
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
//| If any trades are currently open then check to see if there is any box for them otherwise delete the trade. Leave any active trade boxes.
//+------------------------------------------------------------------+
void CheckBoxes()
  {
   int i;
   int x;
   int status;

//Search through all open orders
   for(i=OrdersTotal()-1; i>=0; i--)
     {
      //For all orders that are open
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {
         //check to see if the order matches the current symbool, magic number and if the OrderType is not buy or sell but limit orders.
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number && OrderType()>1)
           {
            //Check the OrderComment to see if it was made by the EA by checking the trade code has '_SB00'. If so strip out the '_SB00' and leave just the rest of the OrderComment()
            string str1=StringSubstr(OrderComment(),0,StringFind(OrderComment(),"_"+TradeCode));

            //Removes the 'T02_' in front of the 'Rectangle XXXXX'
            string str2=StringSubstr(str1,StringFind(str1,"_")+1);

            //if you CANNOT find the order's comment with any related object name
            if((ObjectFind(str2)==-1) || ObjectFind(str2)!=-1)
              {
               //Extract the colour of the box - should this even trigger when there is no box that can be found? Redudant code?
               color objcolor = ObjectGet(str2,OBJPROP_COLOR);

               //If the colour of the box is not Red or GreenYellow then
               if(objcolor!=activate_colour && objcolor!=clrGreenYellow)
                 {

                  status=0;
                  //Take screenshot
                  CaptureScreenshot(OrderTicket(),"4_"+Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_Cancelled");

                  //If the box isn't found then delete the order
                  //Try 5 times to Delete the order
                  for(x = 5; x!= 0; x--)
                    {
                     //Not exactly sure what this does
                     while(IsTradeContextBusy() || !IsTradeAllowed())
                        Sleep(5000);
                     Print("OrderDeleting : "+OrderTicket());

                     //Delete the order as it is no longer required.
                     status=OrderDelete(OrderTicket());
                     if(status==1)
                       {
                        break;
                       }
                    }

                  //Delete all the TP lines since they are no longer needed
                  ObjectDelete("vvOP2_"+IntegerToString(OrderTicket()));
                  ObjectDelete("vOP2_"+IntegerToString(OrderTicket()));
                  ObjectDelete("vTP1_"+IntegerToString(OrderTicket()));
                  ObjectDelete("vTP2_"+IntegerToString(OrderTicket()));
                  ObjectDelete("vSL2_"+IntegerToString(OrderTicket()));
                  ObjectDelete("Link_"+IntegerToString(OrderTicket()));
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|Once a order has closed, the box should be updated and should be sized readjusted as well as any extra lines removed
//+------------------------------------------------------------------+
void FindClosedTrades()
  {
   int i;
   for(i=OrdersHistoryTotal()-1; i>=0; i--)
     {
      //Scan through full order history
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==True)
        {
         //Setup variables for each of the historial roders
         int orderticket=OrderTicket();
         int ordertype=OrderType();
         string ordersymbol=OrderSymbol();
         int ordermagic=OrderMagicNumber();
         string ordercomment=OrderComment();
         double orderlots=OrderLots();
         double profit = OrderProfit() + OrderCommission() + OrderSwap();

         //if order is closed and the same chart as this and has a magic number
         if(ordersymbol==Symbol() && ordermagic==magic_number && ordertype<=1)
           {
            //Look inside each order to find if the Order comment contains the TradeCode used to identify EA order
            int ind=StringFind(ordercomment,"_"+TradeCode);

            //Strip out the ordercomment to find the name of the object that triggered it
            string str1=StringSubstr(ordercomment,0,ind);
            string str2=StringSubstr(str1,StringFind(str1,"_")+1);

            //If closed trades has a box with the correct name but its not blue then start the close trade process which is to take a screenshot, set the color to blue and then change the dimension of the box so that it ends upon trade close to prevent clutter
            if(ObjectGet(str2,OBJPROP_COLOR)!=clrBlue &&  ObjectFind(str2)!=-1)
              {
               //If TP2 line is found and its not a dashdot then change the line to dashdot and set the line to stop at the order close time
               if(ObjectFind("vTP2_"+IntegerToString(orderticket))!=-1 && ObjectGet("vTP2_"+IntegerToString(orderticket),OBJPROP_STYLE)!=STYLE_DASHDOTDOT)
                 {
                  ObjectSet("vTP2_"+IntegerToString(orderticket),OBJPROP_WIDTH,1);
                  ObjectSet("vTP2_"+IntegerToString(orderticket),OBJPROP_STYLE,STYLE_DASHDOTDOT);
                  ObjectSet("vTP2_"+IntegerToString(orderticket),OBJPROP_TIME2,OrderCloseTime());
                  CaptureScreenshot(orderticket,"4_"+Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeClose_TP2"+"_"+str2);
                  //SendScreen(channeltlg,0,Symbol()+" Order Type " + IntegerToString(OrderType()) + " Price Close " + DoubleToString(OrderClosePrice(),Digits()) + " Volume " + DoubleToString(OrderLots(),Digits()),Symbol() + "_" + Period() + "_" + OrderMagicNumber());
                  if(allowed_2nd_trade)
                    {
                     DeletePending2(str2);
                    }
                  ObjectDelete("vvOP2_"+IntegerToString(orderticket));
                  ObjectDelete("vOP2_"+IntegerToString(orderticket));
                  //ObjectDelete("vTP2_"+IntegerToString(orderticket));  //Keep the TP2
                  ObjectDelete("vSL2_"+IntegerToString(orderticket));
                  //ObjectDelete("Link_"+IntegerToString(orderticket));  //Link line is nice and clean so we should keep it.
                 }

               if(ObjectGet("vTP1_"+IntegerToString(orderticket),OBJPROP_STYLE)!=STYLE_DASHDOTDOT &&  ObjectFind("vTP1_"+IntegerToString(orderticket))!=-1)
                 {

                  ObjectSet("vTP1_"+IntegerToString(orderticket),OBJPROP_WIDTH,1);
                  ObjectSet("vTP1_"+IntegerToString(orderticket),OBJPROP_STYLE,STYLE_DASHDOTDOT);
                  ObjectSet("vTP1_"+IntegerToString(orderticket),OBJPROP_TIME2,OrderCloseTime());
                  CaptureScreenshot(orderticket,"4_"+Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeClose_TP1"+"_"+str2);
                  //SendScreen(channeltlg,0,"Order Type " + IntegerToString(OrderType()) + " Price Close " + DoubleToString(OrderClosePrice(),Digits()) + " Volume " + DoubleToString(OrderLots(),Digits()),Symbol() + "_" + Period() + "_" + OrderMagicNumber());
                  ObjectSet(str2,OBJPROP_COLOR,clrBlue);
                  ObjectSet(str2,OBJPROP_TIME2,OrderCloseTime());

                  if(allowed_2nd_trade)
                    {
                     ObjectDelete("vvOP2_"+IntegerToString(orderticket));
                     ObjectDelete("vOP2_"+IntegerToString(orderticket));
                     ObjectDelete("vSL2_"+IntegerToString(orderticket));
                    }

                  ObjectDelete("InfoBox_"+str2);

                  // This part of the infobox handles the changes once the trade has been entered. By this time the box should have already been created.
                  //------------ Update the infobox with changes on every tick -----------------
                  double tpprice=OrderTakeProfit();
                  double tp_in_pips,stop_in_pips,RvR,entry,sl;
                  string infobox;

                  //Check if TP line is above the box to check if this is a buy order
                  if(OrderType()==OP_BUY || OrderType()==OP_BUYLIMIT)
                    {
                     entry=ObjectGet(str2,OBJPROP_PRICE1);
                     sl=ObjectGet(str2,OBJPROP_PRICE2);
                     //Calculcate the various TP,Stop and RvR
                     tp_in_pips=NormalizeDouble((tpprice-entry)/myPoint,Digits);
                     stop_in_pips=NormalizeDouble((entry-sl)/myPoint,Digits);
                     RvR=tp_in_pips/stop_in_pips;
                    }
                  else
                    {
                     entry=ObjectGet(str2,OBJPROP_PRICE2);
                     sl=ObjectGet(str2,OBJPROP_PRICE1);
                     //Check if TP line is below the box to check if this is a sell order
                     tp_in_pips=NormalizeDouble((entry-tpprice)/myPoint,Digits);
                     stop_in_pips=NormalizeDouble((sl-entry)/myPoint,Digits);
                     RvR=tp_in_pips/stop_in_pips;

                    }

                  //Generate the infobox
                  infobox="CLOSED SL: "+DoubleToStr(NormalizeDouble(stop_in_pips,2),1)+" | TP: "+DoubleToStr(tp_in_pips,1)+" | RvR: "+DoubleToStr(RvR,1);
                  //Send order to infobox
                  TextCreate(0,"InfoBoxClosed_"+str2,0,ObjectGet(str2,OBJPROP_TIME1),MathMax(entry,sl),infobox,"Ariel",9,clrYellow,0.0,ANCHOR_LEFT_UPPER);
                  //   string Header = "OrderId,DateTime,OrderType,Symbol,Lots,TpInPips,SlInPips,Rvr,Trade Outcome,Current Account,Comments,Trade OutComments";

                  string resulttocsv=IntegerToString(orderticket) + "," + TimeToString(OrderOpenTime()) + "," + IntegerToString(ordertype) + "," + Symbol() + "," + DoubleToString(orderlots,2) + "," +
                                     DoubleToString(tp_in_pips,Digits()) + "," + DoubleToString(stop_in_pips,Digits()) + "," + DoubleToString(RvR,2) + "," +
                                     DoubleToString((profit>0)?NormalizeDouble(MathAbs(OrderClosePrice()-OrderOpenPrice())/myPoint,Digits):NormalizeDouble(-MathAbs(OrderClosePrice()-OrderOpenPrice()),Digits())/myPoint,Digits)+ "," + DoubleToString(AccountBalance(),Digits());
                  WriteFile(logfile,resulttocsv);


                  // ------------------------------------------------------------
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|  If box no longer exists on the screen then the trade order should also be deleted since it is no longer valid.
//+------------------------------------------------------------------+
// Function to delete trades after box breakout
void DeleteTradeAfterBox()
  {
// Loop variables
   int i;
   int x;
   int status;

// Loop through all trades
   for(i=OrdersTotal()-1; i>=0; i--)
     {
      // Select trade by position
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {
         // Check if trade matches symbol and magic number
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number)
           {
            // Parse trade comment to get trade code
            string str1=StringSubstr(OrderComment(),0,StringFind(OrderComment(),"_"+TradeCode));
            string str2=StringSubstr(str1,StringFind(str1,"_")+1);

            // Convert trade code strings to datetimes
            datetime time1=StrToInteger(DoubleToString(GetRectTime(str2,OBJPROP_TIME1)));
            datetime time2=StrToInteger(DoubleToString(GetRectTime(str2,OBJPROP_TIME2)));
            datetime timex=MathMax(time1,time2);

            // Check if current time past trade expiry
            if(TimeCurrent()>=timex+(Period()*60))
              {
               // Status variable
               status=0;

               // Take screenshot for record
               CaptureScreenshot(OrderTicket(),Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeDelete");

               // Try to delete order up to 5 times
               for(x = 5; x!= 0; x--)
                 {
                  // Check if trade context is busy
                  while(IsTradeContextBusy() || !IsTradeAllowed())
                     Sleep(5000);

                  // Try to delete order
                  status=OrderDelete(OrderTicket());

                  // Break loop if successful
                  if(status==1)
                    {
                     break;
                    }
                 }

               // Delete trade objects
               ObjectDelete("vvOP2_"+IntegerToString(OrderTicket()));
               ObjectDelete("vOP2_"+IntegerToString(OrderTicket()));
               ObjectDelete("vTP2_"+IntegerToString(OrderTicket()));
               ObjectDelete("vSL2_"+IntegerToString(OrderTicket()));

               // Leave some objects for reference
               ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_WIDTH,1);
               ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_STYLE,STYLE_DASH);

               // Change trade code object color
               ObjectSet(str2,OBJPROP_COLOR,clrMaroon);

              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Check to see if the TP lines have moved. If so then update the order to match the location of the TP lines.
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
               ModifyProfitTarget(OrderTicket(),tpprice,OrderStopLoss());
              }
            double tpprice2=NormalizeDouble(ObjectGet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1),Digits);
            if(tpprice2!=OrderTakeProfit() && StringFind(OrderComment(),"T02_")!=-1)
              {
               ModifyProfitTarget(OrderTicket(),tpprice2,OrderStopLoss());
              }
            double entry2=NormalizeDouble(ObjectGet("vOP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1),Digits);
            if(entry2!=OrderOpenPrice() && StringFind(OrderComment(),"T02_")!=-1)
              {
               ModifyProfitTarget(OrderTicket(),NULL,NULL,entry2);
              }

            double slprice2=NormalizeDouble(ObjectGet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1),Digits);
            if(slprice2!=OrderStopLoss() && StringFind(OrderComment(),"T02_")!=-1)
              {
               ModifyProfitTarget(OrderTicket(),OrderTakeProfit(),slprice2);
              }

           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Check if box has moved, if so, update the order to reflect the new location of the box.
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

            //Search if box exists and if its the right red colour which indicates it is active
            if(StringFind(OrderComment(),"T01_")!=-1 && boxColor==activate_colour)
              {

               //Check if the current order is a buy limit. Also ensure that the price is above the top of the box.
               if(OrderType()==OP_BUYLIMIT && Bid>upperline)
                 {

                  //Check to see if the limit order is the same as the dimensions of the box.
                  if(OrderOpenPrice()!=upperline || OrderStopLoss()!=lowerline)
                    {

                     //if the box is not the same as the order then update the order to the box's location
                     ret=OrderModify(OrderTicket(),NormalizeDouble(upperline,Digits),NormalizeDouble(lowerline,Digits),OrderTakeProfit(),OrderExpiration());

                     //Once the order has been updated then all the lines need to be updated also to reflect the new price
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
                        TextMove(0,"InfoBox_"+str2,MathMin(time1,time2),lowerline);
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,upperline+2*(upperline-lowerline));
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,upperline+2*(upperline-lowerline));
                        ObjectSet("Link_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,upperline);
                        ObjectSet("Link_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,ObjectGet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1));
                        ObjectSet("Link_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("Link_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMin(time1,time2));
                        if(allowed_2nd_trade)
                          {
                           ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                           ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,(MathMax(time1,time2)-MathMin(time1,time2))/2+MathMin(time1,time2));
                           ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,(MathMax(time1,time2)-MathMin(time1,time2))/2+MathMin(time1,time2));
                           ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                          }
                        else
                          {
                           ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                           ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                           ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                           ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                          }
                       }

                     //Take screenshot of the Trade entry
                     CaptureScreenshot(OrderTicket(),"1.6_" + GetPeriodName(PERIOD_CURRENT) + "_"  +Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     long idchart=0;
                     // Screnshot M15 trade
                     idchart = OpenNewChart(PERIOD_M15);
                     SetTemplate(idchart);
                     CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.5_" + GetPeriodName(PERIOD_M15) + "_"    +Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     CloseChart(idchart);
                     // Screnshot H1 trade
                     idchart = OpenNewChart(PERIOD_H1);
                     SetTemplate(idchart);
                     CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.4_" + GetPeriodName(PERIOD_H1) +  "_"  +TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     CloseChart(idchart);
                     // Screnshot H4 trade
                     idchart = OpenNewChart(PERIOD_H4);
                     SetTemplate(idchart);
                     CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.3_" + GetPeriodName(PERIOD_H4) +  "_" + Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     CloseChart(idchart);
                     // Screnshot D1 trade
                     idchart = OpenNewChart(PERIOD_D1);
                     SetTemplate(idchart);
                     CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.2_" + GetPeriodName(PERIOD_D1) +  "_" + Symbol()+ "_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     CloseChart(idchart);
                     // Screnshot W1 trade
                     idchart = OpenNewChart(PERIOD_W1);
                     SetTemplate(idchart);
                     CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.1_" + GetPeriodName(PERIOD_W1) +  "_" + Symbol()+ "_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     CloseChart(idchart);


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
                           ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,lowerline-2*(upperline-lowerline));
                           ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,lowerline-2*(upperline-lowerline));
                           ObjectSet("Link_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,lowerline);
                           ObjectSet("Link_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,ObjectGet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1));
                           ObjectSet("Link_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                           ObjectSet("Link_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMin(time1,time2));
                           if(allowed_2nd_trade)
                             {
                              ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                              ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,(MathMax(time1,time2)-MathMin(time1,time2))/2+MathMin(time1,time2));
                              ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,(MathMax(time1,time2)-MathMin(time1,time2))/2+MathMin(time1,time2));
                              ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                             }
                           else
                             {
                              ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                              ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                              ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                              ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                             }
                          }
                        //Take screenshot of the Trade entry
                        CaptureScreenshot(OrderTicket(),"1.6_" + GetPeriodName(PERIOD_CURRENT) + "_"  +Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                        long idchart=0;
                        // Screnshot M15 trade
                        idchart = OpenNewChart(PERIOD_M15);
                        SetTemplate(idchart);
                        CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.5_" + GetPeriodName(PERIOD_M15) + "_"    +Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                        CloseChart(idchart);
                        // Screnshot H1 trade
                        idchart = OpenNewChart(PERIOD_H1);
                        SetTemplate(idchart);
                        CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.4_" + GetPeriodName(PERIOD_H1) +  "_"  +TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                        CloseChart(idchart);
                        // Screnshot H4 trade
                        idchart = OpenNewChart(PERIOD_H4);
                        SetTemplate(idchart);
                        CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.3_" + GetPeriodName(PERIOD_H4) +  "_" + Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                        CloseChart(idchart);
                        // Screnshot D1 trade
                        idchart = OpenNewChart(PERIOD_D1);
                        SetTemplate(idchart);
                        CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.2_" + GetPeriodName(PERIOD_D1) +  "_" + Symbol()+ "_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                        CloseChart(idchart);
                        // Screnshot W1 trade
                        idchart = OpenNewChart(PERIOD_W1);
                        SetTemplate(idchart);
                        CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.1_" + GetPeriodName(PERIOD_W1) +  "_" + Symbol()+ "_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                        CloseChart(idchart);
                       }
                    }

              }

            //--------- Re-adjust the link line if the TP lines have moved ----------------
            if(ObjectGet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1) != ObjectGet("Link_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2))
              {
               ObjectSet("Link_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,ObjectGet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1));
              }
            //-----------------------------------------------------------------------------


            //Ok so even though this function is meant to be for Box moved here is the Stop loss to break even code for the second trade
            if(allowed_2nd_trade)
              {

               //Create variable to track order comment
               string Ordercomment = OrderComment();

               //See if this is order is a second trade
               if(StringFind(Ordercomment,"T02_") != -1)
                 {

                  //Initiate variables as required for second trade.
                  int    Orderticket = OrderTicket();
                  double Ordertakeprofit = OrderTakeProfit();
                  double Orderclose = OrderClosePrice();
                  double Orderopenprice = OrderOpenPrice();
                  double Orderstoploss = OrderStopLoss();

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
                           ModifyProfitTarget(FirstTradeID,NULL,upperline);
                           CaptureScreenshot(FirstTradeID,"2_"+Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_Move1stTradeToBE");
                           //SendScreen(channeltlg,0,Symbol()+"| Type " + IntegerToString(OrderType()) + "| Breakeven At " + DoubleToString(upperline,Digits()) + "| Volume " + DoubleToString(OrderLots(),Digits()),Symbol() + "_" + Period() + "_" + OrderMagicNumber());
                           FirstSL = FirstOpenPrice;
                          }

                        double slprice2=NormalizeDouble(ObjectGet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE1),Digits);

                        //Change the second trade SL to the top of the rectangle
                        if(Bid>=SecondTradeBreakevenPrice && slprice2 != upperline)
                          {

                           //Move the SL line so the TPLinesMoved() doesn't override this
                           ObjectSet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE1,upperline);
                           ObjectSet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE2,upperline);

                           CaptureScreenshot(FirstTradeID,"3_"+Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_Move2ndTradeToBE");
                           //SendScreen(channeltlg,0,Symbol()+"| Type " + IntegerToString(OrderType()) + "| Breakeven At " + DoubleToString(upperline,Digits()) + "| Volume " + DoubleToString(OrderLots(),Digits()),Symbol() + "_" + Period() + "_" + OrderMagicNumber());


                           if(slprice2 != Orderstoploss)
                             {
                              ModifyProfitTarget(Orderticket,NULL,upperline);
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
                           ModifyProfitTarget(FirstTradeID,NULL,lowerline); //This might have a bug in it. Need to look at original order first
                           CaptureScreenshot(FirstTradeID,"2_"+Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_Move1stTradeToBE");
                           //SendScreen(channeltlg,0,Symbol()+ "| Type " + IntegerToString(OrderType()) + "| Breakeven At " + DoubleToString(lowerline,Digits()) + "| Volume " + DoubleToString(OrderLots(),Digits()),Symbol() + "_" + Period() + "_" + OrderMagicNumber());
                           FirstSL = FirstOpenPrice;
                          }



                        double slprice2=NormalizeDouble(ObjectGet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE1),Digits);

                        //Change the second trade SL to the top of the rectangle
                        if(Ask<=SecondTradeBreakevenPrice && slprice2 != lowerline)
                          {

                           //Move the SL line so the TPLinesMoved() doesn't override this
                           ObjectSet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE1,lowerline);
                           ObjectSet("vSL2_"+IntegerToString(Orderticket),OBJPROP_PRICE2,lowerline);

                           CaptureScreenshot(FirstTradeID,"3_"+Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_Move2ndTradeToBE");
                           //SendScreen(channeltlg,0,Symbol()+"| Type " + IntegerToString(OrderType()) + "| Breakeven At " + DoubleToString(lowerline,Digits()) + "| Volume " + DoubleToString(OrderLots(),Digits()),Symbol() + "_" + Period() + "_" + OrderMagicNumber());

                           if(slprice2 != Orderstoploss)
                             {
                              ModifyProfitTarget(Orderticket,NULL,lowerline);
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


            // This part of the infobox handles the changes once the trade has been entered. By this time the box should have already been created.
            //------------ Update the infobox with changes on every tick -----------------
            double tpprice=NormalizeDouble(ObjectGet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1),Digits);
            double tp_in_pips,stop_in_pips,RvR;
            string infobox;

            //Check if TP line is above the box to check if this is a buy order
            if(tpprice!= NULL && tpprice > upperline)
              {

               //Calculcate the various TP,Stop and RvR
               tp_in_pips=NormalizeDouble((tpprice-upperline)/myPoint,Digits);
               stop_in_pips=NormalizeDouble((upperline-lowerline)/myPoint,Digits);
               RvR=tp_in_pips/stop_in_pips;
              }
            else

               //Check if TP line is below the box to check if this is a sell order
               if(tpprice!= NULL && tpprice < lowerline)
                 {
                  tp_in_pips=NormalizeDouble((lowerline-tpprice)/myPoint,Digits);
                  stop_in_pips=NormalizeDouble((upperline-lowerline)/myPoint,Digits);
                  RvR=tp_in_pips/stop_in_pips;
                 }

            //Generate the infobox
            infobox="SL: "+DoubleToStr(NormalizeDouble(stop_in_pips,2),1)+" | TP: "+DoubleToStr(tp_in_pips,1)+" | RvR: "+DoubleToStr(RvR,1);

            //Send order to infobox
            TextChange(0,"InfoBox_"+str2,infobox);
            // ------------------------------------------------------------

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
                  Print("SecondTrigger");
                  int openticket=Open_Trade(Symbol(),cmd,price,orderlots,sl,tp,"T02_"+strname+"_"+TradeCode);
                  //what is this below?
                  if(openticket>0)
                    {
                     ObjectDelete("vvOP2_"+IntegerToString(orderticket));
                     ObjectDelete("vOP2_"+IntegerToString(orderticket));
                     //ObjectDelete("vTP1_"+IntegerToString(orderticket)); //Don't delete this from here otherwise the SL TL lines wont work.
                     ObjectDelete("vTP2_"+IntegerToString(orderticket));
                     ObjectDelete("vSL2_"+IntegerToString(orderticket));
                     DrawTL("vOP2_"+IntegerToString(openticket),price,backline,price,frontline,clrGreen,STYLE_SOLID,1);
                     DrawTL("vSL2_"+IntegerToString(openticket),sl,backline,sl,frontline,clrGray,STYLE_SOLID,1);
                     DrawTL("vTP2_"+IntegerToString(openticket),tp,backline,tp,frontline,clrBrown,STYLE_SOLID,2);

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
//|   Deletes 2nd trade pending order (i think)                                 |
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
               //Take screenshot
               CaptureScreenshot(OrderTicket(),"5_"+Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_DeletePending");
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
                     ObjectDelete("Link_"+IntegerToString(OrderTicket()));
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
//|//Catch new trade and send photo to telegram                      |
//+------------------------------------------------------------------+
void NewTrade()
  {
   static int TotalOrder;
   int OpenOrder=GetOpenOrder(magic_number,Symbol());
   if(TotalOrder !=OpenOrder)
     {
      CheckOrderForSendTrade(magic_number,Symbol(),differenceinsecondforsendphot);
      TotalOrder = OpenOrder;
     }

  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(!IsTesting())
      NewTrade();
   int i;
   double sl=0;
   double tp=0;
   double tp2=0;
   int openticket1=0;
   int openticket2=0;
   double entryprice1=0;
   double entryprice2=0;
   double stoploss2=0;
   double stop_in_pips=0;
   double tp_in_pips;
   double RvR;

   bool enableopen=true;

   string strname;
   string strlots;
   string infobox;
   double upperline;
   double lowerline;
   datetime backline;
   datetime frontline;
   datetime middleofbox;

   CheckBoxes();  //Delete limit trades if Box is deleted or change its colour
   FindClosedTrades(); //Change closed trades box to blue and tp line to dashes
   DeleteTradeAfterBox(); //Delete Limit trades that is outside box
   TPLinesMoved();   //Check if TP line is moved
   BoxMoved();       //Check if Box is moved
   SetPending2();  //Set second order trade
   ManageButtons(); //Manage the buttons for showing indicator
   DeleteExcessGreenTPLines(); //delete the extra lines for showing the indicator

//--- Bullish and Bearish engulfing pattern find

//CandleFinder=CandleIdentifier(Symbol(),PERIOD_M15,1,2,3,clrBlue,STYLE_SOLID,NULL,arrayOut);
   /*
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
               //Get the number of lots from the description
               strlots=ObjectDescription(strname);

               //Find the box and extract the location. Top of the box is price1 and bottom of the box is price2
               double price1=GetRectPrice(strname,OBJPROP_PRICE1);
               double price2=GetRectPrice(strname,OBJPROP_PRICE2);

               //Find the box and the left side of the box is determined as time1 and the right side of the box is time2
               datetime time1=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME1)));
               datetime time2=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME2)));

               //Determine the upper and lower line of the box by understandig which is the Min or max value
               upperline=MathMax(price1,price2);
               lowerline=MathMin(price1,price2);

               //Determine which is the time of the right of the box, middle of the box and the left of the box
               frontline=MathMax(time1,time2);
               middleofbox = (time2 - time1)/2+time1;
               backline=MathMin(time1,time2);


               //Initiate the variables used for calculation.
               //double draft_vTP1_price=0;

               string InfoBoxOrderPrefix;
               bool OKToTrade = true;

               int cmd=-1;

               //----- THIS WHOLE SECTION OUTLINES WHAT HAPPENS PRIOR TO TRADE ENTRY -------
               //Calculate the initial placement of all the lines based on the box
               //---if box is above the bid line then all orders should be a buylimit order. Setup the box such that the bottom of the box is the sl
               if(Bid>upperline)
                 {
                  cmd=OP_BUYLIMIT;
                  entryprice1=upperline;
                  sl=lowerline;
                  stop_in_pips=(entryprice1-sl)/myPoint;
                  tp=entryprice1+2*(entryprice1-sl);

                 }
               else
                  //--if box is below the bid line then all orders should be a sell limit order. Setup the box such that the top of the box is the sl
                  if(Bid<lowerline)
                    {
                     cmd=OP_SELLLIMIT;
                     entryprice1=lowerline;
                     sl=upperline;
                     stop_in_pips=(sl-entryprice1)/myPoint;
                     tp=entryprice1-2*(sl-entryprice1);

                    }

                  else
                     //if current price is between the box upperline and lowerline then that is a market order. Setup box such that its a sell market order initially and the user can change the TP as needed into a buy market order
                     if(Bid>lowerline && Bid<upperline)
                       {

                        entryprice1=Ask;
                        sl=upperline;
                        //calculate the SL in Pips for the Infobox and 2nd trade
                        stop_in_pips=(sl-entryprice1)/myPoint;
                        tp=entryprice1-2*(sl-entryprice1);

                       }



               //Provided trade has not been entered yet and the time for the box is still valid
               if(isAlreadyEnter("_"+strname+"_")==false && TimeCurrent()<=frontline /*&& cmd != NULL*/)
                 {
                  //Once the initial requirements have been set from above, check if a TP1 line exists and that a order doesn't already executed. If so, create a new dashed TP1 line which is used for measurement prior to trade entry and a Infobox text.
                  if(ObjectFind("vTP1_"+strname)==-1)
                    {

                     //requires tp to be set from above.
                     DrawTL("vTP1_"+strname,tp,backline,tp,frontline,clrYellow,STYLE_DASH,1);

                     //check if TP for bluebox exists, replace
                     if(ObjectFind("greenBoxTPName") != -1)
                       {
                        // Get V_Rectangle price
                        double vRectPrice = ObjectGet("greenBoxTPName",OBJPROP_PRICE1);
                        ObjectSet("vTP1_"+strname,OBJPROP_PRICE1,vRectPrice);
                        ObjectSet("vTP1_"+strname,OBJPROP_PRICE2,vRectPrice);

                        // Delete V_Rectangle
                        ObjectDelete("blueBoxTPName");
                       }
                     //create a Infobox to be used to display the RvR and TP and SL amount.
                     TextCreate(0,"InfoBox_"+strname,0,time1,sl,infobox,"Ariel",9,clrYellow,0.0,ANCHOR_LEFT_UPPER);

                    }

                  //Find the TP line price point and initiate that as tp
                  tp=ObjectGet("vTP1_"+strname,OBJPROP_PRICE1);

                  //calculate the tp_in_pips if the TP1 line is above the top of the box
                  if(tp>upperline && Bid>upperline)
                    {
                     tp_in_pips=NormalizeDouble((tp-entryprice1)/myPoint,Digits);
                     InfoBoxOrderPrefix = "BUY LIMIT";
                    }
                  else
                     // if the TP is in the wrong location (ie. below the box) then show error
                     if(tp<upperline && Bid>upperline)
                       {
                        InfoBoxOrderPrefix = "ERROR";
                        OKToTrade = false;
                       }

                  //calculate the tp_in_pips if the TP1 line below the box low.
                  if(tp<lowerline && Bid<lowerline)
                    {
                     tp_in_pips=NormalizeDouble((entryprice1-tp)/myPoint,Digits);
                     InfoBoxOrderPrefix = "SELL LIMIT";
                    }
                  else
                     if(tp>lowerline && Bid<lowerline)
                       {
                        InfoBoxOrderPrefix = "ERROR";
                        OKToTrade = false;
                       }

                  //When we want to place a market order then the box should be placed over the current bid/ask lines and it will calculate
                  if(Bid>lowerline && Bid<upperline)
                    {
                     if(tp>Bid)
                       {
                        tp=ObjectGet("vTP1_"+strname,OBJPROP_PRICE1);
                        tp_in_pips=NormalizeDouble((tp-Bid)/myPoint,Digits);
                        sl=lowerline;
                        InfoBoxOrderPrefix = "BUY MARKET";
                        cmd=OP_BUY;
                       }
                     else
                       {
                        tp=ObjectGet("vTP1_"+strname,OBJPROP_PRICE1);
                        tp_in_pips=NormalizeDouble((Bid-tp)/myPoint,Digits);  //should I replace with ask here?
                        sl=upperline;
                        InfoBoxOrderPrefix = "SELL MARKET";
                        cmd=OP_SELL;
                       }
                    }
                  //Calculate the RvR based off the above
                  RvR=tp_in_pips/stop_in_pips;

                  //calculate the risk of the trade entry. First check if the risk is either in whole lots or in percentage.
                  //if the risk in the description doesn not have a '%' then do the following
                  if(StringFind(strlots,"%")!=-1)
                    {
                     double percent=StrToDouble(StringSubstr(strlots,0,StringFind(strlots,"%")));
                     double my_lots2;
                     if(Digits==3 || Digits==5)
                        my_lots2=(AccountBalance()*percent*0.01)/(stop_in_pips*myTickValue*10);
                     else
                        my_lots2=(AccountBalance()*percent*0.01)/(stop_in_pips*myTickValue);
                     my_lots=NormalizeDouble(my_lots2,digit_lot);
                    }
                  else
                     if(StringFind(strlots,"%")==-1)
                        my_lots=StrToDouble(strlots);
                  if(my_lots<MarketInfo(Symbol(),MODE_MINLOT))
                     my_lots=MarketInfo(Symbol(),MODE_MINLOT);
                  if(my_lots>MarketInfo(Symbol(),MODE_MAXLOT))
                     my_lots=MarketInfo(Symbol(),MODE_MAXLOT);


                  //Once all the information has been set and the TP and SL are set and has found a lot size amount from the box description then it is good to go to enter a trade.
                  //Check if box description is not empty as well as there is a command to execute.
                  if(strlots!="" && OKToTrade==true)
                    {

                     //Execute the order
                     openticket1=Open_Trade(Symbol(),cmd,entryprice1,my_lots,sl,tp,"T01_"+strname+"_"+TradeCode);
                     Print("Open_trade. sl: "+sl+" tp: "+tp+" Openprice: "+entryprice1+" cmd: "+cmd);

                    }
                  //Now that we have a new trade in place. Overwrite the infobox with the calculations we have
                  infobox=InfoBoxOrderPrefix+" SL: "+DoubleToStr(NormalizeDouble(stop_in_pips,2),1)+" | TP: "+DoubleToStr(tp_in_pips,1)+" | RvR: "+DoubleToStr(RvR,1);


                  if(openticket1>0)
                    {
                     //Set off an alarm to notify that trade has been undertaken
                     if(cmd==OP_BUYLIMIT)
                        Alert("BUY LIMIT "+Symbol()+" "+strtf(Period())+" Date & Time: "+TimeToStr(TimeCurrent(),TIME_DATE)+" "+TimeToStr(TimeCurrent(),TIME_MINUTES)+" - "+WindowExpertName());
                     if(cmd==OP_SELLLIMIT)
                        Alert("SELL LIMIT "+Symbol()+" "+strtf(Period())+" Date & Time: "+TimeToStr(TimeCurrent(),TIME_DATE)+" "+TimeToStr(TimeCurrent(),TIME_MINUTES)+" - "+WindowExpertName());
                     if(cmd==OP_SELL)
                        Alert("SELL MARKET "+Symbol()+" "+strtf(Period())+" Date & Time: "+TimeToStr(TimeCurrent(),TIME_DATE)+" "+TimeToStr(TimeCurrent(),TIME_MINUTES)+" - "+WindowExpertName());
                     if(cmd==OP_BUY)
                        Alert("BUY MARKET "+Symbol()+" "+strtf(Period())+" Date & Time: "+TimeToStr(TimeCurrent(),TIME_DATE)+" "+TimeToStr(TimeCurrent(),TIME_MINUTES)+" - "+WindowExpertName());

                     //Draw a new TP1 line which will be used for order management
                     DrawTL("vTP1_"+IntegerToString(openticket1),tp,backline,tp,frontline,clrYellow,STYLE_SOLID,2);

                     //Removes the previous TP line used for measurements as it will be replaced with the line used for ordermanagement.
                     ObjectDelete("vTP1_"+strname);

                     //Removes a object parameters so that we can not trigger another other.
                     ObjectSetText(strname,"");
                     strlots="";

                     //Check to see if the Entry price is the same as the Box dimension. If not, readjust the box size.
                     if(OrderSelect(openticket1, SELECT_BY_TICKET)==true)
                       {
                        if(cmd==OP_SELL)
                          {

                           ObjectSet(strname,OBJPROP_PRICE2,OrderOpenPrice());
                          }
                        else
                           if(cmd==OP_BUY)
                             {
                              ObjectSet(strname,OBJPROP_PRICE1,OrderOpenPrice());
                             }
                       }
                     else
                        Print("OrderSelect returned the error of ",GetLastError());

                     //If Pyramid trading is allowed then action
                     if(allowed_2nd_trade)
                       {
                        int cmd2=-1;
                        //if the order is a buy order (limit or market)
                        if(cmd==OP_BUYLIMIT || cmd==OP_BUY)
                          {
                           //Set the entry for second trade at 1R distance from the first trade
                           entryprice2=entryprice1+(entryprice1-sl);
                           //Set the TP for 2nd trade at twice the distance from the first trade
                           tp2=entryprice1+2*(entryprice1-sl);
                           //Set the SL at half the distance between the first trade entry and SL
                           stoploss2=entryprice1-0.5*(entryprice1-sl);

                          }
                        //if the order is a sell order (limit or market)
                        if(cmd==OP_SELLLIMIT || cmd==OP_SELL)
                          {
                           entryprice2=entryprice1-(sl-entryprice1);
                           tp2=entryprice1-2*(sl-entryprice1);
                           stoploss2=entryprice1+0.5*(sl-entryprice1);
                          }

                        //Draw all the second trade lines for trade management as required.
                        //Trade entry for second trade
                        DrawTL("vOP2_"+IntegerToString(openticket1),entryprice2,backline,entryprice2,frontline,clrGreen,STYLE_SOLID,1);
                        //Not sure what this does TBH.
                        DrawTL("vvOP2_"+IntegerToString(openticket1),entryprice2,backline,entryprice2,frontline,clrNONE,STYLE_SOLID,1);
                        //Stop loss of second trade
                        DrawTL("vSL2_"+IntegerToString(openticket1),stoploss2,backline,stoploss2,frontline,clrBrown,STYLE_SOLID,2);
                        //Take profit of second trade
                        DrawTL("vTP2_"+IntegerToString(openticket1),tp2,middleofbox,tp2,frontline,clrBrown,STYLE_SOLID,2);
                        //Vertical Link line on the left hand side for ease of knowing which lines are related to which trade.
                        DrawTL("Link_"+IntegerToString(openticket1),lowerline,backline,tp,backline,clrBrown,STYLE_DOT,1);


                        ObjectSet("vTP1_"+IntegerToString(openticket1),OBJPROP_TIME1,MathMin(time1,time2));

                        //Draw the TP1 line only to the middle of the box so that it is easier to grab and move rather then TP1 and TP2 lines overlapping each other
                        ObjectSet("vTP1_"+IntegerToString(openticket1),OBJPROP_TIME2,middleofbox);

                       }

                     //Take screenshot of the Trade entry
                     CaptureScreenshot(OrderTicket(),"1.6_" + GetPeriodName(PERIOD_CURRENT) + "_"  +Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     long idchart=0;
                     // Screnshot M15 trade
                     idchart = OpenNewChart(PERIOD_M15);
                     SetTemplate(idchart);
                     CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.5_" + GetPeriodName(PERIOD_M15) + "_"    +Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     CloseChart(idchart);
                     // Screnshot H1 trade
                     idchart = OpenNewChart(PERIOD_H1);
                     SetTemplate(idchart);
                     CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.4_" + GetPeriodName(PERIOD_H1) +  "_"  +TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     CloseChart(idchart);
                     // Screnshot H4 trade
                     idchart = OpenNewChart(PERIOD_H4);
                     SetTemplate(idchart);
                     CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.3_" + GetPeriodName(PERIOD_H4) +  "_" + Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     CloseChart(idchart);
                     // Screnshot D1 trade
                     idchart = OpenNewChart(PERIOD_D1);
                     SetTemplate(idchart);
                     CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.2_" + GetPeriodName(PERIOD_D1) +  "_" + Symbol()+ "_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     CloseChart(idchart);
                     // Screnshot W1 trade
                     idchart = OpenNewChart(PERIOD_W1);
                     SetTemplate(idchart);
                     CaptureScreenshotHigherTf(idchart,OrderTicket(),"1.1_" + GetPeriodName(PERIOD_W1) +  "_" + Symbol()+ "_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_TradeEntry");
                     CloseChart(idchart);

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

         //what is this even for?
         if(StringFind(strname,"vTP1_Rectangle")!=-1)
           {
            if(ObjectFind(0,StringSubstr(strname,5,StringLen(strname)))==-1)
              {
               Print("wtf");
               ObjectDelete(strname);
              }
           }
        }
     }

   refreshcharttime=TimeCurrent()+60;

/// Green box trading ---------------------------------------------------
   string TargetBoxName;
   double Furthest_away_point;
// Loop through all objects on chart
   for(int i=ObjectsTotal()-1; i>=0; i--)
     {
      string objectName = ObjectName(i);

      // Check if current object color is green
      if(ObjectGetInteger(0, objectName, OBJPROP_COLOR) == clrGreen && ObjectGetInteger(0, objectName, OBJPROP_TYPE) == OBJ_RECTANGLE)
        {
         // Object is green

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
         double greenBoxLeft = ObjectGet(objectName, OBJPROP_TIME1);
         double greenBoxTop = ObjectGet(objectName, OBJPROP_PRICE1);
         double greenBoxRight = ObjectGet(objectName, OBJPROP_TIME2);
         double greenBoxBottom = ObjectGet(objectName, OBJPROP_PRICE2);

         //Determine the upper and lower line of the box by understandig which is the Min or max value.
         //if there is no greenbox TP line found then ...
         if(ObjectFind("greenBoxTPName") == -1)
           {
            //Find the line which is the furthest away from the Bid
            if(MathAbs(greenBoxTop-Bid) > MathAbs(greenBoxBottom-Bid))
              {
               Furthest_away_point = greenBoxTop;
              }
            else
              {
               Furthest_away_point = greenBoxBottom;
              }

            double greenBoxHeight = MathAbs(greenBoxTop - greenBoxBottom);

            //
            if(Bid < Furthest_away_point)
              {
               //Target first supply zone it sees
               TargetBoxName = "a|II_Logo_0_M1_UPZONE1";

               //create a TP line for the system to target
               double lineDistance = greenBoxBottom - (greenBoxHeight * 2);

               DrawTL("greenBoxTPName",lineDistance,greenBoxLeft,lineDistance,greenBoxRight,clrGreen,STYLE_DASH,1);

              }

            if(Bid > Furthest_away_point)
              {
               //Target first demand zone it sees
               TargetBoxName = "a|II_Logo_0_M1_DNZONE1";

               //create a TP line for the system to target
               double lineDistance = greenBoxBottom + (greenBoxHeight * 2);

               DrawTL("greenBoxTPName",lineDistance,greenBoxLeft,lineDistance,greenBoxRight,clrGreen,STYLE_DASH,1);

              }
            printf("Furthest_away_point: "+Furthest_away_point+" greenBoxBottom:"+greenBoxBottom+" greenBoxTop:"+greenBoxTop+" MathAbs(greenBoxTop-Bid):"+MathAbs(greenBoxTop-Bid)+" MathAbs(greenBoxBottom-Bid):" +MathAbs(greenBoxBottom-Bid));

           }

         //read greenboxtpname and if that is greater then bid then make targetboxname "a|II_Logo_0_M1_DNZONE1" and vice versa

         //constatntly adjust the edges of the TP to match the edges of the box but not change the price location
         ObjectSetInteger(0, "greenBoxTPName", OBJPROP_TIME1, greenBoxLeft);
         ObjectSetInteger(0, "greenBoxTPName", OBJPROP_TIME2, greenBoxRight);

         // Loop through objects again to find TargetBoxName
         for(int j=ObjectsTotal()-1; j>=0; j--)
           {
            string innerObjectName = ObjectName(j);

            // Check if current inner object is TargetBoxName
            if(innerObjectName == TargetBoxName)
              {
               // Get coordinates of TargetBoxName

               double targetBoxLeft = ObjectGet(innerObjectName, OBJPROP_TIME1);
               double targetBoxTop = ObjectGet(innerObjectName, OBJPROP_PRICE1);
               double targetBoxRight = ObjectGet(innerObjectName, OBJPROP_TIME2);
               double targetBoxBottom = ObjectGet(innerObjectName, OBJPROP_PRICE2);
               double spread = MarketInfo(Symbol(), MODE_SPREAD);

               printf("Height "+MathAbs(targetBoxTop - targetBoxBottom)/myPoint);
               printf("TargetBoxName "+TargetBoxName);
               printf("spread"+(Ask-Bid));

               // Check if TargetBoxName is within green box
               if(targetBoxLeft >= greenBoxLeft &&
                  targetBoxTop <= greenBoxTop &&
                  targetBoxRight <= greenBoxRight &&
                  targetBoxBottom >= greenBoxBottom &&
                  MathAbs(targetBoxTop - targetBoxBottom)/Point >= 3 //ensure we are not entering any tiny SD levels.
                 )

                 {
                  // Target box is within green box

                  // Create new red box over TargetBoxName

                  RectangleCreate(0, "RedBox", 0, targetBoxLeft, targetBoxTop, greenBoxRight, targetBoxBottom, clrRed, STYLE_SOLID, 1, true, true, true);
                    
                  // Get description of green box
                  string greenBoxDesc = ObjectDescription(objectName);

                  // Set red box description to match green box
                  ObjectSetString(0, "RedBox", OBJPROP_TEXT, greenBoxDesc);

                  // Change green box to violet colour dashed line
                  ObjectSetInteger(0, objectName, OBJPROP_COLOR, clrViolet);
                  ObjectSetInteger(0, objectName, OBJPROP_BACK, false);
                  ObjectSetInteger(0, objectName, OBJPROP_FILL, false);
                  //ObjectSetInteger(0, objectName, OBJPROP_BORDER_COLOR, clrViolet);
                  //ObjectSetInteger(0, objectName, OBJPROP_STYLE, STYLE_DASHDOTDOT);

                  //TODO -Take the green dashed line and replace value with value for yellow

                  // Remove green dashed line object
                  //ObjectDelete(0, "DashLine");

                  //Alert("Box Found!");




                 }
              }
           }
        }
     }


  }


//----

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+-------------------------General Functions------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|     FUNCTION DEPRECATED                                                             |
//+------------------------------------------------------------------+
/*
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
 */

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
         if(ObjectGet(StringConcatenate(LevelPrefix,IntegerToString(i)),OBJPROP_COLOR)!=whoredOutDemandLevelColour || ObjectGet(StringConcatenate(LevelPrefix,IntegerToString(i)),OBJPROP_COLOR)!=whoredOutSupplyLevelColour) //Check to see if the level is the entry colour of green showing fresh level
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
                     //ModifySDLevels(0,"Supply_"+i,NULL,NULL,iTime(SymbolCheck,PeriodCheck,x),NULL,whoredOutSupplyLevelColour);
                     //break the for loop early to save processing power
                     x=1;
                    }
                  else
                     if(LevelPrefix=="Demand_")
                       {
                        //ModifySDLevels(0,"Demand_"+i,NULL,NULL,iTime(SymbolCheck,PeriodCheck,x),NULL,whoredOutDemandLevelColour);
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
               ": failed to create a rectangle! Error code = ",ErrorDescription(GetLastError()));
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
            ": failed to delete rectangle! Error code = ",ErrorDescription(GetLastError()));
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
               ": failed to create \"Arrow Down\" sign! Error code = ",ErrorDescription(GetLastError()));
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
/*--- Seems as if this is no longer used.
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
bool ModifyProfitTarget(int myTicket,double ProfitTarget,double StopLoss, double EntryPrice = NULL)
  {
   int try;
   string strerr="";



   if(OrderSelect(myTicket,SELECT_BY_TICKET,MODE_TRADES)==False)
      return(false);

//If either SL or TP not set then set as their original amounts
   if(ProfitTarget==NULL || ProfitTarget=="")
      ProfitTarget = OrderTakeProfit();
   if(StopLoss==NULL || StopLoss=="")
      StopLoss = OrderStopLoss();
   if(EntryPrice==NULL || EntryPrice=="")
      EntryPrice = OrderOpenPrice();


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
                        return(true);
                       }
                     else
                       {
                        err=GetLastError();
                        strerr=IntegerToString(err);
                        CaptureScreenshot(myTicket,Symbol()+"_"+TimeYear(TimeCurrent())+"_"+TimeMonth(TimeCurrent())+"_"+TimeDay(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+"_OrderModifyError");
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
         ticket=OrderSend(curr,cmd,lot,price,slippage,0,0,comm,magic_number,0,colour);
         if(ticket>0)
           {
            break;
            Print("Trade entered successfully");
           }
         else
           {
            err=GetLastError();
            strerr=IntegerToString(err);
            Print("OrderSend Error # "+strerr+" : ",ErrorDescription(err));
            Print("retry: "+retry+" ticket: "+ticket+" curr: "+curr+" cmd: "+cmd+" lot: "+lot+" price: "+price+" sl: "+sl+" tp: "+tp+" comm: "+comm);
           }
        }
     }
   else
     {
      for(retry=1; retry<=number_retry_open_trade; retry++)
        {
         RefreshRates();
         ticket=OrderSend(curr,cmd,lot,price,slippage,sl,tp,comm,magic_number,0,colour);
         if(ticket>0)
           {
            break;
            Print("Trade entered successfully");
           }
         else
           {
            err=GetLastError();
            strerr=IntegerToString(err);
            Print("OrderSend Error # "+strerr+" : ",ErrorDescription(err));
            Print("retry: "+retry+" ticket: "+ticket+" curr: "+curr+" cmd: "+cmd+" lot: "+lot+" price: "+price+" sl: "+sl+" tp: "+tp+" comm: "+comm);
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
               Print("Trade entered successfully 2");
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
            ": failed to create '"+name+"' object! Error code = ",ErrorDescription(GetLastError()));
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
            ": failed to move the anchor point! Error code = ",ErrorDescription(GetLastError()));
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
            ": failed to change the text! Error code = ",ErrorDescription(GetLastError())," Object name:",name);
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
            ": failed to delete \"Text\" object! Error code = ",ErrorDescription(GetLastError()));
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
               Print("Navigate failed. Error = ",ErrorDescription(GetLastError()));
            ChartRedraw();
           }
        }
     }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Create folders and Generate screenshots                          |
//+------------------------------------------------------------------+
void CaptureScreenshot(int TradeID, string filename)
  {
   string Foldername = TradeID+"_"+Symbol();
   CreateFolder(Foldername,false);

   if(WindowScreenShot(Foldername+"\\"+filename+".gif",Screenshot_Width,Screenshot_Height))
     {
      Print("Screenshot captured: "+filename);

     }
   else
     {
      err=GetLastError();
      string strerr=IntegerToString(err);
      Print("Screenshot error:"+strerr);
     }

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Generate screenshot for higher tf                                |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CaptureScreenshotHigherTf(long chartid,int TradeID, string filename)
  {


   string Foldername = TradeID+"_"+Symbol();
   ChartScreenShot(chartid,Foldername+"\\"+filename+".gif",Screenshot_Width,Screenshot_Height);

  }



//+------------------------------------------------------------------+
//| Try creating a folder and display a message about that           |
//+------------------------------------------------------------------+
bool CreateFolder(string folder_path,bool common_flag)
  {
   int flag=common_flag?FILE_COMMON:0;
   string working_folder;
//--- define the full path depending on the common_flag parameter
   if(common_flag)
      working_folder=TerminalInfoString(TERMINAL_COMMONDATA_PATH)+"\\MQL4\\Files";
   else
      working_folder=TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL4\\Files";
//--- debugging message
   PrintFormat("folder_path=%s",folder_path);
//--- attempt to create a folder relative to the MQL5\Files path
   if(FolderCreate(folder_path,flag))
     {
      //--- display the full path for the created folder
      PrintFormat("Created the folder %s",working_folder+"\\"+folder_path);
      //--- reset the error code
      ResetLastError();
      //--- successful execution
      return true;
     }
   else
      PrintFormat("Failed to create the folder %s. Error code %d",working_folder+folder_path,ErrorDescription(GetLastError()));
//--- execution failed
   return false;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Create the button                                                |
//+------------------------------------------------------------------+
bool ButtonCreate(const long              chart_ID=0,               // chart's ID
                  const string            name="Button",            // button name
                  const int               sub_window=0,             // subwindow index
                  const int               x=0,                      // X coordinate
                  const int               y=0,                      // Y coordinate
                  const int               width=50,                 // button width
                  const int               height=18,                // button height
                  const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                  const string            text="Button",            // text
                  const string            font="Arial",             // font
                  const int               font_size=10,             // font size
                  const color             clr=clrBlack,             // text color
                  const color             back_clr=C'236,233,216',  // background color
                  const color             border_clr=clrNONE,       // border color
                  const bool              state=false,              // pressed/released
                  const bool              back=false,               // in the background
                  const bool              selection=false,          // highlight to move
                  const bool              hidden=true,              // hidden in the object list
                  const long              z_order=0)                // priority for mouse click
  {
//--- reset the error value
   ResetLastError();
//--- create the button
   if(!ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create the button "+name+"! Error code = ",ErrorDescription(GetLastError()));
      return(false);
     }
//--- set button coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set button size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set text color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- set border color
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- set button state
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
//--- enable (true) or disable (false) the mode of moving the button by mouse
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
//| Change button text                                               |
//+------------------------------------------------------------------+
bool ButtonTextChange(const long   chart_ID=0,    // chart's ID
                      const string name="Button", // button name
                      const string text="Text")   // text
  {
//--- reset the error value
   ResetLastError();
//--- change object text
   if(!ObjectSetString(chart_ID,name,OBJPROP_TEXT,text))
     {
      Print(__FUNCTION__,
            ": failed to change the text! Error code = ",ErrorDescription(GetLastError()));
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  Manages the color and behavior of the buttons on the screen    |
//+------------------------------------------------------------------+
void ManageButtons()
  {
   int i;
   string strname;
   bool temp;

//---If 'Indicator OFF' levels is pressed then hide all levels
   if(ObjectGetInteger(0,"Button-ShowLevels",OBJPROP_STATE)==true)
     {
      //Disable all other time frames
      ObjectSetInteger(0,"Button-15M",OBJPROP_STATE,True);
      ObjectSetInteger(0,"Button-H1",OBJPROP_STATE,True);
      ObjectSetInteger(0,"Button-H4",OBJPROP_STATE,True);
      ObjectSetInteger(0,"Button-D1",OBJPROP_STATE,True);

      //Set global variable so the button state persists even after changing TF.
      GlobalVariableSet(magic_id+"Button-ShowLevels",true);

      //Change the text to say 'ff' on button
      ButtonTextChange(0,"Button-ShowLevels","OFF");

      //--- set background color of button
      ObjectSetInteger(0,"Button-ShowLevels",OBJPROP_BGCOLOR,clrBlueViolet);

      /*
            //Go through all the objects and hide the ones that are the levels.
            for(i=0; i<ObjectsTotal(); i++)
              {
               strname=ObjectName(0,i);
               //if(StringFind(strname,"II_Logo_0")!=-1)
               //  {
               ObjectSet(strname,OBJPROP_TIMEFRAMES,OBJ_NO_PERIODS);
               //Print(strname+" Disabled");
               //  }
              }
              */
     }
   else
     {

      //Get the status of the buttons from the global variable and set it as the current button status.
      /*
      ObjectSetInteger(0,"Button-15M",OBJPROP_STATE,GlobalVariableGet(magic_id+"Button-15M"));
      ObjectSetInteger(0,"Button-H1",OBJPROP_STATE,GlobalVariableGet(magic_id+"Button-H1"));
      ObjectSetInteger(0,"Button-H4",OBJPROP_STATE,GlobalVariableGet(magic_id+"Button-H4"));
      ObjectSetInteger(0,"Button-D1",OBJPROP_STATE,GlobalVariableGet(magic_id+"Button-D1"));
      */
      GlobalVariableSet(magic_id+"Button-ShowLevels",false);
      ButtonTextChange(0,"Button-ShowLevels","Indicators ON");
      ObjectSetInteger(0,"Button-ShowLevels",OBJPROP_BGCOLOR,clrBlack);
      /*
      for(i=0; i<ObjectsTotal(); i++)
        {
         strname=ObjectName(0,i);
         if(StringFind(strname,"II_Logo_0")!=-1)
           {
         ObjectSet(strname,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
           }
        }
      */

     }




//--- Disable all 15M levels
   if(ObjectGetInteger(0,"Button-15M",OBJPROP_STATE)==True)
     {
      GlobalVariableSet(magic_id+"Button-15M",true);
      ButtonTextChange(0,"Button-15M","OFF");
      //--- set background color
      ObjectSetInteger(0,"Button-15M",OBJPROP_BGCOLOR,clrBlueViolet);
      for(i=0; i<ObjectsTotal(); i++)
        {
         strname=ObjectName(0,i);
         if(StringFind(strname,"II_Logo_0_15")!=-1)
           {
            ObjectSet(strname,OBJPROP_TIMEFRAMES,OBJ_NO_PERIODS);
           }
        }
     }
   else
     {
      GlobalVariableSet(magic_id+"Button-15M",false);
      ButtonTextChange(0,"Button-15M","15M");
      ObjectSetInteger(0,"Button-15M",OBJPROP_BGCOLOR,clrBlack);
      for(i=0; i<ObjectsTotal(); i++)
        {
         strname=ObjectName(0,i);
         if(StringFind(strname,"II_Logo_0_15")!=-1)
           {
            ObjectSet(strname,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
           }
        }
     }

//---Disable all H1 levels
   if(ObjectGetInteger(0,"Button-H1",OBJPROP_STATE)==True)
     {
      GlobalVariableSet(magic_id+"Button-H1",true);
      ButtonTextChange(0,"Button-H1","OFF");
      //--- set background color
      ObjectSetInteger(0,"Button-H1",OBJPROP_BGCOLOR,clrBlueViolet);
      for(i=0; i<ObjectsTotal(); i++)
        {
         strname=ObjectName(0,i);
         if(StringFind(strname,"II_Logo_0_H1")!=-1)
           {
            ObjectSet(strname,OBJPROP_TIMEFRAMES,OBJ_NO_PERIODS);
           }
        }
     }
   else
     {
      GlobalVariableSet(magic_id+"Button-H1",false);
      ButtonTextChange(0,"Button-H1","H1");
      ObjectSetInteger(0,"Button-H1",OBJPROP_BGCOLOR,clrBlack);
      for(i=0; i<ObjectsTotal(); i++)
        {
         strname=ObjectName(0,i);
         if(StringFind(strname,"II_Logo_0_H1")!=-1)
           {
            ObjectSet(strname,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
           }
        }
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0,"Button-H4",OBJPROP_STATE)==True)
     {
      GlobalVariableSet(magic_id+"Button-H4",true);
      ButtonTextChange(0,"Button-H4","OFF");
      //--- set background color
      ObjectSetInteger(0,"Button-H4",OBJPROP_BGCOLOR,clrBlueViolet);
      for(i=0; i<ObjectsTotal(); i++)
        {
         strname=ObjectName(0,i);
         if(StringFind(strname,"II_Logo_0_H4")!=-1)
           {
            ObjectSet(strname,OBJPROP_TIMEFRAMES,OBJ_NO_PERIODS);
           }
        }
     }
   else
     {
      GlobalVariableSet(magic_id+"Button-H4",false);
      ButtonTextChange(0,"Button-H4","H4");
      ObjectSetInteger(0,"Button-H4",OBJPROP_BGCOLOR,clrBlack);
      for(i=0; i<ObjectsTotal(); i++)
        {
         strname=ObjectName(0,i);
         if(StringFind(strname,"II_Logo_0_H4")!=-1)
           {
            ObjectSet(strname,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
           }
        }
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0,"Button-D1",OBJPROP_STATE)==True)
     {
      GlobalVariableSet(magic_id+"Button-D1",true);
      ButtonTextChange(0,"Button-D1","OFF");
      //--- set background color
      ObjectSetInteger(0,"Button-D1",OBJPROP_BGCOLOR,clrBlueViolet);
      for(i=0; i<ObjectsTotal(); i++)
        {
         strname=ObjectName(0,i);
         if(StringFind(strname,"II_Logo_0_D1")!=-1)
           {
            ObjectSet(strname,OBJPROP_TIMEFRAMES,OBJ_NO_PERIODS);
           }
        }
     }
   else
     {
      GlobalVariableSet(magic_id+"Button-D1",false);
      ButtonTextChange(0,"Button-D1","D1");
      ObjectSetInteger(0,"Button-D1",OBJPROP_BGCOLOR,clrBlack);
      for(i=0; i<ObjectsTotal(); i++)
        {
         strname=ObjectName(0,i);
         if(StringFind(strname,"II_Logo_0_D1")!=-1)
           {
            ObjectSet(strname,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
           }
        }
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0,"Button-EnableRules",OBJPROP_STATE)==True && ObjectFind(0,"TradeRules1")!=-1)
     {
      ButtonTextChange(0,"Button-EnableRules","Rules OFF");
      ObjectSetInteger(0,"Button-EnableRules",OBJPROP_BGCOLOR,clrBlueViolet);
      TextDelete(0,"TradeRules1");
      TextDelete(0,"TradeRules2");
      TextDelete(0,"TradeRules3");
      TextDelete(0,"TradeRules4");
      TextDelete(0,"TradeRules5");
      TextDelete(0,"TradeRules6");
      TextDelete(0,"TradeRules7");
     }
   else
     {
      if(ObjectGetInteger(0,"Button-EnableRules",OBJPROP_STATE)==False && ObjectFind(0,"TradeRules1")==-1)
        {
         DrawRulesOnScreen();
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Create a text label                                              |
//+------------------------------------------------------------------+
bool LabelCreate(const long              chart_ID=0,               // chart's ID
                 const string            name="Label",             // label name
                 const int               sub_window=0,             // subwindow index
                 const int               x=0,                      // X coordinate
                 const int               y=0,                      // Y coordinate
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                 const string            text="Label",             // text
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
//--- reset the error value
   ResetLastError();
//--- create a text label
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create text label "+name+"! Error code = ",ErrorDescription(GetLastError()));
      return(false);
     }
//--- set label coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
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
//--- enable (true) or disable (false) the mode of moving the label by mouse
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawRulesOnScreen()
  {
   long x_distance;
   long y_distance;
//--- set window size
   if(!ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance))
     {
      Print("Failed to get the chart width! Error code = ",ErrorDescription(GetLastError()));

     }
   if(!ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,y_distance))
     {
      Print("Failed to get the chart height! Error code = ",ErrorDescription(GetLastError()));

     }

   int x=(int)x_distance/32;
   int y=(int)y_distance/32;
   ButtonTextChange(0,"Button-EnableRules","Rules ON");
   ObjectSetInteger(0,"Button-EnableRules",OBJPROP_BGCOLOR,clrBlack);
   LabelCreate(0,"TradeRules1",0,10,y+50,CORNER_LEFT_UPPER,Rule1,"Arial",10,clrWhiteSmoke,0.0,ANCHOR_LEFT_UPPER,false,false,0);
   LabelCreate(0,"TradeRules2",0,10,y+70,CORNER_LEFT_UPPER,Rule2,"Arial",10,clrWhiteSmoke,0.0,ANCHOR_LEFT_UPPER,false,false,0);
   LabelCreate(0,"TradeRules3",0,10,y+90,CORNER_LEFT_UPPER,Rule3,"Arial",10,clrWhiteSmoke,0.0,ANCHOR_LEFT_UPPER,false,false,0);
   LabelCreate(0,"TradeRules4",0,10,y+110,CORNER_LEFT_UPPER,Rule4,"Arial",10,clrWhiteSmoke,0.0,ANCHOR_LEFT_UPPER,false,false,0);
   LabelCreate(0,"TradeRules5",0,10,y+130,CORNER_LEFT_UPPER,Rule5,"Arial",10,clrWhiteSmoke,0.0,ANCHOR_LEFT_UPPER,false,false,0);
   LabelCreate(0,"TradeRules6",0,10,y+150,CORNER_LEFT_UPPER,Rule6,"Arial",10,clrWhiteSmoke,0.0,ANCHOR_LEFT_UPPER,false,false,0);
   LabelCreate(0,"TradeRules7",0,10,y+170,CORNER_LEFT_UPPER,Rule7,"Arial",10,clrWhiteSmoke,0.0,ANCHOR_LEFT_UPPER,false,false,0);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long OpenNewChart(ENUM_TIMEFRAMES _period)
  {
   long NewId =   ChartOpen(Symbol(),_period);
   if(NewId ==0)
     {
      return 0;
     }
   else
     {
      return NewId;
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseChart(long _id)
  {
   bool result= ChartClose(_id);
   return result;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetTemplate(long _id)
  {
//----------- START - SET UP CHART FURNISHING -------------
//--- enable object create events
   ChartSetInteger(_id,CHART_EVENT_OBJECT_CREATE,true);
//--- enable object delete events
   ChartSetInteger(_id,CHART_EVENT_OBJECT_DELETE,true);
//--- Remove grid
   ChartSetInteger(_id,CHART_SHOW_GRID,0,false);
//--Chart should be candlesticks
   ChartSetInteger(_id,CHART_MODE,0,CHART_CANDLES);
//--Chart to set shift
   ChartSetInteger(_id,CHART_SHIFT,0,true);
//--Chart scale
   ChartSetInteger(_id,CHART_SCALE,0,2);
//---Chat show ask line
   ChartSetInteger(_id,CHART_SHOW_ASK_LINE,0,true);



  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetPeriodName(ENUM_TIMEFRAMES period)
  {
   if(period==PERIOD_CURRENT)
      period=Period();
//---
   switch(period)
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
     }
//---
   return("unknown period");
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int   GetOpenOrder(int magic,string simbolo)
  {
   int Totale=0;
   int  iOrders=OrdersTotal(), i;
   for(i=iOrders-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {

         if(OrderMagicNumber() == magic  && OrderSymbol()==simbolo)
           {
            Totale= Totale +1;
           }
        }

     }

   return Totale;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void   CheckOrderForSendTrade(int magic,string simbolo,int difference)
  {
   int Totale=0;
   int  iOrders=OrdersTotal(), i;
   for(i=iOrders-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {

         if(OrderMagicNumber() == magic  && OrderSymbol()==simbolo && OrderType() <2)
           {
            // this for avoid to send again all trade when stop mt4
            if(TimeCurrent() - OrderOpenTime() < difference)
              {
               //SendScreen(channeltlg,0,Symbol()+ "| Type " + IntegerToString(OrderType()) + "| Price Open " + DoubleToString(OrderOpenPrice(),Digits()) + "| Volume " + DoubleToString(OrderLots(),Digits()),Symbol() + "_" + Period() + "_" + magic);
              }
           }
        }

     }


  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int SendScreen(ulong channeL,int chartid,string commento,string nomefile)
  {
   if(ChartScreenShot(chartid,nomefile + ".png",Screenshot_Width,Screenshot_Height,ALIGN_RIGHT))
      string filename = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\Files\\"+ nomefile + ".PNG";
   Print(GetLastError());
   string photo_id;
//return bot.SendPhoto(photo_id,channeL,nomefile + ".PNG",commento,false,10000);
   return
      FileDelete(TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\Files\\"+ nomefile + ".PNG");
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void WriteHeader()
  {
   string Header = "OrderId,DateTime,OrderType,Symbol,Lots,TpInPips,SlInPips,Rvr,Trade Outcome,Current Account,Comments,Trade OutComments";


   WriteFile(logfile,Header);

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void WriteFile(string name,string text)
  {


   int handlelog=FileOpen(name,FILE_CSV|FILE_WRITE|FILE_READ,",");
   if(handlelog<1)
     {
      Print(GetLastError());
     }
   FileSeek(handlelog, 0, SEEK_END);

   FileWrite(handlelog,text);
   FileFlush(handlelog);
   FileClose(handlelog);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
