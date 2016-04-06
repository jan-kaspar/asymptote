import root;
import pad_layout;

// bin content reflected by marker size
NewPad();
draw(RootGetObject("../example.root", "hist2"), "s", blue);

// add cell boundaries
NewPad();
TH2_boundaryPen = red;
draw(RootGetObject("../example.root", "hist2"), "s,b", blue);

NewRow();

// bin content reflected by cell color
NewPad(axesAbove=true);
TH2_palette = Gradient(white, blue, heavygreen, red, black);
draw(RootGetObject("../example.root", "hist2"), "p");

// add palette bar
NewPad(axesAbove=true);
draw(RootGetObject("../example.root", "hist2"), "p,bar");

// use logarithmic color scale (i.e. scale in z)
NewPad(axesAbove=true);
scale(Linear, Linear, Log);
draw(RootGetObject("../example.root", "hist2"), "p,bar");

// control palette bar position, size, ticks and lable
NewPad("$x$", "$y$", axesAbove=true);
TH2_paletteBarSpacing = 0.1;
TH2_paletteBarWidth = 0.05;
TH2_zLabel = "$z$";
TH2_paletteTicks = PaletteTicks(Step=20, step=10);
draw(RootGetObject("../example.root", "hist2"), "p,bar");

NewRow();

// z range selection
NewPad(axesAbove=true);
TH2_z_min = 50;
TH2_z_max = 100;
draw(RootGetObject("../example.root", "hist2"), "p,bar");

// disable z selection
TH2_z_min = 0;
TH2_z_max = -inf;
