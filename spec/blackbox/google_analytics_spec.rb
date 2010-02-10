require File.dirname(__FILE__) + '/../spec_helper'


describe "google analytics stats page" do

  before(:all) do
    Scenario.load :foundation
    @tc = build_taxon_concept
    @pass  = 'timey-wimey'
    @agent = Agent.gen(:hashed_password => Digest::MD5.hexdigest(@pass))
    @cp    = ContentPartner.gen(:agent => @agent)
    
    year = 1.month.ago.year
    month = 1.month.ago.month
    @partner_summary = GoogleAnalyticsPartnerSummary.gen(:year => year, :month => month, :agent => @agent)
    @summary = GoogleAnalyticsSummary.gen(:year => year, :month => month)
    @page_stats = GoogleAnalyticsPageStat.gen(:year => year, :month => month, :taxon_concept => @tc )    
    @partner_taxa = GoogleAnalyticsPartnerTaxon.gen(:year => year, :month => month, :taxon_concept => @tc, :agent => @agent )
  end

  after(:all) do
    truncate_all_tables
  end
  
  it "should show content partner page" do
    login_content_partner(:username => @agent.username, :password => @pass)
    body  = request('/content_partner').body
    body.should include "Hello"
  end
  
  it "should render monthly_page_stats page" do
    login_content_partner(:username => @agent.username, :password => @pass)
    res = request("/content_partner/reports/monthly_page_stats")
    res.body.should have_tag("form[action=/content_partner/reports/monthly_page_stats]")
    res.body.should include @summary.pageviews.to_s
    res.body.should include @partner_summary.page_views.to_s
    res.body.should include @page_stats.unique_page_views.to_s
  end
  
  it "should get data from a form and display it" do

    
    login_content_partner(:username => @agent.username, :password => @pass)
    
    year = 2.month.ago.year
    month = 2.month.ago.month
    
    partner_summary = GoogleAnalyticsPartnerSummary.gen(:year => year, :month => month, :agent => @agent)
    summary = GoogleAnalyticsSummary.gen(:year => year, :month => month)
    page_stats = GoogleAnalyticsPageStat.gen(:year => year, :month => month, :taxon_concept => @tc )    
    partner_taxa = GoogleAnalyticsPartnerTaxon.gen(:year => year, :month => month, :taxon_concept => @tc, :agent => @agent )
    
    res = request('/content_partner/reports/monthly_page_stats', :method => :post, :params => {:year_month => "#{year}_#{month}", :agent_id => @agent.id})
    res.body.should have_tag("form[action=/content_partner/reports/monthly_page_stats]")
    res.body.should include summary.pageviews.to_s
    res.body.should include partner_summary.page_views.to_s
    res.body.should include page_stats.unique_page_views.to_s
  end
  
end