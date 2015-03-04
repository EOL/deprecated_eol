require "spec_helper"

describe "Google Analytics Stats Page" do

  before(:all) do
    load_foundation_cache
    Capybara.reset_sessions!
    @taxon_concept = build_taxon_concept(comments: [], bhl: [], toc: [], sounds: [], youtube: [], flash: [], images: [])
    @user = User.gen(username: 'anything')
    @user.password = 'whatevs'
    @user.save
    @content_partner = ContentPartner.gen(user: @user)

    last_month = Date.today - 1.month
    @year = last_month.year
    @month = last_month.month
    @partner_summary = GoogleAnalyticsPartnerSummary.gen(year: @year, month: @month, user: @user)
    @summary = GoogleAnalyticsSummary.gen(year: @year, month: @month)
    @page_stats = GoogleAnalyticsPageStat.gen(year: @year, month: @month, taxon_concept: @taxon_concept )
    @partner_taxa = GoogleAnalyticsPartnerTaxon.gen(year: @year, month: @month, taxon_concept: @taxon_concept, user: @user )
  end

  after(:all) do
    truncate_all_tables
  end

  before(:each) do
    login_as(@user)
  end

  after(:each) do
    visit('/logout')
  end

  it "should render monthly_page_stats page" do
    visit("/content_partners/#{@content_partner.id}/statistics")
    body.should have_tag("form[action='/content_partners/#{@content_partner.id}/statistics']")
    body.should include @summary.pageviews.to_s
    body.should include @partner_summary.page_views.to_s
    body.should include @page_stats.unique_page_views.to_s
  end

  it "should get data from a form and display it" do
   now = Time.now.utc - 2.months
   year = @year - 1
   month = @month - 1
   month = 12 if month == 0
   partner_summary = GoogleAnalyticsPartnerSummary.gen(year: year, month: month, user: @user)
   summary = GoogleAnalyticsSummary.gen(year: year, month: month)
   page_stats = GoogleAnalyticsPageStat.gen(year: year, month: month, taxon_concept: @taxon_concept )
   partner_taxa = GoogleAnalyticsPartnerTaxon.gen(year: year, month: month, taxon_concept: @taxon_concept, user: @user )
   login_as @user
   visit("/content_partners/#{@content_partner.id}/statistics")
   select summary.year.to_s, from: 'date_year'
   select Date::MONTHNAMES[summary.month], from: 'date_month'
   click_button 'Change'
   body.should have_tag("form[action='/content_partners/#{@content_partner.id}/statistics']")
   body.should include summary.pageviews.to_s
   body.should include partner_summary.page_views.to_s
   body.should include page_stats.unique_page_views.to_s
 end

end
