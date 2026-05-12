//+------------------------------------------------------------------+
//|                                              SR_Visual_Lines.mq4 |
//|                                   Copyright 2026, Lucas Vinicius |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Lucas Vinicius"
#property link      "https://www.mql5.com"
#property version   "1.10"
#property strict

//--- Parâmetros de Entrada
input int      Periodo_SR  = 10;     
input double   Lotes       = 1;    
input int      StopLoss    = 20;    
input int      TakeProfit  = 100;    
input int      MagicNumber = 888111; 
input double   DistToque = 10;

//--- Variáveis Globais
double suporte;
double resistencia;
double askant = 0; 
double bidant = 0; 


string Objname ="";
int Borda = 50; //em pips!!!
double  BordaSR = Borda  * Point;

bool NovoSR = false;
double MomentoRompimento = 0.0;
//+------------------------------------------------------------------+
//| Função de Inicialização - Criamos os objetos de linha aqui       |
//+------------------------------------------------------------------+
int OnInit()
{
   suporte = Low[iLowest(NULL, 0, MODE_LOW, Periodo_SR, 1)];
   resistencia = High[iHighest(NULL, 0, MODE_HIGH, Periodo_SR, 1)];
 
   Objname = "LinhaResistencia";
   ObjectCreate(0, Objname, OBJ_HLINE, 0, 0, resistencia);
   ObjectSetInteger(0, Objname, OBJPROP_COLOR, clrDodgerBlue);
   ObjectSetInteger(0, Objname, OBJPROP_WIDTH, 2);

   Objname ="LinhaSuporte";
   ObjectCreate(0, Objname, OBJ_HLINE, 0, 0, suporte);
   ObjectSetInteger(0, Objname, OBJPROP_COLOR, clrTomato);
   ObjectSetInteger(0, Objname, OBJPROP_WIDTH, 2);
   
   
   
   
   Objname = "BordaResistencia";
   ObjectCreate(0, Objname, OBJ_HLINE, 0, 0, resistencia - BordaSR);
   ObjectSetInteger(0, Objname, OBJPROP_COLOR, clrLightBlue);
   ObjectSetInteger(0, Objname, OBJPROP_WIDTH, 2);

   Objname ="BordaSuporte";
   ObjectCreate(0, Objname, OBJ_HLINE, 0, 0, suporte + BordaSR);
   ObjectSetInteger(0, Objname, OBJPROP_COLOR, clrPink);
   ObjectSetInteger(0, Objname, OBJPROP_WIDTH, 2);
   
   
   

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Função de Deinicialização - Remove as linhas ao parar o robô     |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectDelete(0, "LinhaResistencia");
   ObjectDelete(0, "LinhaSuporte");
}

//+------------------------------------------------------------------+
//| Função Principal                                                 |
//+------------------------------------------------------------------+
void OnTick(){
     if (!NovoSR){
         VerificaRompimento(suporte, resistencia); // Se houve ropimento do Suporte ou da Resistencia.
         VerificaOperacao();//se é para vender ou para comprar.
     }else{
         if(((Time[0] - MomentoRompimento)>(PeriodSeconds(_Period) * 11))){
            DesenharSR();
            NovoSR = false;
         }
     }
}
void VerificaOperacao(){
    if(OrdersTotal() > 0){
         if(OrderSelect(0, SELECT_BY_POS, MODE_TRADES)){ // Seleciona a primeira ordem aberta
           if(OrderType() == OP_BUY){ // Se for uma compra
               if(Ask > askant && askant > 0){
                  double novoSL = Ask - (StopLoss * Point);
                  if(novoSL > OrderStopLoss()){
                     bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), novoSL, OrderTakeProfit(), 0, clrGreen);
                     if(!mod) Print("Erro ao modificar SL: ", GetLastError());
                  }
               }
               askant = Ask; // Atualiza o preço anterior
            }
            if(OrderType() == OP_SELL){ 
                  if(Bid < bidant && bidant > 0){
                     double novoSL = Bid + (StopLoss * Point);
                     if(OrderStopLoss() == 0 || novoSL < OrderStopLoss()){
                        bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), novoSL, OrderTakeProfit(), 0, clrRed);
                        if(!mod) 
                           Print("Erro ao modificar SL de Venda: ", GetLastError());
                        else
                           Print("SL de Venda movido para: ", novoSL);
                     }
                  }
                  bidant = Bid; // Atualiza o rastro do preço
               }
        }
     }else{
         if( Bid > resistencia - BordaSR){
            double sl = (StopLoss > 0) ? (Bid + StopLoss * Point) : 0;
            double tp = (TakeProfit > 0) ? (Bid - TakeProfit * Point) : 0;
            int ticket = OrderSend(Symbol(), OP_SELL, Lotes, Bid, 3, sl, tp, "Venda SR", MagicNumber, 0, clrRed);
         }
         if(Bid < (suporte + BordaSR)){
            double sl = (StopLoss > 0) ? (Ask - StopLoss * Point) : 0;
            double tp = (TakeProfit > 0) ? (Ask + TakeProfit * Point) : 0;
            int ticket = OrderSend(Symbol(), OP_BUY, Lotes, Ask, 3, sl, tp, "Compra SR", MagicNumber, 0, clrBlue);
         }
     }

}


void VerificaRompimento(double S, double R){
     if ((Bid > R)||(Bid < S)){
         NovoSR = true;
         MomentoRompimento = Time[0];
         RemoverLinhasSR();
     }
}
void DesenharSR(){
      suporte     = Low[iLowest(NULL, 0, MODE_LOW, Periodo_SR, 1)];
      resistencia = High[iHighest(NULL, 0, MODE_HIGH, Periodo_SR, 1)];
      //-------------------------------------------------------------
      Objname = "LinhaSuporte";
      ObjectMove(0, Objname, 0, 0, suporte);
      Objname = "BordaSuporte";
      ObjectMove(0, Objname, 0, 0, suporte + BordaSR);
      
      
      //-------------------------------------------------------------
      Objname = "LinhaResistencia";
      ObjectMove(0, Objname, 0, 0, resistencia);
      Objname = "BordaResistencia";
      ObjectMove(0, Objname, 0, 0, resistencia - BordaSR);
}

void RemoverLinhasSR(){
      Objname = "LinhaSuporte";
      ObjectMove(0, Objname, 0, 0, 0);
      Objname = "BordaSuporte";
      ObjectMove(0, Objname, 0, 0, 0);
      
      
      //-------------------------------------------------------------
      Objname = "LinhaResistencia";
      ObjectMove(0, Objname, 0, 0, 0);
      Objname = "BordaResistencia";
      ObjectMove(0, Objname, 0, 0, 0);
}
