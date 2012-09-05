# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

# TODO - these specs only pass when they're all passing. If one fails, the data isn't reset.

def review_status_should_be(id, vetted, visible, options = {})
  page.body.should have_tag("form.review_status") do
    with_tag("select option[selected=selected]", :text => vetted)
    with_tag("select option[selected=selected]", :text => visible)
    if options.has_key? :duplicate
      if options[:duplicate]
        with_tag("input[id='#{id}_untrust_reason_duplicate'][checked]")
      else
        without_tag("input[id='#{id}_untrust_reason_duplicate'][checked]")
      end
    end
    if options.has_key? :poor
      if options[:poor]
        with_tag("input[id='#{id}_untrust_reason_poor'][checked]")
      else
        without_tag("input[id='#{id}_untrust_reason_poor'][checked]")
      end
    end
    if options.has_key? :incorrect
      if options[:incorrect]
        with_tag("input[id='#{id}_untrust_reason_incorrect'][checked]")
      else
        without_tag("input[id='#{id}_untrust_reason_incorrect'][checked]")
      end
    end
    if options.has_key? :misidentified
      if options[:misidentified]
        with_tag("input[id='#{id}_untrust_reason_misidentified'][checked]")
      else
        without_tag("input[id='#{id}_untrust_reason_misidentified'][checked]")
      end
    end
  end
end

describe 'Data Object Page' do

  before(:all) do
    load_foundation_cache
    # Somewhat empty, to speed things up:
    @tc = build_taxon_concept(:images => [:object_cache_url => FactoryGirl.generate(:image)], :toc => [])
    @another_name = 'Whatever'
    @another_tc = build_taxon_concept(:images => [], :toc => [], :scientific_name => @another_name)
    @single_name = 'Singularus namicus'
    @singular_tc = build_taxon_concept(:images => [], :toc => [], :scientific_name => @single_name)
    @singular_he = @singular_tc.entry
    @assistant_curator = build_curator(@tc, :level=>:assistant)
    @full_curator = build_curator(@tc, :level=>:full)
    @master_curator = build_curator(@tc, :level=>:master)
    @admin = User.gen(:admin=>1)
    @image = @tc.data_objects.select { |d| d.data_type.label == "Image" }[0]
    @extra_he = @another_tc.entry
    @image.add_curated_association(@full_curator, @extra_he)

    @dato_no_comments = build_data_object('Image', 'No comments',
    :num_comments => 0,
    :object_cache_url => FactoryGirl.generate(:image),
    :vetted => Vetted.trusted,
    :visibility => Visibility.visible)
    @dato_comments_no_pagination = build_data_object('Image', 'Some comments',
    :num_comments => 4,
    :object_cache_url => FactoryGirl.generate(:image),
    :vetted => Vetted.trusted,
    :visibility => Visibility.visible)
    @dato_comments_with_pagination = build_data_object('Image', 'Lots of comments',
    :num_comments => 15,
    :object_cache_url => FactoryGirl.generate(:image),
    :vetted => Vetted.trusted,
    :visibility => Visibility.visible)
    @dato_untrusted = build_data_object('Image', 'removed',
    :num_comments => 0,
    :object_cache_url => FactoryGirl.generate(:image),
    :vetted => Vetted.untrusted,
    :visibility => Visibility.invisible)
    @user_submitted_text = @tc.add_user_submitted_text(:user => @full_curator)
    @user = User.gen
    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
  end

  before(:each) do
    @image.data_objects_hierarchy_entries.first.trust(@full_curator)
    @image.data_objects_hierarchy_entries.first.show(@full_curator)
    @image.curated_data_objects_hierarchy_entries.each do |assoc|
      next if assoc.hierarchy_entry_id == @extra_he.id # Keep this one.
      @image.remove_curated_association(assoc.user, assoc.hierarchy_entry) if # ...only if it's real:
        CuratedDataObjectsHierarchyEntry.find_by_data_object_guid_and_hierarchy_entry_id(assoc.data_object_guid,
                                                                                         assoc.hierarchy_entry_id)
    end
  end

  it "should render" do
    visit("/data_objects/#{@image.id}")
    page.status_code.should == 200
  end

  it "should show data object attribution" do
    visit("/data_objects/#{@image.id}")
    # Note that the spacing here (ATM, space followed by a newline) is pretty fragile... but I don't know how to make
    # it more robust without a regex.
    body.should have_tag('.source p', :text => "Author: \n#{@image.authors.first.full_name}")
  end

  it "should show image description for image objects" do
    visit("/data_objects/#{@image.id}")
    body.should have_tag('.article .copy', :text => @image.description)
  end

  it "should not show comments section if there are no comments (obsolete?)" do
    visit("/data_objects/#{@dato_no_comments.id}")
    page.status_code.should == 200
    page.should have_no_xpath("//div[@id='commentsContain']")
  end

  it "should not show pagination if there are less than 10 comments (waiting on feed items adjustments)"

  it "should show pagination if there are more than 10 comments (waiting on feed items adjustments)"

  # TODO - this should open the data object page, NOT the overview page!
  it "should have a taxon_concept link for untrusted image, but following the link should show a warning"

  it "should not show a link for data_object if its taxon page is not in database anymore" do
    tc = build_taxon_concept(:images => [:object_cache_url => FactoryGirl.generate(:image)], :toc => [], :published => false)
    image = tc.data_objects.select { |d| d.data_type.label == "Image" }[0]
    tc.published = false
    tc.save!
    dato_no_tc = build_data_object('Image', 'unlinked',
    :num_comments => 0,
    :object_cache_url => FactoryGirl.generate(:image),
    :vetted => Vetted.trusted,
    :visibility => Visibility.visible)
    dato_no_tc.get_taxon_concepts[0].published?.should be_false
    visit("/data_objects/#{dato_no_tc.id}")
    page_link = "/pages/#{tc.id}?image_id="
    page.body.should_not include(page_link)
  end

  it 'should allow a curator to add an association' do
    login_as @full_curator
    visit("/data_objects/#{@dato_no_comments.id}")
    page.body.should have_tag('#sidebar .header a', :text => 'Add new association')
    page.body.should_not have_tag('form.review_status a', :text => 'Remove association')
    click_link("Add new association")
    fill_in 'name', :with => @another_name
    click_button "find taxa"
    click_button "add association"
    page.body.should have_tag('form.review_status a', :text => 'Remove association')
    visit('/logout')
  end

  it 'should show proper vetted & visibility statuses of associations to the anonymous users' do
    visit("/data_objects/#{@image.id}")
    page.body.should have_tag("ul.review_status") do
      with_tag("li:first-child .trusted", :text => "Trusted")
    end
    visit("/data_objects/#{@dato_untrusted.id}")
    page.body.should_not have_tag("ul.review_status")
    page.body.should include("not associated with any published taxa")
  end

  it 'should be able curate a DOHE association as Unreviewed, Untrusted and Trusted' do
    login_as @full_curator
    visit("/data_objects/#{@image.id}")
    taid = @image.all_associations.first.id
    review_status_should_be(taid, 'Trusted', 'Visible')
    select "Unreviewed", :from => "vetted_id_#{taid}"
    select "Hidden", :from => "visibility_id_#{taid}"
    lambda { click_button "Save changes" }.should raise_error
    visit("/data_objects/#{@image.id}")
    review_status_should_be(taid, 'Trusted', 'Visible', :duplicate => false, :poor => false)
    select "Unreviewed", :from => "vetted_id_#{taid}"
    select "Hidden", :from => "visibility_id_#{taid}"
    check "#{taid}_untrust_reason_duplicate"
    click_button "Save changes"
    review_status_should_be(taid, 'Unreviewed', 'Hidden', :duplicate => true, :poor => false)
    select "Untrusted", :from => "vetted_id_#{taid}"
    lambda { click_button "Save changes" }.should raise_error
    visit("/data_objects/#{@image.id}")
    review_status_should_be(taid, 'Unreviewed', 'Hidden', :duplicate => true, :poor => false)
    select "Untrusted", :from => "vetted_id_#{taid}"
    check "#{taid}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(taid, 'Untrusted', 'Hidden', :misidentified => true, :incorrect => false)
    select "Trusted", :from => "vetted_id_#{taid}"
    select "Visible", :from => "visibility_id_#{taid}"
    check "#{taid}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(taid, 'Trusted', 'Visible', :misidentified => false, :incorrect => false)
    visit('/logout')
  end

  it 'should be able curate a CDOHE association as Unreviewed, Untrusted and Trusted' do
    login_as @full_curator
    visit("/data_objects/#{@image.id}")
    trusted_association = @image.all_associations.last
    review_status_should_be(@image.id, 'Trusted', 'Visible')
    select "Unreviewed", :from => "vetted_id_#{trusted_association.id}"
    select "Hidden", :from => "visibility_id_#{trusted_association.id}"
    lambda { click_button "Save changes" }.should raise_error
    visit("/data_objects/#{@image.id}")
    review_status_should_be(@image.id, 'Trusted', 'Visible', :duplicate => false, :poor => false)
    select "Unreviewed", :from => "vetted_id_#{trusted_association.id}"
    select "Hidden", :from => "visibility_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_duplicate"
    click_button "Save changes"
    review_status_should_be(@image.id, 'Unreviewed', 'Hidden', :duplicate => true, :poor => false)
    select "Untrusted", :from => "vetted_id_#{trusted_association.id}"
    lambda { click_button "Save changes" }.should raise_error
    visit("/data_objects/#{@image.id}")
    review_status_should_be(@image.id, 'Unreviewed', 'Hidden', :duplicate => true, :poor => false)
    select "Untrusted", :from => "vetted_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(@image.id, 'Untrusted', 'Hidden', :misidentified => true, :incorrect => false)
    select "Trusted", :from => "vetted_id_#{trusted_association.id}"
    select "Visible", :from => "visibility_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(@image.id, 'Trusted', 'Visible', :misidentified => false, :incorrect => false)
    visit('/logout')
  end

  it 'should be able curate a UDO association as Unreviewed, Untrusted and Trusted' do
    login_as @full_curator
    visit("/data_objects/#{@user_submitted_text.id}")
    trusted_association = @user_submitted_text.all_associations.first
    review_status_should_be(@image.id, 'Trusted', 'Visible')
    select "Unreviewed", :from => "vetted_id_#{trusted_association.id}"
    select "Hidden", :from => "visibility_id_#{trusted_association.id}"
    lambda { click_button "Save changes" }.should raise_error
    visit("/data_objects/#{@user_submitted_text.id}")
    select "Unreviewed", :from => "vetted_id_#{trusted_association.id}"
    select "Hidden", :from => "visibility_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_duplicate"
    click_button "Save changes"
    review_status_should_be(@image.id, 'Unreviewed', 'Hidden', :duplicate => true, :poor => false)
    select "Untrusted", :from => "vetted_id_#{trusted_association.id}"
    lambda { click_button "Save changes" }.should raise_error
    visit("/data_objects/#{@user_submitted_text.id}")
    review_status_should_be(@image.id, 'Unreviewed', 'Hidden', :duplicate => true, :poor => false)
    select "Untrusted", :from => "vetted_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(@image.id, 'Untrusted', 'Hidden', :misidentified => true, :incorrect => false)
    select "Trusted", :from => "vetted_id_#{trusted_association.id}"
    select "Visible", :from => "visibility_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(@image.id, 'Trusted', 'Visible', :misidentified => false, :incorrect => false)
    visit('/logout')
  end

  it 'should not allow assistant curators to remove curated associations' do
    login_as @assistant_curator
    visit("/data_objects/#{@image.id}")
    page.body.should_not have_tag('form.review_status a', :text => 'Remove association')
    visit('/logout')
  end

  it 'should allow a full curators to remove self added associations' do
    login_as @full_curator
    visit("/data_objects/#{@image.id}")
    page.body.should have_tag('form.review_status a', :text => 'Remove association')
    page.body.should have_tag('form.review_status a', :text => @another_name)
    click_link "remove_association_#{@extra_he.id}"
    debugger if body =~ @another_name # Trying to find an intermittent problem...
    page.body.should_not have_tag('form.review_status a', :text => @another_name)
    visit('/logout')
  end

  it 'should allow a master curators to remove curated associations' do
    login_as @master_curator
    visit("/data_objects/#{@image.id}")
    page.body.should_not have_tag('form.review_status a', :text => 'Remove association')
    visit('/logout')
    @image.add_curated_association(@full_curator, @extra_he)
    login_as @master_curator
    visit("/data_objects/#{@image.id}")
    page.body.should have_tag('form.review_status a', :text => 'Remove association')
    page.body.should have_tag('form.review_status a', :text => @another_name)
    click_link "remove_association_#{@extra_he.id}"
    page.body.should_not have_tag('form.review_status a', :text => @another_name)
    visit('/logout')
  end

  it 'should allow logged in users to rate' do
    login_as @user
    visit data_object_path(@image)
    body.should have_tag("#sidebar .ratings .rating") do
      with_tag('h5', :text => "Your rating")
    end
    click_link('Change rating to 3 of 5')
    current_url.should match /#{data_object_path(@image)}/
    body.should include('Rating was added successfully')
    body.should have_tag("#sidebar .ratings .rating") do
      with_tag('h5', :text => "Your rating")
      with_tag('ul li', :text => "Your current rating: 3 of 5")
    end
    visit('/logout')
  end

  it 'should allow logged in users to post a comment' do
    comment = "Test comment by a logged in user."
    login_as @user
    visit("/data_objects/#{@image.id}")
    body.should_not have_tag("blockquote", :text => comment)
    body.should have_tag(".comment #comment_body")
    body.should have_tag("#new_comment .actions input", :val => "Post Comment")
    within(:xpath, '//form[@id="new_comment"]') do
      fill_in 'comment_body', :with => comment
      click_button "Post Comment"
    end
    visit("/data_objects/#{@image.id}")
    body.should have_tag("blockquote", :text => comment)
    visit('/logout')
  end

  it "should not show copyright symbol for public domain objects" do
    @image.license = License.public_domain
    @image.rights_holder = ""
    @image.save
    visit("/data_objects/#{@image.id}")
    body.should_not match('&copy;')
    @image.license = License.cc
    @image.rights_holder = "Someone"
    @image.save
    visit("/data_objects/#{@image.id}")
    body.should match('©')
  end

  it 'should save owner as rights holder(if not specified) while editing an article' do
    user_submitted_text = @tc.add_user_submitted_text(:user => @user)
    login_as @user
    visit("/data_objects/#{user_submitted_text.id}")
    body.should_not have_tag(".article.list ul li a[href='/data_objects/#{user_submitted_text.id}']")
    click_link "Edit this article"
    fill_in 'data_object_rights_holder', :with => ""
    $FOO = true
    click_button "Save article"
    body.should have_tag(".article.list ul li a[href='/data_objects/#{user_submitted_text.id}']")
  end

  it "should link agents to their homepage, and add http if the link does not include it" do
    agent = Agent.gen(:full_name => 'doesnt matter', :homepage => 'www.somesite.com')
    # TODO - this used to use create_without_callbacks, which is gone in Rails 3, and the reason for needing it was
    # not explained. Look into it.
    @image.agents_data_objects << AgentsDataObject.gen(:agent => agent, :agent_role => AgentRole.author, :data_object => @image)
    @image.save
    visit("/data_objects/#{@image.id}")
    body.should have_tag("a[href='http://www.somesite.com']", :text => agent.full_name)
  end

  it "should allow assistant curators to add and/or remove associations, but not to curate them" do
    @image.add_curated_association(@assistant_curator, @extra_he)
    login_as @assistant_curator
    visit("/data_objects/#{@image.id}")
    page.body.should_not have_tag('ul.review_status select')
    page.body.should have_tag('#sidebar .header a', :text => 'Add new association')
    page.body.should have_tag('.review_status li a', :text => 'Remove association')
    page.body.should have_tag('.review_status li a', :text => @another_name)
    # TODO - sometimes this works, sometimes it doesn't.  Why?  I assume the associations are changing between tests.
    lambda { click_link "remove_association_#{@extra_he.id}" }.should raise_error(EOL::Exceptions::WrongCurator)
    #page.body.should_not have_tag('.review_status li a', :text => @another_name)
    visit('/logout')
  end

  it "should allow data object owners to add and/or remove associations, but not to curate them" do
    user_submitted_text = @tc.add_user_submitted_text(:user => @user)
    user_submitted_text.add_curated_association(@user, @extra_he)
    login_as @user
    visit("/data_objects/#{user_submitted_text.id}")
    page.body.should_not have_tag('ul.review_status select')
    page.body.should have_tag('#sidebar .header a', :text => 'Add new association')
    page.body.should have_tag('.review_status li a', :text => 'Remove association')
    page.body.should have_tag('.review_status li a', :text => @another_name)
    click_link "remove_association_#{@extra_he.id}"
    page.body.should_not have_tag('.review_status li a', :text => @another_name)
    visit('/logout')
  end

  it "should show associations in preview mode, but not be able to curate them" do
    dohe = DataObjectsHierarchyEntry.find_by_data_object_id(@image.id)
    dohe.visibility_id = Visibility.preview.id
    dohe.save!
    login_as @full_curator
    visit("/data_objects/#{@image.id}")
    body.should include("cannot be curated because it is being previewed after a harvest.")
    visit('/logout')
  end

  it 'should not allow a curator to add an association which already exists' do
    login_as @full_curator
    visit("/data_objects/#{@user_submitted_text.id}")
    page.body.should have_tag('#sidebar .header a', :text => 'Add new association')
    page.body.should_not have_tag('form.review_status a', :text => 'Remove association')
    click_link("Add new association")
    fill_in 'name', :with => @another_name
    click_button "find taxa"
    page.body.should include('add association')
    page.body.should_not include('associated')
    click_button "add association"
    page.body.should have_tag('form.review_status a', :text => 'Remove association')
    page.body.should have_tag('#sidebar .header a', :text => 'Add new association')
    click_link("Add new association")
    fill_in 'name', :with => @another_name
    click_button "find taxa"
    page.body.should_not include('add association')
    page.body.should include('associated')
    visit('/logout')
  end

  it 'should link image on the image data object page to it\'s original version' do
    visit("/data_objects/#{@image.id}")
    page.body.should have_tag(".media a[href='#{@image.thumb_or_object(:orig)}']")
  end

  it 'should change vetted to unreviewed and visibility to visible when self added article is edited by assistant curator/normal user'
  it 'should change vetted to trusted and visibility to visible when self added article is edited by full/master curator or admin'

end
