// ROOT objects are represented in Asymptote by one single type RootObject
RootObject o;

// load a ROOT object from a file
string file = "../example.root";
RootObject o = RootGetObject(file, "graph");

// test whether the object is valid
if (!o.valid)
	write("invalid");

// print the contents of the object
o.Print();

// you can also print (Asymptote) information on the object
write(o);
write("object o: ", o);

// you can check the inheritance path of the object
if (o.InheritsFrom("TGraph"))
	write("inherits from TGraph");

// ROOT objects can be copied in two ways:
// 1) shallow copy (only pointers are copied, modifications committed to o2 affect o too)
RootObject o2 = o;
write("object o2: ", o2);

// 2) deep copy (data are copied)
// o3 and o have independent data (the obj pointers are different now)
RootObject o3 = o.Copy();	
write("object o3: ", o3);

// an example where the deep copy might be useful - the same histogram with two different binnings
RootObject h = RootGetObject(file, "hist");
RootObject h2 = h.Copy();
h.vExec("Rebin", 5);
h2.vExec("Rebin", 2);
