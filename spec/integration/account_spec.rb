require File.dirname(__FILE__) + '/../spec_helper'

shared_examples_for "all accounts" do
  it "should behave like all users"
end

describe 'Account Pages' do

  before(:all) do
    # truncate_all_tables
    # load_foundation_cache
    # Capybara.reset_sessions!
    # @overview = TocItem.overview
    # @html = '<script>I should have been stripped from teaser</script>' +
    #         '<table>' +
    #         '  <thead>' +
    #         '    <tr><th>I should have been stripped from teaser</th><th>' + Faker::Lorem.sentence(3) + '</th></tr>' +
    #         '  </thead>' +
    #         '  <tbody>' +
    #         '    <tr><td>' + Faker::Lorem.sentence(8) + '</td><td>'  + Faker::Lorem.sentence(3) + '</td></tr>' +
    #         '    <tr><td>' + Faker::Lorem.sentence(2) + '</td><td>'  + Faker::Lorem.sentence(5) + '</td></tr>' +
    #         '  </tbody>' +
    #         '</table>' +
    #         '<div><h1>' + Faker::Lorem.sentence(4) + '</h1>' +
    #         '  <p><i>I am an allowed tag</i> ' + Faker::Lorem.paragraph(6) + '</p>' +
    #         '  <p>' + Faker::Lorem.paragraph(3) + '</p>' +
    #         '  <p>I should have been truncated from teaser</p>' +
    #         '</div>'
    # 
    # @text = Faker::Lorem.paragraphs(6)
    # @taxon_concept = build_taxon_concept(:images => [ { :vetted => Vetted.unknown },
    #                                                   { :vetted => Vetted.unknown } ],
    #                                      :toc => [ { :toc_item => @overview,
    #                                                  :description => @html,
    #                                                  :vetted => Vetted.unknown },
    #                                                { :toc_item => @overview,
    #                                                  :description => @text,
    #                                                  :vetted => Vetted.unknown },] )
    # @credentials = 'This has a <a href="linky">link</a> <b>this is bold<br />as is this</b> and <script type="text/javascript">alert("hi");</script>'
    # @non_curator = User.gen
    # @user = build_curator(@taxon_concept, :credentials => @credentials)
    # # @taxon_concept.images[0].curate(@user, { :vetted_id => Vetted.trusted.id })
    # # @taxon_concept.images[1].curate(@user, { :vetted_id => Vetted.untrusted.id })
    # # @taxon_concept.overview[0].curate(@user, { :vetted_id => Vetted.trusted.id })
    # # @taxon_concept.overview[1].curate(@user, { :vetted_id => Vetted.untrusted.id })
    # @total_datos_curated = 4
    # @show_datos_curated_path = "/users/objects_curated/#{@user.id}"
    # @permalink_path = "/data_objects/#{@taxon_concept.images[0][:id]}"
    # @taxon_page_path = "/pages/#{@taxon_concept[:id]}"
    # account_show_path = "/users/#{@user.id}"
    # visit(account_show_path)
    # @page = page
    # @body = body
    # debugger
    # visit(@show_datos_curated_path)
    # @objects_curated_page = page
    # @objects_curated_body = body
  end

  it_should_behave_like "all accounts"

  it "should show account page"
#    _account_show_path = "/users/#{@user.id}"
#    visit(_account_show_path)
#    current_path.should == _account_show_path


  it 'should allow bold font style in credentials text on account page'
    #@body.should have_tag('div#credentials b')


  it 'should allow hyperlinks in credentials text on account page'
    #@body.should have_tag('a[href="linky"]')


  it 'should allow line breaks in credentials text on account page'
    #@body.should have_tag('div#credentials br')


  it 'should not allow dynamic script in credentials text on account page'
    #@body.should_not have_tag('script', :text => 'alert("hi");')


  it 'should show the number of data objects curated with hyperlink on account page'
  #   @body.should have_tag('div#activity') do
  #     with_tag('a', :attributes => { :href => @show_datos_curated_path }, :text => @total_datos_curated)
  #   end
  # end
  #
  #
  it 'should strip most html tags from descriptions on the show objects curated page'
  #   @objects_curated_body.should have_tag('td.description')
  #   @objects_curated_body.should_not have_tag('td.description script')
  #   @objects_curated_body.should_not have_tag('td.description table')
  #   @objects_curated_body.should_not have_tag('td.description div')
  #   @objects_curated_body.should_not have_tag('td.description p')
  #   @objects_curated_page.should_not have_content('I should have been stripped from teaser')
  #   @objects_curated_body.should have_tag('td.description i')
  # end

  it 'should show teaser views of descriptions on the show objects curated page' do
    # @objects_curated_page.should_not have_content('I should have been stripped from teaser')
  end

  it 'should show data object permalinks on the show objects curated page'
  #   @objects_curated_body.should have_tag('td.description a', :attributes => { :href => @permalink_path }, :text => "Permalink")
  # end
  #
  it 'should show scientific names with hyperlinks on the show objects curated page'
  #   @objects_curated_body.should have_tag('table#show_objects_curated a', :attributes => { :href => @taxon_page_path }) do
  #     with_tag('i', :text => @taxon_concept.hierarchy_entries.first.name[:canonical])
  #   end
  # end

end

