import root;
import pad_layout;

// draw the histogram by line
NewPad();
draw(rGetObj("../example.root", "hist"), "", blue);

// add error bars
NewPad();
draw(rGetObj("../example.root", "hist"), "eb", blue);

// add error bars
NewPad();
draw(rGetObj("../example.root", "hist"), "ec", blue);

// set opacity of the error contour
NewPad();
TH1_errorContourOpacity = 0.05;
draw(rGetObj("../example.root", "hist"), "ec", blue);

NewRow();

// draw the histogram normalized to the integral/sum of 1.
NewPad();
draw(rGetObj("../example.root", "hist"), "n", red);

NewRow();

// x-range control
NewPad();
TH1_lowLimit = -1;
TH1_highLimit = +1;
draw(rGetObj("../example.root", "hist"), "", magenta);
limits((-5, 0), (5, 60));

// force plotting front and back edges (they are drawn from y value of TH1_def_val)
NewPad();
TH1_def_val = 10;
draw(rGetObj("../example.root", "hist"), "e", magenta);
limits((-5, 0), (5, 60));

// reset x-range control
TH1_lowLimit = -inf; TH1_highLimit = +inf;

// empty/negative bin control in log scale: these bins are assigned value of TH1_def_val (after scaling)
NewPad();
scale(Linear, Log);
TH1_def_val = -5;
draw(rGetObj("../example.root", "hist"), "e", magenta);


NewRow();

// add basic characteristics to the legend
NewPad();
draw(rGetObj("../example.root", "hist"), "lE,lM,lR", heavygreen);
AttachLegend();

// or an abbreviation
NewPad();
draw(rGetObj("../example.root", "hist"), "l", heavygreen);
AttachLegend();
