//+------------------------------------------------------------------+
//| Inputs_Logging.mqh — logger configuration inputs (ADR-011)        |
//| TD-02 line 1623 CLogger::Init params; NFR-6.3 group annotation    |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_LOGGING_MQH
#define PHOENICISNEX_INPUTS_LOGGING_MQH

input group "Logging"
input int  InpLogLevel           = 1;     // ADR-011 default LOG_INFO — values: 0=DEBUG 1=INFO 2=WARN 3=ERROR — see domain/EnumTypes.mqh::ESeverity (IMPL-002)
input bool InpAlertOnError       = true;  // NFR-5.1 — trigger MT5 native Alert() popup on ERROR-level log
input int  InpErrorEscalationN   = 10;    // ADR-011 — N consecutive errors per slot tag before escalation Alert

#endif // PHOENICISNEX_INPUTS_LOGGING_MQH
