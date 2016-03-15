import pad_layout;

// there is a simple way of building a customized marker -- one can specify its properties as follows:
//     <shape> + <color> + <size> + <filled flag>
// <shape> is a circular path (the predefined ones are listed below)
// <color> is a pen (e.g. red)
// <size> is a real number (e.g. 2pt)
// <filled flag> is a bool: true (default) for filled marker, false for hollow marker

// the use of markers is very simple
NewPad();
guide g;
for (real x = 0; x <= 10; x += 1)
	g = g -- (x, x^2);
draw(g, blue, mCr2+red+3pt);

// this demonstrates all predifided markers
NewPad();
mark marks[] = { mCi, mSq, mTU, mTL, mTD, mTR, mPl, mCr, mPl2, mCr2, mSt4, mSt5, mSt6 };
string names[] = { "mCi", "mSq", "mTU", "mTL", "mTD", "mTR", "mPl", "mCr", "mPl2", "mCr2", "mSt4", "mSt5", "mSt6" };
for (int i : marks.keys) {
	real y = -10*i;
	label(names[i], (-10, y));
	draw((0, y), marks[i]+blue+3pt+false);
	draw((10, y), marks[i]+blue+3pt+true);
}
limits((-20, -130), (+20, 10));
