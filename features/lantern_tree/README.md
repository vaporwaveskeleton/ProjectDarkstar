# features/lantern_tree

The Lantern Tree upgrade tree. Owner docs: LOOP-001 §3 (handling readings: §3.8; the M2 stub: §3.8 "Built"), TECH-001 §2.9, Q-T325..Q-T335.

Status: the M2 30-node stub (20 tier-1 + 10 tier-2 nodes; the slice sells tier 1 only). Follow docs/04-production/ADDING_A_FEATURE.md before adding more.

- `lantern_tree_node.gd` `LanternTreeNode`: one node as content (id, branch, tier, text keys, hard `requires`, `codex_gate`, `wiring` NOOP/PARTIAL/WIRED + `stub_note`). No price: the tier gives it.
- `lantern_tree_data.gd` `LanternTreeData` (`ds_lantern_tree.tree`, `data/lantern_tree/m2_tree.tres`): the nodes, `price_tier2`, `price_codex_gated`, `tier2_gate`, `max_tier_on_sale`, `sell_unwired`; the tier-1 price is `stock.price_tier1` (#90's `tier1_stock.tres`, one source).
- `lantern_tree_rules.gd` `LanternTreeRules`: pure `state_of` / `can_buy` / `suggested` / `validate` / `has_cycle`.
- `lantern_tree_screen.gd/.tscn` `LanternTreeScreen`, `lantern_tree_confirm.gd/.tscn` `LanternTreeConfirm`: the station UI (Screens on the Ruins `ScreenStack`; no game state; `purchase_confirmed(id)` out). `tree_lantern.gd` `TreeLantern`: one lamp. `chalk_button.gd` `ChalkButton`: a VectorLabel button (Q-T333).
- `handling_node_effects.gd` `HandlingNodeEffects` (`ds_lantern_tree.handling`): per-node handling effects and `speed_bonus_cap`. `handling_tree.gd` `HandlingTree`: `apply(base, node_ids)`; `parse_args` reads `--tree=ID,ID`.
- `lantern_tree_stock.gd` `LanternTreeStock` (`ds_lantern_tree.stock`): the tier-1 price and #90's sale order (now the station's default focus).
- Purchase and state: `RunSessionCore.buy_tree_node_id` (profile `tree_nodes`, reason `tree_purchase`). Bought modules reach the Vigil through the sector (`Vigil.set_tree_nodes`).
- Not built: Codex stamping (gated nodes stay closed, Q-T327), tiers 3–5, respec, the hall's per-node lamps (Q-T332).
