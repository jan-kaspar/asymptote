RootObject o = RootGetObject("../example.root", "hist");

// dump an object
o.vExec("Dump");

// get number of bins
int i = o.iExec("GetNbinsX");
write("bins = ", i);

// get the mean value
real m = o.rExec("GetMean");
write("mean = ", m);

// get the name of the histogram
write("name = ", o.sExec("GetName"));

// get the contents of the first bin
write("contents of the first bin = ", o.rExec("GetBinContent", 1));


RootObject o = RootGetObject("../example.root", "graph");

// passing parameters by reference
// get the coordinates of the first point of a graph
real[] x = {2.};
real[] y = {2.};
o.vExec("GetPoint", 0, x, y);
write("x = ", x[0]);
write("y = ", y[0]);
