import root;

size(6cm, 6cm, false);

// ROOT objects are drawn by
// void draw(transform tr = identity(), picture pic=currentpicture, RootObject obj, string options="", pen pen=currentpen, 
//	marker marker=nomarker, Label legend="")

draw(RootGetObject("../example.root", "hist"), "", blue);
draw(RootGetObject("../example.root", "hist|gaus"), "", red+1pt);

// ROOT objects can be transformed while drawn
draw(shift(0, 40)*yscale(-1), robj, heavygreen+dashed);

// indeed, combination with other asymptote commands is possible
draw(Label("fit", 0), (3, 30)--(1.5, 15), EndArrow);
