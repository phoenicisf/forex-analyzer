//+------------------------------------------------------------------+
//| Inputs_Slot_J.mqh — Slot J input parameters (IMPL-022)           |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_J = 206 (own; not shared)                          |
//| Source:  CodeWiki §3.J (J = follower trade after CD chain);       |
//|          BR-7.2 (⚠️ G4 fix: ExtraTakeProfit_J iterates MagicJ      |
//|          NOT MagicF — original CodeWiki bug); ADR-002              |
//|                                                                   |
//| Slot J role (CD-follower per CodeWiki §3.J):                      |
//|   - Follower trade triggered after a CD entry; topo dep MAGIC_CD  |
//|   - Comment prefix "J," for order disambiguation (own magic       |
//|     MAGIC_J=206 — no shared-magic ambiguity, but CommentParser    |
//|     used uniformly for journal forensic)                          |
//|   - G4 critical fix: ManageExits queries MAGIC_J (own magic) —    |
//|     original `ExtraTakeProfit_J` iterated MagicF (=201) and J     |
//|     orders never had take-profit set; see BR-7.2 + ADR-009 family |
//|                                                                   |
//| ⚠️ Bucket B (intentional behavioral change vs baseline) —         |
//|   NFR-1.8 G4 acceptance budget separate from Bucket A NFR-1.1.    |
//|   See impl-plan IMPL-063 (P4 G4-fixes-on regression run).         |
//|                                                                   |
//| M-size MVP — header-only contract scaffold                        |
//|   Real activation: <closed; ref purged fix-round-18 §18.1> (CrossSlotCoordinator wires CD-open  |
//|   → J follower entry). Phase 1 Evaluate early-returns.            |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_J_MQH
#define PHOENICISNEX_INPUTS_SLOT_J_MQH

input group "Slot J"
input bool   InpEnableSlotJ        = true;    // Enable Slot J (CD-follower per CodeWiki §3.J + G4 fix BR-7.2)
input int    InpJMaxOrders         = 1;       // Max simultaneous J orders (comment-prefix "J,")
input double InpJSlPipsFloor       = 50.0;    // SL floor in pips for J entries (mirrors C/F tier)
input double InpJTpProfitPips      = 40.0;    // Minimum profit gate for exit in pips (G4 fix surface)

#endif // PHOENICISNEX_INPUTS_SLOT_J_MQH
