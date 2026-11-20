# features/lantern_tree

The Lantern Tree upgrade tree. Owner docs: LOOP-001 §3 (handling readings: §3.8).

Status: handling readings only. Follow docs/04-production/ADDING_A_FEATURE.md before adding more.

- `handling_node_effects.gd` `HandlingNodeEffects` (`ds_lantern_tree.handling`, `data/lantern_tree/handling_node_effects.tres`): per-node handling effects and `speed_bonus_cap`.
- `handling_tree.gd` `HandlingTree`: `apply(base, node_ids)` returns a modified duplicate of the Aether stats (stacking rules are ✱, TECH-001 §11.2 2026-11-19); `parse_args` reads `--tree=ID,ID`.
- Not built: node purchase UI and state. Until then nodes come only from `--tree=`.
