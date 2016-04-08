import root;
import pad_layout;

// automatic contours
NewPad("$x$", "$y$");
draw(RootGetObject("../example.root", "graph2"), red);

// manual setting the number contours
NewPad("$x$", "$y$");
TGraph2D_nContours = 3;
draw(RootGetObject("../example.root", "graph2"), blue);

// manual setting contours
NewPad("$x$", "$y$");
TGraph2D_contourValues = new int[] {3, 10, 20, 30};
TGraph2D_labelPen = fontcommand("\it") + red;
draw(RootGetObject("../example.root", "graph2"), heavygreen);
TGraph2D_labelPen = nullpen;	// reset
// TGraph2D_contourValues reset automatically

// format of contour labels
TGraph2D_nContours = 5;
TGraph2D_labelFormat = "%.1f";
NewPad("$x$", "$y$");
draw(RootGetObject("../example.root", "graph2"), blue);

// range selection
NewPad("$x$", "$y$");
TGraph2D_x_min = 0; TGraph2D_x_max = +5;
TGraph2D_y_min = 0; TGraph2D_y_max = +5;
TGraph2D_z_min = 10; TGraph2D_z_max = 30;
draw(RootGetObject("../example.root", "graph2"), blue);

// using with logarithmic scale
NewPad("$x$", "$y$");
scale(Log, Log);
TGraph2D_x_min = 1;
TGraph2D_y_min = 1;
draw(RootGetObject("../example.root", "graph2"), blue);
