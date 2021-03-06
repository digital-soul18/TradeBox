//+------------------------------------------------------------------+
//|                                           SB_Boxes_Trades_EA.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#include <stdlib.mqh>


#property copyright "Copyright 2016"
#property link      ""
#property version   "1.00"
#property strict

extern bool allowed_2nd_trade=true;
extern color activate_colour=clrRed;
extern int magic_number=929161;
extern int slippage = 5;   //Allowed slippage of open/close order
extern bool debugmode = true;

double take_profit=0;         				//Fixed takeprofit in pips (0=no takeprofit)
double stop_loss=0;           				//Fixed stoploss in pips (0=no stoploss)

int timeframe=0;
int number_retry_open_trade=10;

double     myPoint, mySpread, myStopLevel,myTickValue,myTickSize,myLotValue;
double       myDigits;
datetime   TradeBarTime;
bool       enable_ea;
double     my_lots;
int        digit_lot;

int signal;
int signalclose;
int myBars;
double last_history_check;
string TradeCode="SB00";


   
int err;
string strsuffix;
double ratio=1000000;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   SetPoint();
   if(Digits==3 || Digits==5) slippage*=10;
   if(MarketInfo(Symbol(),MODE_LOTSTEP)>=0.01) digit_lot=2;   
   if(MarketInfo(Symbol(),MODE_LOTSTEP)>=0.1) digit_lot=1;   
   if(MarketInfo(Symbol(),MODE_LOTSTEP)>=1) digit_lot=0;
   TradeBarTime=Time[0];
   strsuffix="_"+Symbol()+IntegerToString(Period())+"_"+TradeCode+"_"+IntegerToString(magic_number);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }


double setTP(double open, double tp_pips) { if(tp_pips==0) return(0); else return(NormalizeDouble(open+(tp_pips*myPoint),Digits)); }
double setSL(double open, double sl_pips) { if(sl_pips==0) return(0); else return(NormalizeDouble(open-(sl_pips*myPoint),Digits)); }

bool isAlreadyEnter(string strcomment)
{
   int i;
   for(i=OrdersTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() ==magic_number)
         {
            if(StringFind(OrderComment(),strcomment)!=-1) return(true);  
         }
      }
   }
   for(i=OrdersHistoryTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==True)
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() ==magic_number)
         {
            if(StringFind(OrderComment(),strcomment)!=-1) return(true);  
         }
      }
   }
   
   return(false);
}

void CheckBoxes()
{
   int i;
   int x;
   int status;
   for(i=OrdersTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() ==magic_number && OrderType()>1)
         {
            string str1=StringSubstr(OrderComment(),0,StringFind(OrderComment(),"_"+TradeCode));
            string str2=StringSubstr(str1,StringFind(str1,"_")+1);
            if((ObjectFind(str2)==-1) || (ObjectFind(str2)!=-1 && ObjectGet(str2,OBJPROP_COLOR)!=activate_colour) )
            {
               status=0;
               for (x = 5; x!= 0; x--) 
               {                              
                  while (IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                  status = OrderDelete(OrderTicket());
                  if (status == 1) { break; }
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

void FindClosedTrades()
{
   int i;
   for(i=OrdersHistoryTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==True)
      {
         int orderticket=OrderTicket();
         int ordertype=OrderType();
         string ordersymbol=OrderSymbol();
         int ordermagic=OrderMagicNumber();
         string ordercomment=OrderComment();
         double orderlots=OrderLots();
         if(ordersymbol == Symbol() && ordermagic ==magic_number && ordertype<=1)
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
         }
      }
   }
}

void DeleteTradeAfterBox()
{
   int i;
   int x;
   int status;
   for(i=OrdersTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() ==magic_number && OrderType()>1)
         {
            string str1=StringSubstr(OrderComment(),0,StringFind(OrderComment(),"_"+TradeCode));
            string str2=StringSubstr(str1,StringFind(str1,"_")+1);
            datetime time1=StrToInteger(DoubleToString(GetRectTime(str2,OBJPROP_TIME1)));      
            datetime time2=StrToInteger(DoubleToString(GetRectTime(str2,OBJPROP_TIME2)));  
            datetime timex=MathMax(time1,time2);
            if(TimeCurrent()>=timex+(Period()*60))
            {
               status=0;
               for (x = 5; x!= 0; x--) 
               {                              
                  while (IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                  status = OrderDelete(OrderTicket());
                  if (status == 1) { break; }
               }
            }
         }
      }
   }
}

void TPLinesMoved()
{
   int i;
   for(i=OrdersTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() ==magic_number)
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
               
               double slprice2=NormalizeDouble(ObjectGet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1),Digits);
               if(slprice2!=OrderStopLoss() && StringFind(OrderComment(),"T02_")!=-1)
               {
                  printf("Point2-1");
                  ModifyProfitTarget(OrderTicket(),OrderTakeProfit(),slprice2);
               }  
         }
      }
   }
}

void BoxMoved()
{
   int i;
   for(i=OrdersTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() ==magic_number && OrderType()>1)
         {
            string str1=StringSubstr(OrderComment(),0,StringFind(OrderComment(),"_"+TradeCode));
            string str2=StringSubstr(str1,StringFind(str1,"_")+1);
            double price1=NormalizeDouble(GetRectPrice(str2,OBJPROP_PRICE1),Digits);      
            double price2=NormalizeDouble(GetRectPrice(str2,OBJPROP_PRICE2),Digits); 
            double upperline=MathMax(price1,price2);
            double lowerline=MathMin(price1,price2);
            datetime time1=StrToInteger(DoubleToString(GetRectTime(str2,OBJPROP_TIME1)));      
            datetime time2=StrToInteger(DoubleToString(GetRectTime(str2,OBJPROP_TIME2))); 
            int ret=0;
            //Print("ModifyOrder Sent - OrderOpenPrice()"+OrderOpenPrice()+" lowerline"+lowerline+" OrderStopLoss()"+OrderStopLoss()+" upperline"+upperline);
            if(StringFind(OrderComment(),"T01_")!=-1)
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
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,upperline);
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,upperline);
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,upperline+upperline-lowerline+upperline-lowerline);
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,upperline+upperline-lowerline+upperline-lowerline);
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                        /* This part makes the TP line move when the box is moved but then its also inflexible to move if we do this
                        /* move once then leave it needed
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,upperline+upperline-lowerline+upperline-lowerline);
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,upperline+upperline-lowerline+upperline-lowerline);
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                        */
                     }
                  }
               }
               else if(OrderType()==OP_SELLLIMIT && Bid<lowerline)
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
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,lowerline);
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,lowerline);
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vSL2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,lowerline-(upperline-lowerline)-(upperline-lowerline));
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,lowerline-(upperline-lowerline)-(upperline-lowerline));
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vTP2_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                        /* This part makes the TP line move when the box is moved but then its also inflexible to move if we do this
                        /*  move once then leave it needed maybe leave for 5 seconds and then do it once.
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE1,upperline-upperline-lowerline-upperline-lowerline);
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_PRICE2,upperline-upperline-lowerline-upperline-lowerline);
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME1,MathMin(time1,time2));
                        ObjectSet("vTP1_"+IntegerToString(OrderTicket()),OBJPROP_TIME2,MathMax(time1,time2));
                        */
                     }
                  }
               }
            }
            else if(StringFind(OrderComment(),"T02_")!=-1)
            {
            
            } 
         }
      }
   }
}

void SetPending2()
{
   int i;
   for(i=OrdersTotal()-1;i>=0;i--)
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
         if(ordersymbol == Symbol() && ordermagic ==magic_number && ordertype<=1 && StringFind(ordercomment,"T01_")!=-1)
         {
            if(ObjectFind("vvOP2_"+IntegerToString(orderticket))!=-1)
            {
               if(ordertype==OP_BUY) cmd=OP_BUYSTOP;
               else if(ordertype==OP_SELL) cmd=OP_SELLSTOP;
               double price=ObjectGet("vvOP2_"+IntegerToString(orderticket),OBJPROP_PRICE1);
               double sl=ObjectGet("vSL2_"+IntegerToString(orderticket),OBJPROP_PRICE1);
               double tp=ObjectGet("vTP2_"+IntegerToString(orderticket),OBJPROP_PRICE1);
               string strname;
               string str1=StringSubstr(ordercomment,0,StringFind(ordercomment,"_"+TradeCode));
               string str2=StringSubstr(str1,StringFind(str1,"_")+1);
               strname=str2;
               datetime time1=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME1)));      
               datetime time2=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME2)));  
               datetime frontline=MathMax(time1,time2);
               datetime backline=MathMin(time1,time2);
               int openticket=Open_Trade(Symbol(),cmd,price,orderlots,sl,tp,"T02_"+strname+"_"+TradeCode);
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
         }
      }
   }
}

void DeletePending2(string strcomment)
{
   int i;
   int x;
   int status;
   for(i=OrdersTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() ==magic_number && OrderType()>1)
         {
            if(StringFind(OrderComment(),"T02_"+strcomment)!=-1)
            {
               for (x = 5; x!= 0; x--) 
               {                              
                  while (IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                  status = OrderDelete(OrderTicket());
                  if (status == 1) 
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
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int i;
   double sl=0;
   double tp=0;   
   int openticket1=0;
   int openticket2=0;
   double openprice1=0;
   double openprice2=0;
   double stoploss2=0;
   double stop=0;



   bool enableopen = true; 
   
   string strname;
   string strlots;
   double upperline;
   double lowerline;
   datetime backline;
   datetime frontline;
   
   
   if(allowed_2nd_trade) 
   {
      SetPending2();
   }
   CheckBoxes();  //Delete limit trades if Box is deleted or change its colour
   FindClosedTrades(); //Change closed trades box to blue and tp line to dashes
   DeleteTradeAfterBox(); //Delete Limit trades that is outside box
   TPLinesMoved();   //Check if TP line is moved
   BoxMoved();       //Check if Box is moved
   
   
   
   if(enableopen)
   {
      for(i=0;i<ObjectsTotal();i++)
      {
         strname=ObjectName(0,i);
         if(ObjectType(strname)==OBJ_RECTANGLE)
         {
            strlots=ObjectDescription(strname);
            if(ObjectGet(strname,OBJPROP_COLOR)==activate_colour)
            {
               double price1=GetRectPrice(strname,OBJPROP_PRICE1);      
               double price2=GetRectPrice(strname,OBJPROP_PRICE2);      
               datetime time1=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME1)));      
               datetime time2=StrToInteger(DoubleToString(GetRectTime(strname,OBJPROP_TIME2)));  
               upperline=MathMax(price1,price2);
               lowerline=MathMin(price1,price2);
               frontline=MathMax(time1,time2);
               backline=MathMin(time1,time2);
               
               int cmd=-1;
               if(Bid>upperline) 
               {                   
                  cmd=OP_BUYLIMIT; openprice1=upperline; 
                  sl=lowerline; stop=(openprice1-sl)/myPoint; 
                  tp=setTP(openprice1,2*stop);
               }
               else if(Bid<lowerline) 
               { 
                  cmd=OP_SELLLIMIT; openprice1=lowerline; 
                  sl=upperline; stop=(sl-openprice1)/myPoint; 
                  tp=setTP(openprice1,-2*stop);
               } 
                            

               if(isAlreadyEnter("_"+strname+"_")==false && TimeCurrent()<=frontline)
               {
                  if(StringFind(strlots,"%")!=-1)
                  {
                     double percent=StrToDouble(StringSubstr(strlots,0,StringFind(strlots,"%")));
                     double my_lots2;
                     if(Digits==3 || Digits==5)
                        my_lots2=(AccountBalance()*percent*0.01)/(stop * myTickValue*10);
                     else 
                        my_lots2=(AccountBalance()*percent*0.01)/(stop * myTickValue);
                     my_lots=NormalizeDouble(my_lots2,digit_lot);
                  }
                  else if(StringFind(strlots,"%")==-1) my_lots=StrToDouble(strlots);                  
                  if(my_lots<MarketInfo(Symbol(),MODE_MINLOT)) my_lots=MarketInfo(Symbol(),MODE_MINLOT);
                  if(my_lots>MarketInfo(Symbol(),MODE_MAXLOT)) my_lots=MarketInfo(Symbol(),MODE_MAXLOT);

                  if(strlots != "") openticket1=Open_Trade(Symbol(),cmd,openprice1, my_lots,sl, tp, "T01_"+strname+"_"+TradeCode);                  
                  
                  if(ObjectFind("vTP1_"+strname)==-1 && openticket1==0){
                     DrawTL("vTP1_"+strname,tp,backline,tp,frontline,clrYellow,STYLE_DASH,1);
                     TextCreate(0,"InfoBox_"+strname,0,time2,sl,sl-tp,"Ariel",10,clrYellow,0.0,ANCHOR_RIGHT_UPPER); 
                  }
                  
                  if(openticket1>0)
                  {
                     if(cmd==OP_BUYLIMIT) Alert("BUY LIMIT "+ Symbol()+ " " + strtf(Period()) + " Date & Time: " + TimeToStr(TimeCurrent(),TIME_DATE)+" "+TimeToStr(TimeCurrent(),TIME_MINUTES) + " - " + WindowExpertName());
                     else if(cmd==OP_SELLLIMIT) Alert("SELL LIMIT "+ Symbol()+ " " + strtf(Period()) + " Date & Time: " + TimeToStr(TimeCurrent(),TIME_DATE)+" "+TimeToStr(TimeCurrent(),TIME_MINUTES) + " - " + WindowExpertName());
                     //TODO - Capture the time and price of the vTP1_strname and make it the value for vTP1_+IntegerToString(openticket1)
                     if(ObjectFind("vTP1_"+strname)!=-1){
                        ObjectDelete("vTP1_"+strname); 
                      } 
                     DrawTL("vTP1_"+IntegerToString(openticket1),tp,backline,tp,frontline,clrYellow,STYLE_SOLID,2);
                     if(allowed_2nd_trade)
                     {
                        int cmd2=-1;
                        if(cmd==OP_BUYLIMIT)
                        {
                           openprice2=openprice1+(stop*myPoint);
                           stoploss2=openprice1-(0.5*stop*myPoint);
                        }
                        else if(cmd==OP_SELLLIMIT)
                        {
                           openprice2=openprice1-(stop*myPoint);
                           stoploss2=openprice1+(0.5*stop*myPoint);
                        }
                        DrawTL("vOP2_"+IntegerToString(openticket1),openprice2,backline,openprice2,frontline,clrGreen,STYLE_SOLID,1);
                        DrawTL("vvOP2_"+IntegerToString(openticket1),openprice2,backline,openprice2,frontline,clrNONE,STYLE_SOLID,1);
                        DrawTL("vSL2_"+IntegerToString(openticket1),stoploss2,backline,stoploss2,frontline,clrYellow,STYLE_SOLID,3);
                        DrawTL("vTP2_"+IntegerToString(openticket1),tp,backline,tp,frontline,clrYellow,STYLE_SOLID,2);
                        
                     }
                  }
               }    
            }
         }
         if(StringFind(strname,"InfoBox_")!=-1){
            if(ObjectFind(0,StringSubstr(strname,8,StringLen(strname)))==-1) {
               TextDelete(0,strname);
            }
         }
         if(StringFind(strname,"vTP1_Rectangle")!=-1){
            if(ObjectFind(0,StringSubstr(strname,5,StringLen(strname)))==-1) {
               ObjectDelete(strname); 
            }
         }
      }
   }
   

   /*
   string debug_text = "";
   debug_text = StringConcatenate(debug_text,"Upperline - ", upperline) ;
   debug_text = StringConcatenate(debug_text,"\nStrlots - ", strlots) ;
   debug_text = StringConcatenate(debug_text,"\nStrname - ", strname) ;
   debug_text = StringConcatenate(debug_text,"\nmylots - ", my_lots) ;
    if(debugmode = true && ObjectFind("debug") == -1) {// create object 
     if(!ObjectCreate(0,"debug",OBJ_LABEL,0,0,0)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create text label! Error code = ",GetLastError()); 
     } 
    ObjectSetInteger(0,"debug",OBJPROP_XDISTANCE,10); 
    ObjectSetInteger(0,"debug",OBJPROP_YDISTANCE,10); 
    ObjectSetString(0,"debug",OBJPROP_TEXT,debug_text); 
    ObjectSetInteger(0,"debug",OBJPROP_COLOR,clrWhite); 

    }
    
   */
 
//----

  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+-------------------------General Functions------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
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

int CountOpenOrders(int direction)
{
int i,j;
   

   
   j  =  0;
   
   for(i=OrdersTotal()-1;i>=0;i--)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
            {
               if(   OrderType()          == direction   &&
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

int CloseTrades(int direction)
{
int j;
//double ClosePrice;

   j  =  0;
   int x;
   int status;
   
   if(direction==-1)
      return(0);
      
   for(int cnt=OrdersTotal()-1;cnt>=0;cnt--)
      {
         if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)==True)
            {
               if(OrderSymbol()==Symbol() && 
                  OrderMagicNumber()==magic_number)                     
                  if(OrderType()==direction)
                     {
                        if(OrderType()==OP_BUY)
                           {
                              for (x = 5; x!= 0; x--) 
                              {                              
                                 while (IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                                 status = OrderClose(OrderTicket(),OrderLots(),Bid,0);
                                 printf("order auto closed");
                                 if (status == 1) { j++; break; }
                              }
                           }
                        else
                           if(OrderType()==OP_BUYLIMIT)
                              {
                                 for (x = 5; x!= 0; x--) 
                                 {                              
                                    while (IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                                    status = OrderDelete(OrderTicket());
                                    if (status == 1) { j++; break; }
                                 }
                              }
                        else
                           if(OrderType()==OP_BUYSTOP)
                              {
                                 for (x = 5; x!= 0; x--) 
                                 {                              
                                    while (IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                                    status = OrderDelete(OrderTicket());
                                    if (status == 1) { j++; break; }
                                 }
                              }
                        
                        if(OrderType()==OP_SELL)
                           {
                              for (x = 5; x!= 0; x--) 
                              {                              
                                 while (IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                                 status = OrderClose(OrderTicket(),OrderLots(),Ask,0);
                                 if (status == 1) { j++; break; }
                              }
                           }
                        else
                           if(OrderType()==OP_SELLLIMIT)
                              {
                                 for (x = 5; x!= 0; x--) 
                                 {                              
                                    while (IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                                    status = OrderDelete(OrderTicket());
                                    if (status == 1) { j++; break; }
                                 }
                              }
                        else
                           if(OrderType()==OP_SELLSTOP)
                              {
                                 for (x = 5; x!= 0; x--) 
                                 {                              
                                    while (IsTradeContextBusy() || !IsTradeAllowed()) Sleep(5000);
                                    status = OrderDelete(OrderTicket());
                                    if (status == 1) { j++; break; }
                                 }
                              }
                     }
            }
      }
   
   return(j);
}


//+------------------------------------------------------------------+
//+----------------Modify Profit Target and Stop Loss----------------+

bool ModifyProfitTarget(int myTicket, double ProfitTarget, double StopLoss)
{
   int try;
   string strerr="";
   if(OrderSelect(myTicket,SELECT_BY_TICKET,MODE_TRADES)==False)
      return(false);
            
      if(
            (
               MathRound(ProfitTarget/Point)   != MathRound(OrderTakeProfit()/Point)
               ||
               MathRound(StopLoss/Point)       != MathRound(OrderStopLoss()/Point)
            )                 
        )
            {
               //RefreshRates();
               for(try=1;try<=5;try++)
               {
                  if(OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(StopLoss,Digits),NormalizeDouble(ProfitTarget,Digits),OrderExpiration()))
                     return(true);
                  else{
                     err=GetLastError();
                     strerr=IntegerToString(err);
                     Print("OrderModify Error # " + strerr + " : ",ErrorDescription(err));
                  }
               }
            }
   return(false);
}







//+------------------------------------------------------------------+
//+----------------------OPEN TRADE----------------------------------+


int Open_Trade(string curr,int cmd,double price, double lot,double sl, double tp, string comm)
{
   string strerr="";
   int ticket=0;
   int retry=0;
   color colour=CLR_NONE;
   
   sl=NormalizeDouble(sl,Digits);
   tp=NormalizeDouble(tp,Digits);
   price=NormalizeDouble(price,Digits);
   
   if(cmd==0) colour=Blue;
   if(cmd==1) colour=Red;
   
   if(Digits==3 || Digits==5) 
   {
      for(retry=1;retry<=number_retry_open_trade;retry++)
      {      
         RefreshRates();
         ticket=OrderSend(curr,cmd,lot,price,slippage,0,0,comm,magic_number,0,colour);
         if(ticket>0) break;
         else {
            err=GetLastError();
            strerr=IntegerToString(err);
            Print("OrderSend Error # " + strerr + " : ",ErrorDescription(err));
         }
      }
   }
   else 
   {
      for(retry=1;retry<=number_retry_open_trade;retry++)
      {
         RefreshRates();
         ticket=OrderSend(curr,cmd,lot,price,slippage,sl,tp,comm,magic_number,0,colour);   
         if(ticket>0) break;  
         else {
            err=GetLastError();
            strerr=IntegerToString(err);
            Print("OrderSend Error # " + strerr + " : ",ErrorDescription(err));
         }
      }
   }
         
   if(ticket>0)
   {
      if(Digits==3 || Digits==5)
      {
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
            for(retry=1;retry<=number_retry_open_trade;retry++)
            {
               if(ModifyProfitTarget(ticket, tp, sl))
               break;
            }
      }
      TradeBarTime=Time[0];
      return(ticket);
   }
   return(0);
}


void DrawTL(string sName, double dPrice1, datetime dtTime1,  double dPrice2, datetime dtTime2, color cLineClr=CLR_NONE, int style=STYLE_SOLID, int size=2)
{
    string sObjName = sName;

    if(ObjectFind(sObjName) == -1){
        // create object 
        ObjectCreate(sObjName,OBJ_TREND, 0, 0,0,0,0);
    }

    ObjectSet(sObjName,OBJPROP_PRICE1,dPrice1);
    ObjectSet(sObjName,OBJPROP_TIME1,dtTime1);
    ObjectSet(sObjName,OBJPROP_PRICE2,dPrice2);
    ObjectSet(sObjName,OBJPROP_TIME2,dtTime2);
    ObjectSet(sObjName, OBJPROP_COLOR, cLineClr);
    ObjectSet(sObjName, OBJPROP_WIDTH, size);
    ObjectSet(sObjName,OBJPROP_STYLE,style);
    ObjectSet(sObjName,OBJPROP_RAY,false);
}

void DrawLine(string sName, double dPrice,color cLineClr=CLR_NONE, int iWidth=1)
{
    string sObjName = sName;

    if(ObjectFind(sObjName) == -1){
        // create object 
        ObjectCreate(sObjName,OBJ_HLINE, 0, 0,0);
    }

    ObjectSet(sObjName,OBJPROP_PRICE1,dPrice);
    ObjectSet(sObjName, OBJPROP_COLOR, cLineClr);
    ObjectSet(sObjName, OBJPROP_WIDTH, iWidth);
}



double GetHLineValue(string name)
{

   if (ObjectFind(name) == -1)
      return(-1);
   else
      return(ObjectGet(name,OBJPROP_PRICE1));
}

double GetRectPrice(string name, ENUM_OBJECT_PROPERTY_DOUBLE type)
{
   if (ObjectFind(name) == -1)
      return(-1);
   else
      return(ObjectGet(name,type));
}


double GetRectTime(string name, ENUM_OBJECT_PROPERTY_INTEGER type)
{
   if (ObjectFind(name) == -1)
      return(-1);
   else
      return(ObjectGet(name,type));
}


string strtf(int tf)
{
   switch(tf)
   {
      case PERIOD_M1: return("M1");
      case PERIOD_M5: return("M5");
      case PERIOD_M15: return("M15");
      case PERIOD_M30: return("M30");
      case PERIOD_H1: return("H1");
      case PERIOD_H4: return("H4");
      case PERIOD_D1: return("D1");
      case PERIOD_W1: return("W1");
      case PERIOD_MN1: return("MN1");
      default:return("Unknown timeframe");
   }
}

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
