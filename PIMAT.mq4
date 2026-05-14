//+------------------------------------------------------------------+
//|                                                    AutoTrail.mq4 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//Extern Parametres expressed by pips (integer)! E.g., 20 pips = 0.00020(EUR/USD) pips
extern double ExPaStopLoss   = 20.0;
extern double ExPaTakeProfit = 10.0;
extern double ExPaTargetProfit = 100.0; // The fixed and target profit for any order!
extern double ExPaFeesCharged  = 7.0;   // Fees Charged by the brokerage firm
extern double ExPaProfitGap = 5.0;      // Distance, in pips, from the desired profit to allow for fluctuations and maximize gain.

int    MagicNumber = 566654156;
double MarketValues[2];
struct OrderData {
       int    ticket;
       double OpenPrice;
       double stopLoss;
       double takeProfit;
       double LastProtectionValue;
       double GrantedProfit;
}; 
OrderData SystemOrders[100];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ExPaStopLoss   = ExPaStopLoss * Point;
   ExPaTakeProfit  = ExPaTakeProfit * Point;
   ExPaTargetProfit = ExPaTargetProfit * Point;
   ExPaFeesCharged  = ExPaFeesCharged * Point;
   ExPaProfitGap    = ExPaProfitGap * Point;
   //---------------------------------------
   
   int ticket = OrderSend(Symbol(), OP_SELL, 1, Bid, 3, 0, 0, "Venda", MagicNumber, 0, clrRed);
   SystemOrders[0].ticket = ticket;
   SystemOrders[0].OpenPrice = OrderOpenPrice();
   SystemOrders[0].stopLoss = OrderOpenPrice() + ExPaStopLoss;
   SystemOrders[0].takeProfit = OrderOpenPrice() - ExPaTakeProfit;
   SystemOrders[0].LastProtectionValue = Bid;
   
   /*
   int ticket = OrderSend(Symbol(), OP_BUY, 1, Ask, 3, 0, 0, "Compra", MagicNumber, 0, clrBlue);
   SystemOrders[0].ticket = ticket;
   SystemOrders[0].OpenPrice = OrderOpenPrice();
   SystemOrders[0].stopLoss = OrderOpenPrice() - ExPaStopLoss;
   SystemOrders[0].takeProfit = OrderOpenPrice() + ExPaTakeProfit;
   SystemOrders[0].LastProtectionValue = Ask;
   */
   
   DrawProtectionLines(SystemOrders[0]);     
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
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
     MarketValues[0]=Ask;
     MarketValues[1]=Bid;
     AutoTrailMonitor(0,1); //Compra precisa de tipo 0, venda, tipo =1 
  }
//+------------------------------------------------------------------+

double AutoTrailMonitor(int Indice, int T){//T= TIpo da Ordem
       int TotalOrders  = OrdersTotal();
       Print("TAKEPROFIT(ORIGINAL):",SystemOrders[0].takeProfit); 
       for(int icount=0;icount < TotalOrders;icount++){
           if(OrderSelect(icount, SELECT_BY_POS, MODE_TRADES)){
              if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber){
                 //-----------------------------------------------------
                 bool Cond0 = ((1-(2*T))*(MarketValues[1-T] - SystemOrders[Indice].OpenPrice) - ExPaTargetProfit <= 0);
                 if(Cond0){ // Do not achieve the maximum target profit defined!
                      bool Cond1 = ((1-(2*T))*(MarketValues[1-T] - SystemOrders[Indice].stopLoss) <= 0);
                      if (Cond1){ //The actual gain is lower then the stoploss point. CLOSE ORDER!!!! 
                          OrderClose(SystemOrders[Indice].ticket, OrderLots(), OrderClosePrice(), 3, clrRed);
                      }
                      //-------------------------------------------------------------
                      bool Cond2 = (((1-(2*T))*(MarketValues[1-T] - SystemOrders[Indice].OpenPrice))>0); 
                      // Tests whether the order is generating profit.
                      bool Cond3 = (((1-(2*T))*(MarketValues[1-T] - SystemOrders[Indice].LastProtectionValue))>0);
                      // Check if the current price point has already been protected by a stop-loss order.
                      //-------------------------------------------------------------
                      if (Cond2&&Cond3){//Update the StopLoss protection line.
                          SystemOrders[Indice].LastProtectionValue = MarketValues[1-T];
                          SystemOrders[Indice].stopLoss  = (double)(MarketValues[1-T]-((1-2*T)*ExPaStopLoss));
                      }
                    //---------------------------------------------------------------------------------------------
                      bool Cond4 = ((1-(2*T))*(MarketValues[1-T] - SystemOrders[Indice].takeProfit))>0; //Tests whether tp line is crossed
                      if (Cond4){//Update the TakeProfit and StopLoss protection line.
                          SystemOrders[Indice].LastProtectionValue = MarketValues[1-T];
                          SystemOrders[Indice].stopLoss  = (double)(MarketValues[1-T]);
                          SystemOrders[Indice].takeProfit = (double) MathAbs((MarketValues[1-T]+((1-2*T)*((200.0 * Point)))));
                          Print("TAKEPROFIT:",SystemOrders[Indice].takeProfit);
                      }
                      
                      
                     

                      //-------------------------------------------------------------------------------------
                      DrawProtectionLines(SystemOrders[Indice]);
                  }else{ // fechando ordem com lucro maximo 
                        OrderClose(SystemOrders[Indice].ticket, OrderLots(), OrderClosePrice(), 3, clrGreen);     
                  }
              }
           }
       } 
   return 0.0;
 }

void DrawProtectionLines(const OrderData &O){
   string Objname = "TakeProfitLine_" + (string)O.ticket;
   if(ObjectFind(0, Objname) < 0){
      ObjectCreate(0, Objname, OBJ_HLINE, 0, 0, O.takeProfit);
      ObjectSetInteger(0, Objname, OBJPROP_COLOR, clrDodgerBlue);
      ObjectSetInteger(0, Objname, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, Objname, OBJPROP_STYLE, STYLE_DOT);
   }
   else{
      ObjectMove(0, Objname, 0, 0, O.takeProfit);
   }
   Objname = "StopLossLine_"+ (string)O.ticket;
   if(ObjectFind(0, Objname) < 0){
      ObjectCreate(0, Objname, OBJ_HLINE, 0, 0, O.stopLoss);
      ObjectSetInteger(0, Objname, OBJPROP_COLOR, clrPink);
      ObjectSetInteger(0, Objname, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, Objname, OBJPROP_STYLE, STYLE_DOT);
   }
   else{
      ObjectMove(0, Objname, 0, 0, O.stopLoss);
   }


}