//+------------------------------------------------------------------+
//|                                                    Saudacoes.mq5 |
//|                                            Copyright 2025, Lucas |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Lucas"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#property script_show_inputs
input uint GreetingHour=0;//Digite as Horas (0~23)
void OnStart()
  {
//---
   Alert(Greeting(GreetingHour)+", "+Symbol());
  }
  string Greeting(uint horas){
         string saudacao[3]{"Bom dia", "Boa Tarde", "Boa Noite"};
         return saudacao[horas % 24 / 8];      
  }
//+------------------------------------------------------------------+
