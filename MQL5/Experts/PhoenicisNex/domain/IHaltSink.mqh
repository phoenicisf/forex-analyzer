//+------------------------------------------------------------------+
//| domain/IHaltSink.mqh — abstract halt-trigger sink                 |
//| Layer:   domain/ (pure interface; no service deps)                |
//| Purpose: break circular include between CTradeJournal (services/) |
//|          and CEAState (core/). CEAState implements IHaltSink;     |
//|          CTradeJournal holds IHaltSink* and invokes Halt() on     |
//|          sustained-write-failure threshold (ADR-006 RPO escalation|
//|          + Finding 03.6).                                          |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_DOMAIN_IHALTSINK_MQH
#define PHOENICISNEX_DOMAIN_IHALTSINK_MQH

class IHaltSink
  {
public:
   virtual void Halt(string reason) = 0;
  };

#endif // PHOENICISNEX_DOMAIN_IHALTSINK_MQH
