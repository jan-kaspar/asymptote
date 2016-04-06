import root;
import pad_layout;

// draw the histogram
NewPad();
draw(rGetObj("../example.root", "hist"), "", blue);

// add vertical lines
NewPad();
draw(rGetObj("../example.root", "hist"), "vl", blue);

// add error bars
NewPad();
draw(rGetObj("../example.root", "hist"), "vl,eb", blue);

// add error bars
NewPad();
draw(rGetObj("../example.root", "hist"), "vl,ec", blue);

// set opacity of the error contour
NewPad();
TH1_errorContourOpacity = 0.05;
draw(rGetObj("../example.root", "hist"), "vl,ec", blue);

NewRow();

// draw the histogram normalized to the integral/sum of 1.
NewPad();
draw(rGetObj("../example.root", "hist"), "n", red);

NewRow();

// x-range control
NewPad();
TH1_x_min = -1;
TH1_x_max = +1;
draw(rGetObj("../example.root", "hist"), "vl", magenta);
limits((-5, 0), (5, 60));

// force plotting front and back edges (they are drawn from y value of TH1_y_def)
NewPad();
TH1_y_def = 10;
TH1_use_y_def = true;
draw(rGetObj("../example.root", "hist"), "vl", magenta);
limits((-5, 0), (5, 60));

// reset x-range control
TH1_x_min = -inf; TH1_x_max = +inf;

// empty/negative bin control in log scale: these bins are assigned value of TH1_y_def (after scaling)
NewPad();
scale(Linear, Log);
TH1_y_def = 0.1;
TH1_use_y_def = true;
draw(rGetObj("../example.root", "hist"), "vl", magenta);

NewRow();

// add basic characteristics to the legend
NewPad();
draw(rGetObj("../example.root", "hist"), "vl,lE,lM,lR", heavygreen);
AttachLegend();

// or an abbreviation
NewPad();
draw(rGetObj("../example.root", "hist"), "vl,l", heavygreen);
AttachLegend();
