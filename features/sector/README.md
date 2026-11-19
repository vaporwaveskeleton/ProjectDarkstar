# features/sector

SeamAssembler / KitAssembly / anchors (TECH-001 §2.2–§2.3), and the sector camera (TECH-001 §2.5). Owner docs: ZONES-001 §1.7, §4; camera numbers SYS-001 §9. The bootstrap stub lives in scenes/sector/.

Status: camera built (M1 slice 3 PR 1): `sector_camera.gd` (`SectorCamera`, a `Camera2D` stepped in the physics tick) and `sector_camera_stats.gd` (`SectorCameraStats`, data in `data/sector/sector_camera.tres`, `ds_camera.*`, TECH-001 §3.4). Torus sandbox (Q-T58): `sector_wrap.gd` (`SectorWrap`, wraps the Vigil after its physics step and keeps other actors on the image nearest it), `sector_floor.gd` (`SectorFloor`, a repeating `Pal` grid over the whole view) with `sector_floor_style.gd` (`SectorFloorStyle`, data in `data/sector/sector_floor.tres`, ✱ visual values); the camera follows by `Torus.delta` and rebases at the seam. Tests in `tests/`. SeamAssembler, KitAssembly and anchors are not built. Follow docs/04-production/ADDING_A_FEATURE.md before adding code.
