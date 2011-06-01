require File.dirname(__FILE__) + '/../spec_helper'

describe 'Data Object Page' do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    # Somewhat empty, to speed things up:
    @tc = build_taxon_concept(:images => [:object_cache_url => Factory.next(:image)], :toc => [])
    @another_name = 'Whatever'
    @another_tc = build_taxon_concept(:images => [], :toc => [], :scientific_name => @another_name)
    @single_name = 'Singularus namicus'
    @singular_tc = build_taxon_concept(:images => [], :toc => [], :scientific_name => @single_name)
    @singular_he = @singular_tc.entry
    @curator = build_curator(@tc)
    @another_curator = build_curator(@tc)
    @image = @tc.data_objects.select { |d| d.data_type.label == "Image" }[0]
    @image.feed.post @feed_body_1 = "Something"
    @image.feed.post @feed_body_2 = "Something Else"
    @image.feed.post @feed_body_3 = "Something More"
    @extra_he = @another_tc.entry
    @image.add_curated_association(@curator, @extra_he)

    # Build data_object without comments
    @dato_no_comments = build_data_object('Image', 'No comments',
    :num_comments => 0,
    :object_cache_url => Factory.next(:image),
    :vetted => Vetted.trusted,
    :visibility => Visibility.visible)
    @dato_comments_no_pagination = build_data_object('Image', 'Some comments',
    :num_comments => 4,
    :object_cache_url => Factory.next(:image),
    :vetted => Vetted.trusted,
    :visibility => Visibility.visible)
    @dato_comments_with_pagination = build_data_object('Image', 'Lots of comments',
    :num_comments => 15,
    :object_cache_url => Factory.next(:image),
    :vetted => Vetted.trusted,
    :visibility => Visibility.visible)
    @dato_untrusted = build_data_object('Image', 'removed',
    :num_comments => 0,
    :object_cache_url => Factory.next(:image),
    :vetted => Vetted.untrusted,
    :visibility => Visibility.invisible)
  end

  it "should render" do
    visit("/data_objects/#{@image.id}")
    page.status_code.should == 200
  end

  it "should show data object attribution" do
    visit("/data_objects/#{@image.id}")
    body.should have_tag('dl#attribution[data-object_id=?]', "#{@image.id}")
  end

  it "should show the permalink" do
    visit("/data_objects/#{@image.id}")
    page.should have_content("Permalink")
    body.should have_tag('dd', :text => "http://#{$SITE_DOMAIN_OR_IP}/data_objects/#{@image.id}")
  end

  it "should show image description for image objects" do
    visit("/data_objects/#{@image.id}")
    body.should include('<h3>Description</h3>')
    body.should include("<div class='description #{@image.id}'>")
    body.should include @image.description
  end

  it "should not show comments section if there are no comments" do
    visit("/data_objects/#{@dato_no_comments.id}")
    page.status_code.should == 200
    page.should have_no_xpath("//div[@id='commentsContain']")
  end

  it "should not show pagination if there are less than 10 comments" do
    visit("/data_objects/#{@dato_comments_no_pagination.id}")
    page.status_code.should == 200
    page.should have_xpath("//div[@id='commentsContain']")
    page.should have_no_xpath("//div[@id='commentsContain']/div[@id='pagination']")
  end

  it "should show pagination if there are more than 10 comments" do
    visit("/data_objects/#{@dato_comments_with_pagination.id}")
    page.status_code.should == 200
    page.should have_xpath("//div[@id='commentsContain']/div[@class='pagination']")
  end

  # TODO - change this to open the data object page, NOT the overview page!
  it "should have a taxon_concept link for untrusted image, but following the link should show a warning" # do
    # visit("/data_objects/#{@dato_untrusted.id}")
    # page.status_code.should == 200
    # page_link = "/pages/#{@tc.id}?image_id=#{@dato_untrusted.id}"
    # page.body.should include(page_link)
    # visit(page_link)
    # page.status_code.should == 200
    # page.body.should include('Image is no longer available')
  # end

  it "should not show a link for data_object if its taxon page is not in database anymore" do
    tc = build_taxon_concept(:images => [:object_cache_url => Factory.next(:image)], :toc => [], :published => false)
    image = tc.data_objects.select { |d| d.data_type.label == "Image" }[0]
    tc.published = false
    tc.save!
    dato_no_tc = build_data_object('Image', 'unlinked',
    :num_comments => 0,
    :object_cache_url => Factory.next(:image),
    :vetted => Vetted.trusted,
    :visibility => Visibility.visible)
    dato_no_tc.get_taxon_concepts[0].published?.should be_false
    visit("/data_objects/#{dato_no_tc.id}")
    page_link = "/pages/#{tc.id}?image_id="
    page.body.should_not include(page_link)
    page.body.should include("associated with the deprecated page")
  end

  it 'should show the activity feed' do
    visit("/data_objects/#{@image.id}")
    page.body.should have_tag('#feed_items ul') do
      with_tag('.details', :text => /#{@feed_body_1}/)
      with_tag('.details', :text => /#{@feed_body_2}/)
      with_tag('.details', :text => /#{@feed_body_3}/)
    end
  end

  it 'should show an empty feed' do
    visit("/data_objects/#{@dato_untrusted.id}")
    page.body.should have_tag('#feed_items', :text => /no activity/i)
  end

  it 'should allow a curator to remove an association' do
    login_as @curator
    visit("/data_objects/#{@image.id}")
    page.body.should have_tag('ul#associations') do
      with_tag('a', :text => 'Remove association')
    end
    page.body.should have_tag('a', :text => @another_name)
    click_link "remove_association_#{@extra_he.id}"
    page.body.should_not have_tag('a', :text => @another_name)
  end

  # NOTE - I wanted to see how it "felt" to write longer individual tests.  These run faster, but how does it
  # actually work in practice?  This is an experiment.
  # The first thing I have to say about it is that the name is obnoxiously long.
  it 'should allow a curator to add an association...' do
    login_as @curator
    visit("/data_objects/#{@image.id}")
    xpect 'the page does not yet have our association'
    page.body.should_not have_tag('a', :text => @single_name)
    fill_in 'add_association', :with => @single_name
    click_button 'Add'
    remove_path = remove_association_path(:id => @image.id, :hierarchy_entry_id => @singular_he.id)
    xpect 'the page now has our association'
    page.body.should have_tag('a', :text => @single_name)
    xpect 'the page has a link to remove the association'
    # NOTE: this wasn't working when we used :href as an argument to #have_tag, so we're using XPath-y syntax:
    page.body.should have_tag('a[href=?]', remove_path)
    visit('/logout')
    login_as @another_curator
    visit("/data_objects/#{@image.id}")
    xpect 'the page does NOT have a link to remove the association after logging out'
    page.body.should_not have_tag('a[href=?]', remove_path)
  end

end
