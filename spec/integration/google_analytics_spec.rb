require File.dirname(__FILE__) + '/../spec_helper'

describe "Google Analytics Stats Page" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @taxon_concept = build_taxon_concept
    @user = User.gen(:username => 'anything')
    @user.password = 'whatevs'
    @user.save
    @content_partner = ContentPartner.gen(:user => @user)

    year = 1.month.ago.year
    month = 1.month.ago.month
    @partner_summary = GoogleAnalyticsPartnerSummary.gen(:year => year, :month => month, :user => @user)
    @summary = GoogleAnalyticsSummary.gen(:year => year, :month => month)
    @page_stats = GoogleAnalyticsPageStat.gen(:year => year, :month => month, :taxon_concept => @taxon_concept )
    @partner_taxa = GoogleAnalyticsPartnerTaxon.gen(:year => year, :month => month, :taxon_concept => @taxon_concept, :user => @user )
  end

  after(:all) do
    truncate_all_tables
  end

  before(:each) do
    I18n.locale = 'en'
    login_as(@user)
  end

  after(:each) do
    visit('/logout')
  end

  it "should render monthly_page_stats page" do
    visit("/content_partners/#{@content_partner.id}/statistics")
    body.should have_tag("form[action=/en/content_partners/#{@content_partner.id}/statistics]")
    body.should include @summary.pageviews.to_s
    body.should include @partner_summary.page_views.to_s
    body.should include @page_stats.unique_page_views.to_s
  end

  it "should get data from a form and display it" do
   year = 2.month.ago.year
   month = 2.month.ago.month
   partner_summary = GoogleAnalyticsPartnerSummary.gen(:year => year, :month => month, :user => @user)
   summary = GoogleAnalyticsSummary.gen(:year => year, :month => month)
   page_stats = GoogleAnalyticsPageStat.gen(:year => year, :month => month, :taxon_concept => @taxon_concept )
   partner_taxa = GoogleAnalyticsPartnerTaxon.gen(:year => year, :month => month, :taxon_concept => @taxon_concept, :user => @user )
   visit("/content_partners/#{@content_partner.id}/statistics", :method => :post, :params => {:year_month => "#{year}_#{month}", :user_id => @user.id})
   body.should have_tag("form[action=/en/content_partners/#{@content_partner.id}/statistics]")
   body.should include summary.pageviews.to_s
   body.should include partner_summary.page_views.to_s
   body.should include page_stats.unique_page_views.to_s
 end

end
