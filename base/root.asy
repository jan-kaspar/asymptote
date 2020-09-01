/****************************************************************************
*
* This is a part of the "ROOT extension to Asymptote" project.
* Authors:
*	Jan Kašpar (jan.kaspar@gmail.com)
*
* \brief Macros to draw ROOT objects.
****************************************************************************/

import graph;
import contour;
import palette;

from settings access verbose;

// whether to use TNamed::GetName when supplied label=""
bool useDefaultLabel = false;

//----------------------------------------------------------------------------------------------------
// option list
//----------------------------------------------------------------------------------------------------

/// type representing a list of draw options
typedef string[] OptionList;

//----------------------------------------------------------------------------------------------------

/// converts a string to a list of options
OptionList StrToOptList(string option)
{
	return split(option, ",");
}

//----------------------------------------------------------------------------------------------------

/// checks whether option 'option' is present in the option list
bool TestOption(OptionList list, string option)
{
	for (int i : list.keys)
		if (list[i] == option)
			return true;
	return false;
}

//----------------------------------------------------------------------------------------------------

/// checks whether option 'o1' or 'o2' is present in the option list
bool TestOption(OptionList list, string o1, string o2)
{
	return TestOption(list, o1) || TestOption(list, o2);
}

//----------------------------------------------------------------------------------------------------
// TH1
//----------------------------------------------------------------------------------------------------

real TH1_x_min = -inf;
real TH1_x_max = +inf;
real TH1_errorContourOpacity = 0.3;
bool TH1_use_y_def = false;
real TH1_y_def = -1.;

/**
 *\brief Draws a 1D histogram.
 *
 * Recognized options are:
 *  - "N", "n"	to normalize the histogram to the integral/sum of 1.
 *  - "vl"		to draw vertical lines
 *  - "cl"		to draw central lines (line that connects bin centers)
 *  - "d0"		discard bin with zero content
 *  - "eb"		to draw bin error bars
 *  - "ec"		to draw error contour

 *  - "L", "l"	equivalent to lE,lM,lR
 *  - "lE"		adds the number of entries to the legend
 *  - "lM"		adds the mean to the legend
 *  - "lR"		adds the RMS to the legend
 **/
void drawTH1(transform tr, picture pic, RootObject obj, string options, pen _pen, marker _marker, Label _legend)
{
	if (options == "def")
		options = "vl,ec";

	OptionList optList = StrToOptList(options);

	bool vertLines = TestOption(optList, "vl");
	bool centLines = TestOption(optList, "cl");
	bool discZeros = TestOption(optList, "d0");
	bool errBars = TestOption(optList, "eb");
	bool errCont = TestOption(optList, "ec");

	bool horLines = true;
	if (vertLines)
		horLines = false;
	if (centLines)
	{
		horLines = false;
		vertLines = false;
	}

	// normalization factor
	real fac = 1;
	if (TestOption(optList, "N", "n"))
	{
		// TODO: first needs to fix the bug in root.cc
		real integral = obj.rExec("Integral", "width");
		//real integral = 0;
		if (integral > 0)
			fac = 1/integral;
		else
			write("ERROR in drawTH1 > Cannot normalize histogram - the integral is zero.");
	}

	// draw the histogram
	guide bit;
	int N = obj.iExec("GetNbinsX");
	real prev_v = inf;
	for (int i = 1; i <= N; ++i)
	{
		real l = obj.rExec("GetBinLowEdge", i);
		real w = obj.rExec("GetBinWidth", i);
		real c = l+w/2;
		real r = l+w;

		real v = obj.rExec("GetBinContent", i) * fac;
		real e = obj.rExec("GetBinError", i) * fac;

		real vMin = v-e, vCnt = v, vMax = v+e;

		// out-of draw range? discard zeros?
		if (c < TH1_x_min || c > TH1_x_max || (discZeros && v == 0.))
		{
			prev_v = inf;
			if (size(bit) > 0)
				draw(tr*bit, _pen, _marker);
			bit = nullpath;
			continue;
		}

		// valid value?
		if (pic.scale.y.scale.logarithmic && vCnt <= 0)
		{
			if (TH1_use_y_def)
			{
				vCnt = TH1_y_def;
			} else {
				prev_v = inf;
				if (size(bit) > 0)
					draw(tr*bit, _pen, _marker);
				bit = nullpath;
				continue;
			}
		}

		// add line segment(s)
		if (centLines)
			bit = bit--Scale((c, vCnt));
		else
			bit = bit--Scale((l, vCnt))--Scale((r, vCnt));

		// draw segments if non-continuous mode
		if (horLines)
		{
			if (size(bit) > 0)
				draw(tr*bit, _pen, _marker);
			bit = nullpath;
		}

		prev_v = vCnt;

		// valid error?
		if (pic.scale.y.scale.logarithmic && vMin <= 0)
			vMin = vCnt;

		// error contours
		if (errCont)
			filldraw(tr*(Scale((l, vMin))--Scale((r, vMin))--Scale((r, vMax))--Scale((l, vMax))--cycle),
				_pen+opacity(TH1_errorContourOpacity), nullpen);

		// error bars
		if (errBars)
			draw(tr*(Scale((c, vMin))--Scale((c, vMax))), _pen);
	}

	if (size(bit) > 0)
		draw(tr*bit, _pen, _marker);

	// add legend entry
	if (_legend.s == "" && useDefaultLabel)
		_legend = obj.sExec("GetName");

	if (_legend.s != "")
	{
		Legend bla;
		bla.operator init(_legend.s, _pen, _marker.f);
		pic.legend.push(bla);
	}

	// add statistics to the legend
	bool lE = TestOption(optList, "L", "l");
	bool lM = lE, lR = lE;
	if (TestOption(optList, "lE")) lE = true;
	if (TestOption(optList, "lM")) lM = true;
	if (TestOption(optList, "lR")) lR = true;

	if (lE) {
		Legend bla;
		bla.operator init("entries = " + format("$%.0f$", obj.rExec("GetEntries")), p=invisible);
		pic.legend.push(bla);
	}
	if (lM) {
		Legend bla;
		bla.operator init("mean = " + format("$%.1E$", obj.rExec("GetMean")), p=invisible);
		pic.legend.push(bla);
	}
	if (lR) {
		Legend bla;
		bla.operator init("RMS = " + format("$%.1E$", obj.rExec("GetRMS")), p=invisible);
		pic.legend.push(bla);
	}
}

//----------------------------------------------------------------------------------------------------
// TH2
//----------------------------------------------------------------------------------------------------

real TH2_x_min = -inf, TH2_x_max = +inf;
real TH2_y_min = -inf, TH2_y_max = +inf;
real TH2_z_min = 2, TH2_z_max = 1;	// invalid order, will trigger automatic calculation

pen TH2_boundaryPen = black;
pen TH2_palette[] = Gradient(blue, heavygreen, yellow, red, black);
real TH2_paletteBarSpacing = 0.05;
real TH2_paletteBarWidth = 0.1;
string TH2_zLabel = "";
paletteticks TH2_paletteTicks = PaletteTicks;

/**
 *\brief Draws a 2D histogram.
 *
 * Recognized options are:
	// - "P", "p" will pick color from the palette, if not will use the color supplied in function parameters (default)
	// - "O", "o" will adjust opacity according to the cell content
	// - "S", "s" whether to adapt the cell size according to the cell content
	// - "B", "b" whether to draw a boundary around cells
	// - "bar"	  add palette bar
	// - "d0"     do not draw empty cells (content = 0)
 **/
void drawTH2(transform tr, picture pic, RootObject obj, string options, pen _pen, marker _marker, Label _legend)
{
	RootObject xAx = obj.oExec("GetXaxis");
	RootObject yAx = obj.oExec("GetYaxis");

	int Nx = obj.iExec("GetNbinsX");
	int Ny = obj.iExec("GetNbinsY");

	pen fillPen = _pen;

	if (options == "def")
		options = "p,d0,bar";

	OptionList optList = StrToOptList(options);

	bool palette = false;
	if (TestOption(optList, "P", "p")) palette = true;

	bool opacity = false;
	if (TestOption(optList, "O", "o")) opacity = true;

	bool paletteBar = false;
	if (TestOption(optList, "bar")) paletteBar = true;

	bool sizing = false;
	if (TestOption(optList, "S", "s")) sizing = true;

	bool discardEmpty = false;
	if (TestOption(optList, "d0")) discardEmpty = true;

	pen boundaryPen = nullpen;
	if (TestOption(optList, "B", "b")) boundaryPen = TH2_boundaryPen;

	// determine index ranges
	int xi_min = Nx, xi_max = 1;
	for (int i = 1; i <= Nx; ++i)
	{
		real cx = xAx.rExec("GetBinCenter", i);
		if (cx >= TH2_x_min && cx <= TH2_x_max)
		{
			xi_min = min(xi_min, i);
			xi_max = max(xi_max, i);
		}
	}

	int yi_min = Ny, yi_max = 1;
	for (int i = 1; i <= Ny; ++i)
	{
		real cy = yAx.rExec("GetBinCenter", i);
		if (cy >= TH2_y_min && cy <= TH2_y_max)
		{
			yi_min = min(yi_min, i);
			yi_max = max(yi_max, i);
		}
	}

	// determine z scale
	real c_min = pic.scale.z.T(TH2_z_min), c_max = pic.scale.z.T(TH2_z_max);
	if (c_max <= c_min)
	{
		// TODO
		c_max = -1e100;
		c_min = +1e100;

		for (int xi = xi_min; xi <= xi_max; ++xi)
		{
			for (int yi = yi_min; yi <= yi_max; ++yi)
			{
				real c = obj.rExec("GetBinContent", xi, yi);

				// skip NAN etc.
				if (c != c)
					continue;

				// apply picture's scale
				if (pic.scale.z.scale.logarithmic && c <= 0)
					continue;
				else
					c = pic.scale.z.T(c);

				c_max = max(c_max, c);
				c_min = min(c_min, c);
			}
		}
	}

	if (c_min >= c_max)
	{
		if (pic.scale.z.scale.logarithmic && c_max == 0)
		{
			// this can be the case where histogram contains only cells which are empty or with 1 hit
			// set some scale to permit plotting it
			c_min = -1;
		} else {
			write("ERROR in drawTH2 > "+format("c_min=%.2E, ", c_min)+format("c_max=%.2E", c_max));
			return;
		}
	}

	if (verbose > 0)
	{
		write("c_min = ", c_min);
		write("c_max = ", c_max);
	}

	// plot bins
	for (int xi = xi_min; xi <= xi_max; ++xi)
	{
		for (int yi = yi_min; yi <= yi_max; ++yi)
		{
			real c = obj.rExec("GetBinContent", xi, yi);

			// skip NAN etc.
			if (c != c)
				continue;

			// skip empty cells?
			if (c == 0)
				continue;

			if (pic.scale.z.scale.logarithmic && c <= 0)
				continue;
			else
				c = pic.scale.z.T(c);

			// effective content: value between 0 and 1
			real ec = (c - c_min) / (c_max - c_min);

			// skip bins outside the z-range selection
			if (ec < 0 || ec > 1)
				continue;

			// bin geometry
			real cx = xAx.rExec("GetBinCenter", xi);
			real cy = yAx.rExec("GetBinCenter", yi);
			real wx = xAx.rExec("GetBinWidth", xi) / 2;
			real wy = yAx.rExec("GetBinWidth", yi) / 2;

			// skip if bin outside selection
			if (cx < TH2_x_min || cx > TH2_x_max)
				continue;

			if (cy < TH2_y_min || cy > TH2_y_max)
				continue;

			if (sizing)
			{
				wx = wx * ec;
				wy = wy * ec;
			}

			int idx = (int) (ec * (TH2_palette.length - 1));
			fillPen = (palette) ? TH2_palette[idx] : _pen;

			if (opacity)
				fillPen += opacity(ec);

			if (idx >= 0)
				filldraw(tr*((cx-wx, cy-wy)--(cx+wx, cy-wy)--(cx+wx, cy+wy)--(cx-wx,cy+wy)--cycle), fillPen, boundaryPen);
		}
	}

	if (paletteBar)
	{
		bounds B;
		B.min = pic.scale.z.Tinv(c_min);
		B.max = pic.scale.z.Tinv(c_max);

		// need a local copy of all parameters
		string zLabel = TH2_zLabel;
		pen palette[] = TH2_palette;
		picture p = currentpicture;
		paletteticks paletteTicks = TH2_paletteTicks;
		real paletteBarSpacing = TH2_paletteBarSpacing;
		real paletteBarWidth = TH2_paletteBarWidth;

		pic.add( new void(frame f, transform t) {
			pair min = p.userMin();
			pair max = p.userMax();

			real w = max.x - min.x;
			real x1 = max.x + w * paletteBarSpacing;
			real x2 = x1 + w * paletteBarWidth;

			x1 = p.scale.x.Tinv(x1);
			x2 = p.scale.x.Tinv(x2);

			real y1 = p.scale.y.Tinv(min.y);
			real y2 = p.scale.y.Tinv(max.y);

			palette(p, zLabel, B, (x1, y1), (x2, y2), Right, palette, paletteTicks);
		});
	}
}

//----------------------------------------------------------------------------------------------------
// TGraph
//----------------------------------------------------------------------------------------------------

// skip every nth point
int TGraph_reducePoints = 1;

// list of indeces of points to be skipped
int TGraph_skipPoints[];

// limit on number of points
int TGraph_nPointsLimit = intMax;

// range selection
real TGraph_x_min = -inf, TGraph_x_max = +inf;
real TGraph_y_min = -inf, TGraph_y_max = +inf;

pen TGraph_errorBarPen = black;
arrowbar TGraph_errorBar = Bars;
real TGraph_errorContourOpacity = 0.3;

/**
 *\brief Draws a 1D graph.
 *
 * Recognized options are:
 *  - "L", "l"	to draw a line through the graph's points (default option)
 *  - "P", "p"	to draw each of the points (including optional error bars)
 *  - "D", "d"	to draw a dot for each point
 *  - "ieb"		to Ignore Error Bars
 *  - "iebx"	to Ignore Error Bars in x
 *  - "ieby"	to Ignore Error Bars in y
 *	- "sebc"	to draw Error Bars with a Special Color (TGraph_errorBarPen)
 *	- "ec"		to draw error contour (to fill the +- 1sigma region around the actual curve)
 *  - "d0"		discard (skip) points with y = 0
 **/
void drawTGraph(transform tr, picture pic, RootObject obj, string options, pen _pen, marker _marker, Label _legend)
{
	if (options == "def")
		options = "l";

	OptionList optList = StrToOptList(options);

	// default legend properties
	pen l_pen = nullpen;
	marker l_marker;

	// number of points
	int N = obj.iExec("GetN");

	bool drawPoints = TestOption(optList, "P", "p");
	bool drawDots = TestOption(optList, "D", "d");
	bool drawLine = TestOption(optList, "L", "l");

	bool hasErrors = obj.InheritsFrom("TGraphErrors");
	bool hasErrorsAsym = obj.InheritsFrom("TGraphAsymmErrors");
	bool errorBars_x = hasErrors || hasErrorsAsym;
	bool errorBars_y = hasErrors || hasErrorsAsym;
	bool errorContour = false;
	bool discardZeros = false;

	if (TestOption(optList, "ieb"))
		errorBars_x = errorBars_y = false;

	if (TestOption(optList, "iebx"))
		errorBars_x = false;

	if (TestOption(optList, "ieby"))
		errorBars_y = false;

	if (TestOption(optList, "ec"))
	{
		errorContour = true;
		errorBars_x = errorBars_y = false;
	}

	if (TestOption(optList, "d0"))
		discardZeros = true;

	pen ebp = _pen;
	if (TestOption(optList, "sebc"))
		ebp = TGraph_errorBarPen;

	// go through all points
	int j = 0, i_eff;
	guide p, uep, bep;
	for (int i = 0; i < N && i_eff < TGraph_nPointsLimit; ++i)
	{
		// skip point?
		bool skip = false;
		for (int si : TGraph_skipPoints.keys)
			if (TGraph_skipPoints[si] == i)
			{
				skip = true;
				break;
			}
		if (skip)
			continue;

		real[] x = {0};
		real[] y = {0};
		obj.vExec("GetPoint", i, x, y);

		// skip points outside selected range
		if (x[0] < TGraph_x_min || x[0] > TGraph_x_max)
			continue;

		if (y[0] < TGraph_y_min || y[0] > TGraph_y_max)
			continue;

		if (discardZeros && y[0] == 0)
			continue;

		real ex_mi, ex_pl, ey_mi, ey_pl;
		if (hasErrors)
		{
			ex_mi = ex_pl = obj.rExec("GetErrorX", i);
			ey_mi = ey_pl = obj.rExec("GetErrorY", i);
		}

		if (hasErrorsAsym)
		{
			ex_mi = obj.rExec("GetErrorXlow", i);
			ex_pl = obj.rExec("GetErrorXhigh", i);
			ey_mi = obj.rExec("GetErrorYlow", i);
			ey_pl = obj.rExec("GetErrorYhigh", i);
		}

		// avoid NANs, floating point exceptions in log scale, etc.
		if (y[0] != y[0] || x[0] != x[0])
			continue;
		if ((pic.scale.x.scale.logarithmic && x[0] <= 0) || (pic.scale.y.scale.logarithmic && y[0] <= 0))
			continue;
		if (x[0] == inf || x[0] == -inf || y[0] == inf || y[0] == +inf)
			continue;

		if (errorBars_x || errorBars_y || errorContour)
		{
			if (ey_mi != ey_mi || ex_mi != ex_mi || ey_pl != ey_pl || ex_pl != ex_pl)
				continue;
			if (ex_mi == inf || ex_mi == -inf || ey_mi == inf || ey_mi == -inf)
				continue;
			if (ex_pl == inf || ex_pl == -inf || ey_pl == inf || ey_pl == -inf)
				continue;
			if ((pic.scale.x.scale.logarithmic && x[0]-ex_mi <= 0) || (pic.scale.y.scale.logarithmic && y[0]-ey_mi <= 0))
				continue;
		}

		// add only filtered points
		if (j == 0)
		{
			if (drawPoints)
				draw(pic, tr*Scale((x[0], y[0])), _pen, _marker);

			if (drawDots)
				dot(pic, tr*Scale((x[0], y[0])), _pen);

			if (drawPoints || drawDots)
			{
				if (errorBars_x)
					draw(tr*(Scale((x[0]-ex_mi, y[0]))--Scale((x[0]+ex_pl, y[0]))), ebp, TGraph_errorBar);
				if (errorBars_y)
					draw(tr*(Scale((x[0], y[0]-ey_mi))--Scale((x[0], y[0]+ey_pl))), ebp, TGraph_errorBar);
			}

			if (errorContour)
			{
				uep = uep--Scale((x[0]-ex_mi, y[0]+ey_pl));
				uep = uep--Scale((x[0]+ex_pl, y[0]+ey_pl));
				bep = bep--Scale((x[0]-ex_mi, y[0]-ey_mi));
				bep = bep--Scale((x[0]+ex_pl, y[0]-ey_mi));
			}

			if (drawLine)
				p = p--Scale((x[0], y[0]));

			++i_eff;
		}

		j = (j + 1) % TGraph_reducePoints;
	}

	if (errorContour)
	{
		guide g = uep--reverse(bep)--cycle;
		filldraw(pic, tr*g, _pen+opacity(TGraph_errorContourOpacity), nullpen);
	}

	if (drawPoints)
		l_marker = _marker;

	if (drawLine)
	{
		draw(pic, tr*p, _pen);
		l_pen = _pen;
	}

	if (hasErrors)
		l_pen = _pen;

	// add legend entry
	if (_legend.s == "" && useDefaultLabel)
		_legend = obj.sExec("GetName");

	if (_legend.s != "")
	{
		Legend bla;
		bla.operator init(_legend.s, l_pen, l_marker.f);
		pic.legend.push(bla);
	}

	// settings reset
	TGraph_skipPoints.delete();
}

//----------------------------------------------------------------------------------------------------
// TGraph2D
//----------------------------------------------------------------------------------------------------

// range selection
real TGraph2D_x_min = -inf, TGraph2D_x_max = +inf;
real TGraph2D_y_min = -inf, TGraph2D_y_max = +inf;
real TGraph2D_z_min = -inf, TGraph2D_z_max = +inf;

// list of z value for which contours shall be draw
real[] TGraph2D_contourValues;

// if TGraph2D_contourValues is empty, make the following number of equidistant contours between z_min and z_max
int TGraph2D_nContours = 9;

// formatting rule for labels
string TGraph2D_labelFormat = "%f";

// pen for drawing lables, if nullpen, the pen supplied to drawTGraph2D is used
pen TGraph2D_labelPen = nullpen;

/**
 *\brief Draws a 2D graph.
 *
 * Recognized options are:
 *  - "cont" to draw contour lines (default option)
 **/
// TODO: more options: textual labels on/off, color coded contours (+z scale bar)
void drawTGraph2D(transform tr, picture pic, RootObject obj, string options, pen _pen, marker _marker, Label _legend)
{
	if (options == "def")
		options = "cont";

	if (find(options, "cont") >= 0)
	{
		int N = obj.iExec("GetN");
		pair[] points;
		real[] values;

		real c_min = +inf, c_max = -inf;

		for (int i = 0; i < N; ++i)
		{
			real x = obj.raExec("GetX", i);
			real y = obj.raExec("GetY", i);
			real z = obj.raExec("GetZ", i);

			// skip points outside selection
			if (x < TGraph2D_x_min || x > TGraph2D_x_max)
				continue;
			if (y < TGraph2D_y_min || y > TGraph2D_y_max)
				continue;
			if (z < TGraph2D_z_min || z > TGraph2D_z_max)
				continue;

			points.push( Scale((x, y)) );
			values.push(z);

			// determine content range
			if (z > c_max)
				c_max = z;
			if (z < c_min)
				c_min = z;
		}

		if (TGraph2D_contourValues.length == 0)
		{
			real step = (c_max - c_min) / (TGraph2D_nContours + 1);
			real v = c_min + step;
			for (int i = 0; i < TGraph2D_nContours; ++i)
			{
				TGraph2D_contourValues.push(v);
				v += step;
			}
		}

		// generate contours
		guide contours[][] = contour(points, values, TGraph2D_contourValues);

		// plot contours
		pen labelPen = (TGraph2D_labelPen == nullpen) ? _pen : TGraph2D_labelPen;
		for (int i : contours.keys)
		{
			Label label = Label(format(TGraph2D_labelFormat, TGraph2D_contourValues[i]), Relative(0.5), (0,0),
				labelPen, UnFill());

			for (int j : contours[i].keys)
			{
				draw(label, contours[i][j], _pen);
			}
		}

		TGraph2D_contourValues.delete();
	}

	//pen[][] palette = { {red, green}, {blue, gray}};
	//fill(contour(points, values, cValues), palette);

	// add legend entry
	if (_legend.s == "" && useDefaultLabel)
		_legend = obj.sExec("GetName");

	if (_legend.s != "")
	{
		Legend bla;
		bla.operator init(_legend.s, _pen);
		pic.legend.push(bla);
	}
}

//----------------------------------------------------------------------------------------------------
// TF1
//----------------------------------------------------------------------------------------------------

// number of function samples
int TF1_nPoints = 1000;

// range selection
real TF1_x_min = -inf;
real TF1_x_max = +inf;

RootObject TF1_obj;
real TF1_enumerator(real x)
{
	return TF1_obj.rExec("Eval", x);
}

/**
 *\brief Draws a 1D function.
 *
 * Recognized options are:
 **/
void drawTF1(transform tr, picture pic, RootObject obj, string options, pen _pen, marker _marker, Label _legend)
{
	TF1_obj = obj;

	real xMin[] = {0.};
	real xMax[] = {0.};
	obj.vExec("GetRange", xMin, xMax);

	if (TF1_x_min != -inf)
		xMin[0] = TF1_x_min;

	if (TF1_x_max != +inf)
		xMax[0] = TF1_x_max;

	// add legend entry
	if (_legend.s == "" && useDefaultLabel)
		_legend = obj.sExec("GetName");

	draw(tr*graph(TF1_enumerator, xMin[0], xMax[0], TF1_nPoints), _pen, _legend);
}

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------

/**
 *\brief Common method to draw a ROOT object.
 *
 * Recognized classes are:
 *  - TH1
 *  - TH2
 *  - TGraph (+TGraphErrors)
 *  - TGraph2D
 *  - TF1
 **/
void draw(transform tr = identity(), picture pic=currentpicture, RootObject obj, string options="def", pen pen=currentpen,
	marker marker=nomarker, Label legend="")
{
	if (!obj.valid)
	{
		write("ERROR in draw(..., RootObject, ...) > Cannot draw invalid RootObject.");
		return;
	}

	if (obj.InheritsFrom("TH2")) { drawTH2(tr, pic, obj, options, pen, marker, legend); return; }
	if (obj.InheritsFrom("TH1")) { drawTH1(tr, pic, obj, options, pen, marker, legend); return; }
	if (obj.InheritsFrom("TGraph")) { drawTGraph(tr, pic, obj, options, pen, marker, legend); return; }
	if (obj.InheritsFrom("TGraph2D")) { drawTGraph2D(tr, pic, obj, options, pen, marker, legend); return; }
	if (obj.InheritsFrom("TF1")) { drawTF1(tr, pic, obj, options, pen, marker, legend); return; }

	write("ERROR in draw(..., RootObject, ...) > Do not know how to draw the following RootObject.");
	obj.Print();
}