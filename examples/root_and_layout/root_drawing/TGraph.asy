import root;
import pad_layout;

// draw line through points
NewPad();
draw(RootGetObject("../example.root", "graph"), "l", red); 

// draw line through points and draw error contour (fill the +- 1sigma region around the actual curve)
NewPad();
draw(RootGetObject("../example.root", "graph"), "l,ec", heavygreen); 

// set the opacity of the error contour
NewPad();
TGraph_errorContourOpacity = 0.05;
draw(RootGetObject("../example.root", "graph"), "l,ec", blue); 

NewRow();

// draw each of the points with a marker
NewPad();
draw(RootGetObject("../example.root", "graph"), "p", red, mCi+red+2pt);

// error bars with a special color
NewPad();
TGraph_errorBarPen = blue;
draw(RootGetObject("../example.root", "graph"), "p,sebc", red, mCi+red+2pt);

// ignore error bars
NewPad();
draw(RootGetObject("../example.root", "graph"), "p,ieb", mCi+red+2pt);

NewRow();

// draw only a chosen x region
NewPad();
TGraph_x_max = 2;
draw(RootGetObject("../example.root", "graph"), "p", red, mCi+red+2pt); 
TGraph_x_min = 2;
TGraph_x_max = +inf;
draw(RootGetObject("../example.root", "graph"), "l,ec,p", red, mSq+blue+1pt);
TGraph_x_min = -inf;
TGraph_x_max = +inf;

// skip certain points (calculation error?) 
NewPad();
TGraph_skipPoints = new int[] {9, 10, 11};
draw(RootGetObject("../example.root", "graph"), "p", red, mCi+red+2pt);

NewRow();

// keep all points
NewPad();
TGraph_reducePoints = 1;
draw(RootGetObject("../example.root", "scatter"), "p", mCi+black+1pt);

// keep every tenth point only
NewPad();
TGraph_reducePoints = 10;
draw(RootGetObject("../example.root", "scatter"), "p", mCi+black+1pt);

// limit total number of points (keep first 100 points)
NewPad();
TGraph_N_limit = 100;
draw(RootGetObject("../example.root", "scatter"), "p", mCi+black+1pt);
