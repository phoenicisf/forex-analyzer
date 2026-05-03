//+------------------------------------------------------------------+
//| Inputs_Slot_LX.mqh — per-slot input declarations for Slot LX     |
//| Layer:  inputs/ (no service deps — pure input declarations)       |
//| Slot:   LX — Magic 211 (MAGIC_L per domain/EnumTypes.mqh)         |
//|         MAGIC_L shared with L (IMPL-030) — comment disambig "LX," |
//| Source: CodeWiki §3.L (pyramid variant); TD-02 §5.4; NFR-6.3      |
//|                                                                  |
//| MVP scope (IMPL-031):                                             |
//|   1. Pyramid gate: L parent position profitable >= InpLXPyramidGatePips|
//|   2. Own-no-active guard: LX active count < InpLXMaxOrders         |
//|   3. Direction inheritance: same direction as profitable L parent  |
//|   4. Profit gate exit: InpLXTpProfitPips                           |
//|                                                                  |
//| P4 deferred (IMPL-062):                                          |
//|   - Advanced pyramid scaling conditions                            |
//|   - Multi-level pyramid (> 1 add-on layer)                        |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_LX_MQH
#define PHOENICISNEX_INPUTS_SLOT_LX_MQH

input group "Slot LX"
input bool   InpEnableSlotLX           = true;    // Enable Slot LX (pyramid on profitable L)
input int    InpLXMaxOrders            = 1;       // Max simultaneous LX pyramid orders (comment disambig "LX,")
input double InpLXBaseLot              = 15.0;    // Base lot multiplier factor (lighter than parent L's 20.0)
input double InpLXSlPips               = 60.0;    // Stop-loss in pips for pyramid order
input double InpLXTpProfitPips         = 25.0;    // Minimum profit gate for LX exit in pips
input double InpLXPyramidGatePips      = 30.0;    // Parent L profit threshold (pips) to trigger pyramid entry

#endif // PHOENICISNEX_INPUTS_SLOT_LX_MQH
