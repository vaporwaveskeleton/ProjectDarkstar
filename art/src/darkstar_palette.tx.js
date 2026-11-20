// DARKSTAR palette for loom (ART-001 §4, §14.8a). File of record: core/ui/pal.gd (Pal) and
// assets/palettes/darkstar_palette.json; tests/test_generated_assets_only.gd checks these values match Pal.
// include("darkstar_palette.tx.js") at the top of every texture source and name colours by role only:
// no "#rrggbb" literals and no pal() call anywhere else (the test rejects both). ramp(), mix(), mul() and
// hsv() may derive in-between tones from these roles, the way lighting does in pxl (ART-001 §14.8a).
// AETHER-n are post-Pretence only (ART-001 §4, §15); never on the Act 0 screen.
pal({
  void0: "#0A0A12",    // VOID-0
  void1: "#131428",    // VOID-1
  void2: "#1D2040",    // VOID-2
  void3: "#2A3057",    // VOID-3
  void4: "#3C4574",    // VOID-4
  void5: "#56608F",    // VOID-5
  bone0: "#3A3B44",    // BONE-0
  bone1: "#5A5C67",    // BONE-1
  bone2: "#8A8C93",    // BONE-2
  bone3: "#B9B8AE",    // BONE-3
  bone4: "#E4DFD1",    // BONE-4
  bone5: "#F7F4E8",    // BONE-5
  choir0: "#2C1230",   // CHOIR-0
  choir1: "#4A1C4A",   // CHOIR-1
  choir2: "#6E2A64",   // CHOIR-2
  choir3: "#9A3E76",   // CHOIR-3
  choir4: "#C55A86",   // CHOIR-4
  choir5: "#EFA6B0",   // CHOIR-5
  phos0: "#0C2A2E",    // PHOS-0
  phos1: "#14514F",    // PHOS-1
  phos2: "#1E7C71",    // PHOS-2
  phos3: "#34A88F",    // PHOS-3
  phos4: "#62CFA8",    // PHOS-4
  phos5: "#A8F0D0",    // PHOS-5
  gas0: "#3A2410",     // GAS-0
  gas1: "#6B4415",     // GAS-1
  gas2: "#A8701F",     // GAS-2
  gas3: "#D99A2E",     // GAS-3
  gas4: "#F2C65C",     // GAS-4
  gas5: "#FFEFC0",     // GAS-5
  null: "#000000",     // NULL
  signal: "#FF4A57",   // SIGNAL
  aether0: "#2A2160",  // AETHER-0
  aether1: "#463490",  // AETHER-1
  aether2: "#6F5BB8",  // AETHER-2
  aether3: "#968ED2",  // AETHER-3
  aether4: "#E8DCD8",  // AETHER-4
  aether5: "#80C4D0",  // AETHER-5
})
