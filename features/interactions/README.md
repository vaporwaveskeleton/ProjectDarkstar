# features/interactions

Shrines, Chalk Desk, Sepulchre deposit interactions (layer 'interactables'). Owner docs: GDD §6.4, LOOP-001 §7, §10.5.

Built (2026-11-19): the Ruins visit as diegetic onboarding (LOOP-001 §10.5; TECH-001 §2.9).
- `RuinsOnboarding`: the pure rules of a Ruins visit (chalk, payout, stations, dark-mouth gate, lamp-down reveal, launch). No nodes; `scenes/ruins/ruins.gd` drives it.
- `RuinsOnboardingStats` (`ds_ruins.onboarding.*`, `data/interactions/ruins_onboarding.tres`): pacing and layout, all ✱.
- Lit visuals mirrored into `RuinsLook.stage`: `PilotLamp`, `StationMark`, `TicketFlight`.
- Tests: `tests/test_ruins_onboarding.gd`; the scene test is `scenes/tests/test_ruins_scene.gd`; scenario `tests/scenarios/ruins_onboarding_first_visit.scenario.json`.
