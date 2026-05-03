//+------------------------------------------------------------------+
//| Inputs_Slot_D.mqh — Slot D input parameters (IMPL-020)           |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_CD = 200 (shared with Slot C — D wraps C)          |
//| Source:  CodeWiki §3.2 Slot D; BR-2.1; ADR-002                    |
//|                                                                   |
//| NOTE: Slot D is a 4-line wrapper of Slot C's force-pending        |
//|       workflow (BR-2.1). It shares MAGIC_CD with C; comment       |
//|       prefix "D," disambiguates D's tickets from C's "C,".        |
//|                                                                   |
//|       Force-pending timeout (`InpLegacyForceBars`) lives in       |
//|       Inputs_Pending.mqh (BR-6.8). DO NOT redeclare here.         |
//|                                                                   |
//|       Lot/SL inputs reuse Slot C's `InpC*` from Inputs_Slot_C.mqh |
//|       — D opens with `2 * gLot * 0.7` per CodeWiki §3.2 trigger;   |
//|       enable flag below gates the wrapper independently.          |
//|                                                                   |
//| Phase 1 MVP — header-only contract scaffold:                      |
//|   Real ForcePendingActionOrder + ForceDivergentWorking helpers    |
//|   deferred to P4 IMPL-062 (paired with C's advanced filters).     |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_D_MQH
#define PHOENICISNEX_INPUTS_SLOT_D_MQH

input group "Slot D"
input bool   InpEnableSlotD          = true;    // Enable Slot D (4-line wrapper of C's force-pending workflow)
input double InpDLotMultiplier       = 1.4;     // Lot multiplier vs C base (CodeWiki §3.2 — 2 * gLot * 0.7)

#endif // PHOENICISNEX_INPUTS_SLOT_D_MQH
