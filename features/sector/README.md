# features/sector

SeamAssembler / KitAssembly / anchors (TECH-001 §2.2–§2.3), and the sector camera (TECH-001 §2.5). Owner docs: ZONES-001 §1.7, §4; camera numbers SYS-001 §9. The bootstrap stub lives in scenes/sector/.

Status: camera built (M1 slice 3 PR 1): `sector_camera.gd` (`SectorCamera`, a `Camera2D` stepped in the physics tick) and `sector_camera_stats.gd` (`SectorCameraStats`, data in `data/sector/sector_camera.tres`, `ds_camera.*`, TECH-001 §3.4). Tests in `tests/`. SeamAssembler, KitAssembly and anchors are not built. Follow docs/04-production/ADDING_A_FEATURE.md before adding code.
