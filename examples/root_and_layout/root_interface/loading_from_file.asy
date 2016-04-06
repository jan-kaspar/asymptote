string file = "../example.root";

// ROOT objects can be load from ROOT files by calling
// RootGetObject(string file, string name, bool error=true, bool search=true)

// load a ROOT object from a file
RootObject o = RootGetObject(file, "graph");
o.Print();

// you can load objects from directories
RootObject h = RootGetObject(file, "dir1/hist");
h.Print();

// you can extract ROOT objection even from collection objects (such as TCanvas, ...)
// 1) by index within the collection:
RootObject o = RootGetObject(file, "canvas#1");
o.Print();

// 2) by the name within the collection
RootObject o = RootGetObject(file, "canvas|hist");
o.Print();

// the /, | and # operators can be chained up
o = RootGetObject(file, "dir2/canvas|hist#0");
o.Print();

// if the | and # operators would clash with object names, their expansion can be inhibited
o = RootGetObject(file, "dir3/a#weird|name", search=false);
o.Print();

// if the requested object does not exist, Asymptote would issue an error message
// this can be avoided by setting error=false, in this case the returned object is ivalid
o = RootGetObject(file, "ThisDoesNotExist", error=false);
o.Print();

// for convenience there si `robj' keeping reference to the last loaded object
RootGetObject(file, "graph");
robj.Print();

// in the following case the loading fails hence robj still referes to the graph from the previous example
RootGetObject(file, "ThisDoesNotExist", error=false);
robj.Print();
