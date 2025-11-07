//+------------------------------------------------------------------+
//| EURUSD_Data_Extractor.mq5                                       |
//| Export EURUSD price bars, ticks, and trades to CSV (2020-2025)  |
//| Copyright 2025, AI Trader Analytics                             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AI Trader Analytics"
#property link      "https://www.mql5.com"
#property version   "2.01"
#property script_show_inputs

//--- Inputs
input string           InSymbol      = "EURUSD";          // Symbol to export
input ENUM_TIMEFRAMES  InTimeframe   = PERIOD_M1;         // Timeframe for bars
input datetime         FromDate      = D'2020.01.01 00:00';
input datetime         ToDate        = D'2025.12.31 23:59';
input bool             ExportBars    = true;              // Export OHLC bars
input bool             ExportTicks   = false;             // Export tick data
input bool             ExportDeals   = false;             // Export trade history (deals)

input string           BarsCsvName   = "EURUSD_BARS_2020_2025.csv";
input string           TicksCsvName  = "EURUSD_TICKS_2020_2025.csv";
input string           DealsCsvName  = "EURUSD_DEALS_2020_2025.csv";

//--- Helpers
int  digits = 5;
string data_path = TerminalInfoString(TERMINAL_DATA_PATH);
string files_dir = data_path + "\\MQL5\\Files\\"; // where FileOpen() saves by default

//+------------------------------------------------------------------+
//| Script start                                                     |
//+------------------------------------------------------------------+
void OnStart()
{
   // Ensure symbol is selected/available
   if(!SymbolSelect(InSymbol,true))
   {
      Print("[ERROR] Cannot select symbol ", InSymbol);
      return;
   }
   digits = (int)SymbolInfoInteger(InSymbol, SYMBOL_DIGITS);

   PrintFormat("[INFO] Exporting data for %s from %s to %s", InSymbol, TimeToString(FromDate, TIME_DATE|TIME_SECONDS), TimeToString(ToDate, TIME_DATE|TIME_SECONDS));
   Print("[INFO] Output folder: ", files_dir);

   int total_written_bars  = 0;
   int total_written_ticks = 0;
   int total_written_deals = 0;

   if(ExportBars)
      total_written_bars = ExportBarsCsv(InSymbol, InTimeframe, FromDate, ToDate, BarsCsvName);

   if(ExportTicks)
      total_written_ticks = ExportTicksCsv(InSymbol, FromDate, ToDate, TicksCsvName);

   if(ExportDeals)
      total_written_deals = ExportDealsCsv(InSymbol, FromDate, ToDate, DealsCsvName);

   PrintFormat("[DONE] Bars: %d, Ticks: %d, Deals: %d", total_written_bars, total_written_ticks, total_written_deals);
   Print("[HINT] Find the CSV files in: ", files_dir);
}

//+------------------------------------------------------------------+
//| Export OHLC bars using CopyRates                                 |
//+------------------------------------------------------------------+
int ExportBarsCsv(string symbol, ENUM_TIMEFRAMES tf, datetime from_dt, datetime to_dt, string out_name)
{
   MqlRates rates[];
   int copied = CopyRates(symbol, tf, from_dt, to_dt, rates);
   if(copied <= 0)
   {
      Print("[WARN] CopyRates returned ", copied, ". Trying to pre-load history...");
      // Preload series by requesting Bars()
      int bars_preload = Bars(symbol, tf);
      PrintFormat("[INFO] Preloaded bars count: %d", bars_preload);
      // try again
      copied = CopyRates(symbol, tf, from_dt, to_dt, rates);
      if(copied <= 0)
      {
         Print("[ERROR] No bar data available for ", symbol, " ", TFToString(tf), " in the selected range.");
         return 0;
      }
   }

   int fh = FileOpen(out_name, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(fh == INVALID_HANDLE)
   {
      Print("[ERROR] Cannot create output file: ", out_name);
      return 0;
   }

   // Header
   FileWrite(fh, "Date","Time","Open","High","Low","Close","TickVolume","Spread","RealVolume");

   for(int i=0;i<copied;i++)
   {
      string date_str = TimeToString(rates[i].time, TIME_DATE);
      string time_str = TimeToString(rates[i].time, TIME_MINUTES);
      FileWrite(fh,
         date_str,
         time_str,
         DoubleToString(rates[i].open,  digits),
         DoubleToString(rates[i].high,  digits),
         DoubleToString(rates[i].low,   digits),
         DoubleToString(rates[i].close, digits),
         IntegerToString((int)rates[i].tick_volume),
         IntegerToString((int)rates[i].spread),
         IntegerToString((int)rates[i].real_volume)
      );
   }
   FileClose(fh);
   PrintFormat("[OK] Bars exported: %d -> %s%s", copied, files_dir, out_name);
   return copied;
}

//+------------------------------------------------------------------+
//| Export tick data using CopyTicksRange                            |
//+------------------------------------------------------------------+
int ExportTicksCsv(string symbol, datetime from_dt, datetime to_dt, string out_name)
{
   MqlTick ticks[];
   // CopyTicksRange expects time in milliseconds (ulong), convert from datetime seconds
   ulong from_msc = (ulong)from_dt * 1000;
   ulong to_msc   = (ulong)to_dt   * 1000;
   int copied = CopyTicksRange(symbol, ticks, from_msc, to_msc, COPY_TICKS_ALL);
   if(copied <= 0)
   {
      Print("[ERROR] No tick data available for ", symbol, " in the selected range.");
      return 0;
   }

   int fh = FileOpen(out_name, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(fh == INVALID_HANDLE)
   {
      Print("[ERROR] Cannot create tick output file: ", out_name);
      return 0;
   }

   // Header
   FileWrite(fh, "Date","Time","Time_msc","Bid","Ask","Last","Volume","Flags");

   for(int i=0;i<copied;i++)
   {
      string date_str = TimeToString(ticks[i].time, TIME_DATE);
      string time_str = TimeToString(ticks[i].time, TIME_SECONDS);
      // cast time_msc to long for IntegerToString compatibility
      long tmsc = (long)ticks[i].time_msc;
      FileWrite(fh,
         date_str,
         time_str,
         IntegerToString(tmsc),
         DoubleToString(ticks[i].bid,  digits),
         DoubleToString(ticks[i].ask,  digits),
         DoubleToString(ticks[i].last, digits),
         IntegerToString((int)ticks[i].volume),
         IntegerToString((int)ticks[i].flags)
      );
   }
   FileClose(fh);
   PrintFormat("[OK] Ticks exported: %d -> %s%s", copied, files_dir, out_name);
   return copied;
}

//+------------------------------------------------------------------+
//| Export trade history (deals) for the symbol                      |
//+------------------------------------------------------------------+
int ExportDealsCsv(string symbol, datetime from_dt, datetime to_dt, string out_name)
{
   if(!HistorySelect(from_dt, to_dt))
   {
      Print("[ERROR] HistorySelect failed.");
      return 0;
   }
   int total = (int)HistoryDealsTotal();
   if(total <= 0)
   {
      Print("[WARN] No deals in the selected range.");
      return 0;
   }

   int fh = FileOpen(out_name, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(fh == INVALID_HANDLE)
   {
      Print("[ERROR] Cannot create deals output file: ", out_name);
      return 0;
   }

   // Header
   FileWrite(fh, "Ticket","Order","Date","Time","Type","Entry","Lots","Price","Profit","Commission","Swap","Symbol");

   int written = 0;
   for(int i=0; i<total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;

      string d_symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
      if(d_symbol != symbol) continue;

      datetime dt   = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      int      type = (int)HistoryDealGetInteger(ticket, DEAL_TYPE);
      int      entry= (int)HistoryDealGetInteger(ticket, DEAL_ENTRY);
      double   lots = HistoryDealGetDouble(ticket,  DEAL_VOLUME);
      double   price= HistoryDealGetDouble(ticket,  DEAL_PRICE);
      double   profit=HistoryDealGetDouble(ticket,  DEAL_PROFIT);
      double   comm  = HistoryDealGetDouble(ticket,  DEAL_COMMISSION);
      double   swap  = HistoryDealGetDouble(ticket,  DEAL_SWAP);
      ulong    order = (ulong)HistoryDealGetInteger(ticket, DEAL_ORDER);

      string date_str = TimeToString(dt, TIME_DATE);
      string time_str = TimeToString(dt, TIME_SECONDS);

      FileWrite(fh,
         IntegerToString((int)ticket),
         IntegerToString((int)order),
         date_str,
         time_str,
         IntegerToString(type),
         IntegerToString(entry),
         DoubleToString(lots, 2),
         DoubleToString(price, digits),
         DoubleToString(profit, 2),
         DoubleToString(comm, 2),
         DoubleToString(swap, 2),
         d_symbol
      );
      written++;
   }
   FileClose(fh);
   PrintFormat("[OK] Deals exported: %d -> %s%s", written, files_dir, out_name);
   return written;
}

//+------------------------------------------------------------------+
//| Utility: timeframe to string (avoid built-in name conflicts)     |
//+------------------------------------------------------------------+
string TFToString(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M2:  return "M2";
      case PERIOD_M3:  return "M3";
      case PERIOD_M4:  return "M4";
      case PERIOD_M5:  return "M5";
      case PERIOD_M6:  return "M6";
      case PERIOD_M10: return "M10";
      case PERIOD_M12: return "M12";
      case PERIOD_M15: return "M15";
      case PERIOD_M20: return "M20";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H2:  return "H2";
      case PERIOD_H3:  return "H3";
      case PERIOD_H4:  return "H4";
      case PERIOD_H6:  return "H6";
      case PERIOD_H8:  return "H8";
      case PERIOD_H12: return "H12";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
      default:         return "TF";
   }
}
//+------------------------------------------------------------------+