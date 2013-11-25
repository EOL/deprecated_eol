require 'spec_helper'

describe 'taxa/data/index' do

  def assign_nothing
    assign(:assistive_section_header, 'whatever')
    assign(:recently_used, nil)
    assign(:taxon_page, @taxon_page)
    assign(:taxon_data, @taxon_page.data)
    @data = TaxonDataSet.new([])
    @data.stub(:empty?).and_return(false)
    assign(:data_point_uris, @data)
    assign(:toc_id, nil)
    assign(:selected_data_point_uri_id, nil)
    assign(:categories, TocItem.for_uris(Language.english).select{ |toc| @taxon_page.data.categories.include?(toc) })
    assign(:toc_id, nil)
    assign(:supress_disclaimer, true)
  end

  before(:all) do
    Visibility.create_enumerated
    Vetted.create_enumerated
    CuratorLevel.create_enumerated
    Language.create_english # :\
    @anonymous = EOL::AnonymousUser.new('en')
    @curator = FactoryGirl.create(:curator)
    @taxon = TaxonConcept.gen()
  end

  before(:each) do
    view.stub(:meta_open_graph_data).and_return([])
    view.stub(:tweet_data).and_return({})
  end

  describe '(logged out)' do

    before(:each) do
      @taxon_page = TaxonUserClassificationFilter.new(@taxon, @anonymous)
      view.stub(:current_user).and_return(@anonymous)
      assign_nothing
    end

    it 'should NOT show the key' do
      render
      expect(rendered).not_to include(I18n.t(:data_tab_curator_key_exemplar, image: "", link: taxon_overview_path(@taxon_page)))
    end

  end

  describe '(as a full curator)' do

    before(:each) do
      @taxon_page = TaxonUserClassificationFilter.new(@taxon, @curator)
      view.stub(:current_user).and_return(@curator)
      assign_nothing
    end

    it 'should show the key' do
      render
      expect(rendered).to include(I18n.t(:data_tab_curator_key_exemplar, image: "", link: taxon_overview_path(@taxon_page)))
    end

  end

end
