import pad_layout;

// this is to build a test legend
// this demonstrates the behavior of `AddToLegend' function
void MakeTestLegend()
{
	AddToLegend("short", red, mCi+red+2pt);
	AddToLegend("a bit longer", blue);
	AddToLegend("already quite long", heavygreen);
	AddToLegend("but this one is really long, so it will most likely be\break{} wrapped into several lines", black);
	AddToLegend("bla bla neco bla bla and yet some more bla", red);
	AddToLegend("again something here", blue, mPl2+2pt+blue);
	AddToLegend("and the last one", mSt+heavygreen+2pt);
	AddToLegend("OK, here is one more quite long line here", red);
	AddToLegend("short again", magenta);
}


// the default legend (one column, no long-line wrapping)
NewPad(false);
MakeTestLegend();
AttachLegend();

NewRow();

// one column, but set the row width to 5cm (longer lines are automatically wrapped)
NewPad(false);
MakeTestLegend();
AttachLegend(1, 5cm);

NewRow();

// build legend with four columns (by default, each column is vertically stretched to keep an uniform height)
NewPad(false);
MakeTestLegend();
AttachLegend(4, 5cm);

NewRow();

// this prevents the vertical stretching
NewPad(false);
MakeTestLegend();
AttachLegend(4, 5cm, stretch=false);

NewRow();

// legend alignment examples
guide g1, g2;
for (real x = 0; x <= 10; x += 1) {
	g1 = g1 -- (x, x^2);
	g2 = g2 -- (x, 100-x^2);
}

// attach the legend by its N(orth) point to the NE point of the plot
NewPad("$x$, $y$");
draw(g1, red, "red curve");
draw(g2, blue, "blue curve", mCi+blue+1pt);
AttachLegend(N, NE);

// a more convenient example
NewPad("$x$, $y$");
draw(g1, red, "red curve");
draw(g2, blue, "blue curve", mCi+blue+1pt);
AttachLegend(W, W);

// the default
NewPad("$x$, $y$");
draw(g1, red, "red curve");
draw(g2, blue, "blue curve", mCi+blue+1pt);
AttachLegend();
