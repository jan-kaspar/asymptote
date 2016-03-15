void makeExampleRoot()
{
	TFile *f = new TFile("example.root", "recreate");

	TH1D *h = new TH1D("hist", ";x", 100, -5, 5);
	for (unsigned int i = 0; i < 1000; i++)
		h->Fill(gRandom->Gaus());
	h->Fit("gaus");
	h->Write();

	TH2D *h2 = new TH2D("hist2", "", 10, 0., 10., 10, 0., 10.);
	for (unsigned int i = 1; i <= h2->GetNbinsX(); i++) {
		for (unsigned int j = 1; j <= h2->GetNbinsY(); j++) {
			double x = h2->GetXaxis()->GetBinCenter(i);
			double y = h2->GetYaxis()->GetBinCenter(j);

			double v = x*x + y*y;
			h2->SetBinContent(i, j, v);
		}
	}
	h2->Write();
	
	TGraphErrors *g = new TGraphErrors();
	g->SetName("graph");
	for (double x = -5; x <= 5; x += 0.5) {
		int idx = g->GetN();
		g->SetPoint(idx, x, x*x);
		g->SetPointError(idx, 0, 1. + fabs(x));
	}
	g->Write();
	
	TGraph *g_sc = new TGraph();
	g_sc->SetName("scatter");
	for (unsigned int i = 0; i < 10000; i++)
		g_sc->SetPoint(i, gRandom->Gaus(), gRandom->Gaus());
	g_sc->Write();

	TGraph2D *g2 = new TGraph2D();
	g2->SetName("graph2");
	for (double x = -5; x <= +5; x += 0.5)
		for (double y = -5; y <= +5; y += 0.5)
			g2->SetPoint(g2->GetN(), x, y, x*x + y*y);
	g2->Write();

	TCanvas *c = new TCanvas("canvas");
	h->Draw();
	g->Draw("l");
	c->Write();
	
	TCanvas *c2 = new TCanvas("canvas2");
	g2->Draw("cont");
	c2->Write();

	f->mkdir("dir1");
	f->mkdir("dir2");
	f->mkdir("dir3");

	f->cd("dir1");
	h->Write();
	
	f->cd("dir2");
	c->Write();

	f->cd("dir3");
	h->SetName("a#weird|name");
	h->Write();
}
