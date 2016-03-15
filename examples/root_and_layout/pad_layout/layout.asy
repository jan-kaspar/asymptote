import pad_layout;

// test curves
guide g1, g2;
for (real x = 0; x <= 10; x += 1) {
	g1 = g1 -- (x, x^2);
	g2 = g2 -- (x, 100-x^2);
}

// All graphics is organized in pads -- graphic containers with a set of x, y axes, legend, ...

// To create a new pad, call:
// pad NewPad(
//			bool drawAxes = true,		// whether the axes shall be drawn
// 			bool axesAbove = false,		// whether the axes shall be drawn over the pad drawings
// 			string xLabel = "",			// the label of the x axis
//			string yLabel = "",
// 			ticks xTicks = xTicksDef,	// the tick specifier for the x axis
//			ticks yTicks = yTicksDef,
// 			bool autoSize = true,		// whether to impose the plot size (xSize, ySize)
// 			real xSize = xSizeDef,		// the horizontal plot size (distance between the vertical axes)
//			real ySize = ySizeDef,		// the vertical plot size (distance between the horizontal axes)
// 			int xGridHint,				// the horizontal placement of the pad within the layout (grid)
//			int yGridHint				// the vertical placement of the pad within the layout (grid)
//	)
//
// When the grid hints are not specified, the pads are placed in a row (from left to right). This corresponds
// to incrementing xGridHint. One can start a new row by calling NewRow(). This resets xGridHint to 0 and
// increments yGridHint by 1. The first row has yGridHint 0.
//
// The current pad can be referred by `currentpad' variable.

// default pad
NewPad();
draw(g1, blue);

// pad with labels
NewPad("$x$", "$y$");
draw(g2, red);

// pad with tick specifiers
NewPad("$x$", LeftTicks(Step=1, step=0.2));
draw(g2, red);

// pad with non-default size
NewPad("$x$", 5cm, 7cm);
draw(g1, blue);

// pad without sizing
NewPad("$x$", autoSize=false);
draw(g1, blue);

// new a new row is started
NewRow();

// pad without axes
NewPad(drawAxes=false);
label("no axes here");

// an example where placing axes on top of pad graphics is essential
NewPad(axesAbove=true);
filldraw((0, 0)--(1, 0)--(1, 1)--(0, 1)--cycle, green, nullpen);

// any of the attributes can be changed later
NewPad();
draw(g1, blue);
currentpad.xLabel = "$x$";
currentpad.xSize = 4cm;

// one can alternate between several pads
pad p1 = NewPad();
pad p2 = NewPad("pad2");
draw(g1, blue);

p1.xLabel = "pad1";
SetPad(p1);
draw(g2, red);

// one can put a pad to any place in the layout grid
NewPad(3, 2);
draw(g1, blue);

// legend can be attached easily
NewPad(-1, 2);
draw(g1, blue, "blue curve");
draw(g2, red, "red curve");
AttachLegend();

// for the formats the support multiple pages, one can use NewRow() to start a new page
NewPage();
NewPad();
draw(g1, blue);


// The placement of pads into a layout is performed by function
// void GShipout(
//		string prefix=defaultfilename,
//		pair alignment=(0, 0),				// alignment point
//		real hSkip=1cm,						// spacing between columns
//		real vSkip=1cm,						// spacing between rows
//		real margin=1mm, 					// margin around the entire layout
// 		pen p = nullpen,					// pen to draw a frame around the entire layout (with margin)
//		filltype filltype = Fill(white)		// background style for the layout
// )
//
// The alignment point specifies the point on the axes frame (e.g. NE corresponds to top-right corner) that
// is used to align the pads into the grid. In other words, the alignment points of each pad would form
// columns and rows.

// The GShipout method is called automatically at the end of Asymptote processing. The only reason to call
// explicitely is when you want to change some of the default parameters.
GShipout(Fill(paleyellow));
