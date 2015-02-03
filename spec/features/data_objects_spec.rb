# encoding: utf-8
require "spec_helper"

# TODO - these specs only pass when they're all passing. If one fails, the data isn't reset.

def review_status_should_be(id, vetted, visible, options = {})
  page.body.should have_tag("form.review_status") do
    with_tag("select option[selected=selected]", text: vetted)
    with_tag("select option[selected=selected]", text: visible)
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

  # TODO - this is REALLY slow. Try to reduce the number of TCs, or fix that method.
  before(:all) do
    load_foundation_cache
    # Somewhat empty, to speed things up:
    @tc = build_taxon_concept(images: [object_cache_url: FactoryGirl.generate(:image)], toc: [])
    @extra_name = 'Annuvvahnaemforyoo'
    @extra_tc = build_taxon_concept(images: [], toc: [], scientific_name: @extra_name)
    @single_name = 'Singularusnamicus'
    @singular_tc = build_taxon_concept(images: [], toc: [], scientific_name: @single_name)
    @singular_he = @singular_tc.entry
    @name_to_add = 'Addthisnametomeplease'
    @to_add_tc = build_taxon_concept(images: [], toc: [], scientific_name: @name_to_add)
    @assistant_curator = build_curator(@tc, level: :assistant)
    @full_curator = build_curator(@tc, level: :full)
    @master_curator = build_curator(@tc, level: :master)
    @admin = User.gen(admin: 1)
    @image = @tc.data_objects.select { |d| d.data_type.label == "Image" }[0]
    @extra_he = @extra_tc.entry
    @assistants_entry = build_taxon_concept(images: [], toc: []).entry

    @dato_no_comments = build_data_object('Image', 'No comments',
    num_comments: 0,
    object_cache_url: FactoryGirl.generate(:image),
    vetted: Vetted.trusted,
    visibility: Visibility.visible)
    @dato_comments_no_pagination = build_data_object('Image', 'Some comments',
    num_comments: 4,
    object_cache_url: FactoryGirl.generate(:image),
    vetted: Vetted.trusted,
    visibility: Visibility.visible)
    @dato_comments_with_pagination = build_data_object('Image', 'Lots of comments',
    num_comments: 15,
    object_cache_url: FactoryGirl.generate(:image),
    vetted: Vetted.trusted,
    visibility: Visibility.visible)
    @dato_untrusted = build_data_object('Image', 'removed',
    num_comments: 0,
    object_cache_url: FactoryGirl.generate(:image),
    vetted: Vetted.untrusted,
    visibility: Visibility.invisible)
    @user_submitted_text = @tc.add_user_submitted_text(user: @full_curator)
    @user = User.gen
    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
  end

  # TODO - this is slow. Find out why.
  before(:each) do
    DataObjectsHierarchyEntry.where(data_object_id: @image.id).update_all(visibility_id: Visibility.visible.id)
    @image.add_curated_association(@full_curator, @extra_he)
    @image.data_objects_hierarchy_entries.first.update_attributes(:vetted_id => Vetted.trusted.id)
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
    expect(body).to have_tag('.source p', text: /Author:.*#{@image.authors.first.full_name}/m)
  end

  it "should show image description for image objects" do
    visit("/data_objects/#{@image.id}")
    expect(page).to have_content @image.description
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
    tc = build_taxon_concept(images: [object_cache_url: FactoryGirl.generate(:image)], toc: [], published: false)
    image = tc.data_objects.select { |d| d.data_type.label == "Image" }[0]
    tc.published = false
    tc.save!
    dato_no_tc = build_data_object('Image', 'unlinked',
    num_comments: 0,
    object_cache_url: FactoryGirl.generate(:image),
    vetted: Vetted.trusted,
    visibility: Visibility.visible)
    dato_no_tc.get_taxon_concepts[0].published?.should be_false
    visit("/data_objects/#{dato_no_tc.id}")
    page_link = "/pages/#{tc.id}?image_id="
    page.body.should_not include(page_link)
  end

  it 'should allow a curator to add an association' do
    login_as @full_curator
    visit("/data_objects/#{@dato_no_comments.id}")
    page.body.should have_tag('#sidebar .header a', text: 'Add new association')
    page.body.should_not have_tag('form.review_status a', text: 'Remove association')
    click_link("Add new association")
    fill_in 'name', with: @name_to_add
    click_button "find taxa"
    click_button "add association" # If this fails, make sure you have Solr running!
    page.body.should have_tag("a[href='#{remove_association_path(@dato_no_comments.id, @to_add_tc.entry.id)}']")
    expect(page).to have_content(I18n.t(:association_added_flash))
    visit('/logout')
  end

  it 'should show proper vetted & visibility statuses of associations to the anonymous users' do
    visit("/data_objects/#{@image.id}")
    page.body.should have_tag("ul.review_status") do
      with_tag("li:first-child .trusted", text: "Trusted")
    end
    visit("/data_objects/#{@dato_untrusted.id}")
    page.body.should_not have_tag("ul.review_status")
    page.body.should include("not associated with any published taxa")
  end

  # TODO - Hi there. You'll notice the next few specs are quite redundant. Do you see a way to generalize them?
  # Thanks for your consideration,
  # The management.

  it 'should be able curate a DOHE association as Unreviewed, Untrusted and Trusted' do
    login_as @full_curator
    visit("/data_objects/#{@image.id}")
    taid = @image.data_object_taxa_by_visibility(invisible: true).first.id
    review_status_should_be(taid, 'Trusted', 'Visible')
    # AHHH! The problem is that @image is in a preview state.  :D  Fix.
    debugger unless body =~ /vetted_id_#{taid}/
    select "Unreviewed", from: "vetted_id_#{taid}"
    select "Hidden", from: "visibility_id_#{taid}"
    click_button "Save changes"
    page.should have_selector('p.status.error')
    review_status_should_be(taid, 'Trusted', 'Visible')
    review_status_should_be(taid, 'Trusted', 'Visible', duplicate: false, poor: false)
    select "Unreviewed", from: "vetted_id_#{taid}"
    select "Hidden", from: "visibility_id_#{taid}"
    check "#{taid}_untrust_reason_duplicate"
    click_button "Save changes"
    review_status_should_be(taid, 'Unreviewed', 'Hidden', duplicate: true, poor: false)
    select "Untrusted", from: "vetted_id_#{taid}"
    click_button "Save changes"
    page.should have_selector('p.status.error')
    review_status_should_be(taid, 'Unreviewed', 'Hidden', duplicate: true, poor: false)
    select "Untrusted", from: "vetted_id_#{taid}"
    check "#{taid}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(taid, 'Untrusted', 'Hidden', misidentified: true, incorrect: false)
    select "Trusted", from: "vetted_id_#{taid}"
    select "Visible", from: "visibility_id_#{taid}"
    check "#{taid}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(taid, 'Trusted', 'Visible', misidentified: false, incorrect: false)
    visit('/logout')
  end

  it 'should be able curate a CDOHE association as Unreviewed, Untrusted and Trusted' do
    login_as @full_curator
    visit("/data_objects/#{@image.id}")
    # TODO - it's not there.  :|  I wonder if maybe this is a cache thing?
    assoc_id = @image.reload.data_object_taxa.first.id
    review_status_should_be(assoc_id, 'Trusted', 'Visible')
    select "Unreviewed", from: "vetted_id_#{assoc_id}"
    select "Hidden", from: "visibility_id_#{assoc_id}"
    click_button "Save changes"
    page.should have_selector('p.status.error')
    review_status_should_be(assoc_id, 'Trusted', 'Visible', duplicate: false, poor: false)
    select "Unreviewed", from: "vetted_id_#{assoc_id}"
    select "Hidden", from: "visibility_id_#{assoc_id}"
    check "#{assoc_id}_untrust_reason_duplicate"
    click_button "Save changes"
    review_status_should_be(assoc_id, 'Unreviewed', 'Hidden', duplicate: true, poor: false)
    select "Untrusted", from: "vetted_id_#{assoc_id}"
    click_button "Save changes"
    page.should have_selector('p.status.error')
    review_status_should_be(assoc_id, 'Unreviewed', 'Hidden', duplicate: true, poor: false)
    select "Untrusted", from: "vetted_id_#{assoc_id}"
    check "#{assoc_id}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(assoc_id, 'Untrusted', 'Hidden', misidentified: true, incorrect: false)
    select "Trusted", from: "vetted_id_#{assoc_id}"
    select "Visible", from: "visibility_id_#{assoc_id}"
    check "#{assoc_id}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(assoc_id, 'Trusted', 'Visible', misidentified: false, incorrect: false)
    visit('/logout')
  end

  it 'should be able curate a UDO association as Unreviewed, Untrusted and Trusted' do
    login_as @full_curator
    # TODO - we occasionaly get failures here, so we should probably use a distinct data object.
    visit("/data_objects/#{@user_submitted_text.id}")
    assoc_id = @user_submitted_text.data_object_taxa.first.id
    review_status_should_be(assoc_id, 'Trusted', 'Visible')
    select "Unreviewed", from: "vetted_id_#{assoc_id}"
    select "Hidden", from: "visibility_id_#{assoc_id}"
    click_button "Save changes"
    page.should have_selector('p.status.error')
    review_status_should_be(assoc_id, 'Trusted', 'Visible')
    select "Unreviewed", from: "vetted_id_#{assoc_id}"
    select "Hidden", from: "visibility_id_#{assoc_id}"
    check "#{assoc_id}_untrust_reason_duplicate"
    click_button "Save changes"
    review_status_should_be(assoc_id, 'Unreviewed', 'Hidden', duplicate: true, poor: false)
    select "Untrusted", from: "vetted_id_#{assoc_id}"
    click_button "Save changes"
    review_status_should_be(assoc_id, 'Unreviewed', 'Hidden', duplicate: true, poor: false)
    select "Untrusted", from: "vetted_id_#{assoc_id}"
    check "#{assoc_id}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(assoc_id, 'Untrusted', 'Hidden', misidentified: true, incorrect: false)
    select "Trusted", from: "vetted_id_#{assoc_id}"
    select "Visible", from: "visibility_id_#{assoc_id}"
    check "#{assoc_id}_untrust_reason_misidentified"
    click_button "Save changes"
    review_status_should_be(assoc_id, 'Trusted', 'Visible', misidentified: false, incorrect: false)
    visit('/logout')
  end

  it 'should not allow assistant curators to remove curated associations' do
    login_as @assistant_curator
    visit("/data_objects/#{@image.id}")
    page.body.should_not have_tag('form.review_status a', text: 'Remove association')
    visit('/logout')
  end

  it 'should allow a full curators to remove self added associations' do
    login_as @full_curator
    visit("/data_objects/#{@image.id}")
    page.body.should have_tag('form.review_status a', text: 'Remove association')
    page.body.should have_tag("a[href='#{remove_association_path(@image.id, @extra_he.id)}']")
    click_link "remove_association_#{@extra_he.id}"
    page.body.should_not have_tag("a[href='#{remove_association_path(@image.id, @extra_he.id)}']")
    visit('/logout')
  end

  it 'should allow a master curator to remove curated associations' do
    login_as @master_curator
    visit("/data_objects/#{@image.id}")
    page.body.should have_tag('form.review_status a', text: 'Remove association')
    page.body.should have_tag('form.review_status a', text: @extra_name)
    click_link "remove_association_#{@extra_he.id}"
    page.body.should_not have_tag("a[href='#{remove_association_path(@image.id, @extra_he.id)}']")
    visit('/logout')
  end

  it 'should allow logged in users to rate' do
    login_as @user
    visit data_object_path(@image)
    body.should have_tag("#sidebar .ratings") do
      with_tag('dt', text: "Your rating")
    end
    click_link('Change rating to 3 of 5')
    current_url.should match /#{data_object_path(@image)}/
    body.should include('Rating was added successfully')
    body.should have_tag("#sidebar .ratings") do
      with_tag('dt', text: "Your rating")
      with_tag('ul li', text: "Your current rating: 3 of 5")
    end
    visit('/logout')
  end

  it 'should allow logged in users to post a comment' do
    comment = "Test comment by a logged in user."
    login_as @user
    visit("/data_objects/#{@image.id}")
    body.should_not have_tag("blockquote", text: comment)
    body.should have_tag(".comment #comment_body")
    body.should have_tag("#new_comment .actions input", val: "Post Comment")
    within(:xpath, '//form[@id="new_comment"]') do
      fill_in 'comment_body', with: comment
      click_button "Post Comment"
    end
    visit("/data_objects/#{@image.id}")
    expect(page).to have_content(comment)
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
    user_submitted_text = @tc.add_user_submitted_text(user: @user)
    login_as @user
    visit("/data_objects/#{user_submitted_text.id}")
    body.should_not have_tag(".article.list ul li a[href='/data_objects/#{user_submitted_text.id}']")
    click_link "Edit this article"
    fill_in 'data_object_rights_holder', with: ""
    click_button "Save article"
    body.should have_tag(".article.list ul li a[href='/data_objects/#{user_submitted_text.id}']")
  end

  it "should link agents to their homepage, and add http if the link does not include it" do
    agent = Agent.gen(full_name: 'doesnt matter', homepage: 'www.somesite.com')
    # TODO - this used to use create_without_callbacks, which is gone in Rails 3, and the reason for needing it was
    # not explained. Look into it.
    @image.agents_data_objects << AgentsDataObject.gen(agent: agent, agent_role: AgentRole.author, data_object: @image)
    @image.save
    visit("/data_objects/#{@image.id}")
    body.should have_tag("a[href='http://www.somesite.com']", text: agent.full_name)
  end

  it "should allow assistant curators to add and/or remove associations, but not to curate them" do
    @image.add_curated_association(@assistant_curator, @assistants_entry)
    login_as @assistant_curator
    visit("/data_objects/#{@image.id}")
    page.body.should_not have_tag('ul.review_status select')
    page.body.should have_tag('#sidebar .header a', text: 'Add new association')
    page.body.should have_tag("a[href='#{remove_association_path(@image.id, @assistants_entry.id)}']")
    page.body.should have_tag('.review_status a', text: @extra_name)
    click_link "remove_association_#{@assistants_entry.id}"
    page.body.should_not have_tag("a[href='#{remove_association_path(@image.id, @assistants_entry.id)}']")
    visit('/logout')
  end

  it "should allow data object owners to add and/or remove associations, but not to curate them" do
    user_submitted_text = @tc.add_user_submitted_text(user: @full_curator)
    user_submitted_text.add_curated_association(@full_curator, @extra_he)
    user_submitted_text.reload # it's the responsibility of the controller to do this, so...
    login_as @full_curator
    visit("/data_objects/#{user_submitted_text.id}")
    page.body.should_not have_tag('ul.review_status select')
    page.body.should have_tag('#sidebar .header a', text: 'Add new association')
    page.body.should have_tag('.remove_association a', text: 'Remove association')
    find('.review_status').all('a').map(&:text).should include(@extra_name)
    click_link "remove_association_#{@extra_he.id}"
    page.body.should_not have_tag('.review_status li a', text: @extra_name)
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
    page.body.should have_tag('#sidebar .header a', text: 'Add new association')
    click_link("Add new association")
    fill_in 'name', with: @extra_name
    click_button "find taxa"
    page.body.should include('add association')
    page.body.should_not include('associated')
    click_button "add association"
    page.body.should have_tag('form.review_status a', text: 'Remove association')
    page.body.should have_tag('#sidebar .header a', text: 'Add new association')
    click_link("Add new association")
    fill_in 'name', with: @extra_name
    click_button "find taxa"
    page.body.should_not include('add association')
    page.body.should include('associated')
    visit('/logout')
  end

  it 'should link image on the image data object page to it\'s original version' do
    visit("/data_objects/#{@image.id}")
    page.body.should have_tag(".media a[href='#{@image.thumb_or_object(:orig)}']")
  end

  it 'should not show an image cropping tool to non-admins' do
    login_as @master_curator
    visit("/data_objects/#{@image.id}")
    body.should_not have_tag('.crop_preview.width_130')
    body.should_not have_tag('.crop_preview.width_88')
    body.should_not have_tag('#crop_form')
    visit('/logout')
  end

  it 'should show admins an image cropping tool' do
    login_as @admin
    visit("/data_objects/#{@image.id}")
    body.should have_tag('.crop_preview.width_130')
    body.should have_tag('.crop_preview.width_88')
    body.should have_tag('#crop_form')
    visit('/logout')
  end

  it 'should use the resource rights holder if the data object doesnt have one' do
    # creating a resource for this data object
    hierarchy = Hierarchy.gen
    resource = Resource.gen(hierarchy: hierarchy)
    hierarchy_entry = HierarchyEntry.gen(hierarchy: hierarchy)
    data_object = DataObject.gen    
    DataObjectsHierarchyEntry.gen(hierarchy_entry: hierarchy_entry, data_object: data_object)
    data_object.update_column(:rights_holder, '')
    resource.update_column(:rights_holder, 'RESOURCE RIGHTS')
    visit("/data_objects/#{data_object.id}")
    body.should include('RESOURCE RIGHTS')
    body.should_not include('OBJECT RIGHTS')

    data_object.update_column(:rights_holder, 'OBJECT RIGHTS')
    visit("/data_objects/#{data_object.id}")
    body.should include('OBJECT RIGHTS')
    body.should_not include('RESOURCE RIGHTS')
  end

  it 'should use the resource rights statement if the data object doesnt have one' do
    # creating a resource for this data object
    hierarchy = Hierarchy.gen
    resource = Resource.gen(hierarchy: hierarchy)
    hierarchy_entry = HierarchyEntry.gen(hierarchy: hierarchy)
    data_object = DataObject.gen    
    DataObjectsHierarchyEntry.gen(hierarchy_entry: hierarchy_entry, data_object: data_object)
    data_object.update_column(:rights_statement, '')
    resource.update_column(:rights_statement, 'RESOURCE STATEMENT')
    visit("/data_objects/#{data_object.id}")
    body.should include('RESOURCE STATEMENT')
    body.should_not include('OBJECT STATEMENT')

    data_object.update_column(:rights_statement, 'OBJECT STATEMENT')
    data_object.reload.rights_statement_for_display.should == 'OBJECT STATEMENT'
    visit("/data_objects/#{data_object.id}")
    body.should include('OBJECT STATEMENT')
    body.should_not include('RESOURCE STATEMENT')
  end

  it 'should use the resource bibliographic citation if the data object doesnt have one' do
    # creating a resource for this data object
    hierarchy = Hierarchy.gen
    resource = Resource.gen(hierarchy: hierarchy)
    hierarchy_entry = HierarchyEntry.gen(hierarchy: hierarchy)
    data_object = DataObject.gen    
    DataObjectsHierarchyEntry.gen(hierarchy_entry: hierarchy_entry, data_object: data_object)
    data_object.update_column(:bibliographic_citation, '')
    resource.update_column(:bibliographic_citation, 'RESOURCE CITATION')
    visit("/data_objects/#{data_object.id}")
    body.should include('RESOURCE CITATION')
    body.should_not include('OBJECT CITATION')

    data_object.update_column(:bibliographic_citation, 'OBJECT CITATION')
    data_object.reload.bibliographic_citation_for_display.should == 'OBJECT CITATION'
    visit("/data_objects/#{data_object.id}")
    body.should include('OBJECT CITATION')
    body.should_not include('RESOURCE CITATION')
  end

  it 'should preserve data rating when editing' do
    user_submitted_text = @tc.add_user_submitted_text(user: @user, license: License.cc)
    login_as @user
    # Visit page and add a rating
    visit("/data_objects/#{user_submitted_text.id}")
    click_link('Change rating to 4 of 5')
    current_url.should match "/data_objects/#{user_submitted_text.id}"
    body.should include('Rating was added successfully')
    body.should have_tag("#sidebar .ratings") do
      with_tag('dt', text: "Your rating")
      with_tag('ul li', text: "Your current rating: 4 of 5")
    end
    user_submitted_text.reload.data_rating.should == 4
    user_submitted_text.latest_published_version_in_same_language.should == user_submitted_text

    # edit article and check on latest version
    click_link "Edit this article"
    fill_in 'data_object_rights_holder', with: "nonsense"
    click_button "Save article"
    user_submitted_text.reload.latest_published_version_in_same_language.should_not == user_submitted_text
    user_submitted_text.latest_published_version_in_same_language.guid.should == user_submitted_text.guid
    user_submitted_text.latest_published_version_in_same_language.id.should > user_submitted_text.id
    user_submitted_text.latest_published_version_in_same_language.data_rating.should == 4
  end

  it 'should not show a description if there isnt one' do
    d = DataObject.gen(description: "", data_type: DataType.image)
    visit(data_object_path(d))
    body.should_not have_tag("h3", text: 'Description' )

    d = DataObject.gen(description: "anything", data_type: DataType.image)
    visit(data_object_path(d))
    body.should have_tag("h3", text: 'Description' )
  end

  it 'should show references and identifiers' do
    d = DataObject.gen(data_type: DataType.text)
    r = Ref.gen(full_reference: 'This is the full reference')
    RefIdentifier.gen(ref: r, ref_identifier_type: RefIdentifierType.url, identifier: 'http://si.edu/someref')
    RefIdentifier.gen(ref: r, ref_identifier_type: RefIdentifierType.doi, identifier: 'doi:10.1006/some.ref')
    DataObjectsRef.gen(data_object: d, ref: r)
    visit(data_object_path(d))
    body.should have_tag("a[href='http://si.edu/someref']")
    body.should have_tag("a[href='http://dx.doi.org/10.1006/some.ref']")

    # slightly different formatting for the RefIdentifiers. The view shoudl auto-complete the URLs
    d = DataObject.gen(data_type: DataType.text)
    r = Ref.gen(full_reference: 'This is the full reference')
    RefIdentifier.gen(ref: r, ref_identifier_type: RefIdentifierType.url, identifier: 'si.edu/someref')
    RefIdentifier.gen(ref: r, ref_identifier_type: RefIdentifierType.doi, identifier: '10.1006/some.ref')
    DataObjectsRef.gen(data_object: d, ref: r)
    visit(data_object_path(d))
    body.should have_tag("a[href='http://si.edu/someref']")
    body.should have_tag("a[href='http://dx.doi.org/10.1006/some.ref']")
  end

  it 'should not show names from untrusted associations, unless thats is all there is' do
    d = DataObject.gen(data_type: DataType.image, object_title: nil)
    d.add_curated_association(@full_curator, @extra_he)
    d.add_curated_association(@full_curator, @singular_he)
    visit(data_object_path(d))
    body.should include("<h1>Image of <i>#{@extra_he.name.canonical_form.string}</i> and <i>#{@singular_he.name.canonical_form.string}</i>")
    # untrusting the first name so only the second will show up
    d.vet_by_taxon_concept(@extra_he.taxon_concept, Vetted.untrusted)
    visit(data_object_path(d))
    body.should include("<h1>Image of <i>#{@singular_he.name.canonical_form.string}</i>")
    # now that they are both untrusted, it will say unknown taxon
    d.vet_by_taxon_concept(@singular_he.taxon_concept, Vetted.untrusted)
    visit(data_object_path(d))
    body.should include("<h1>Image of an unknown taxon")
  end

  it 'should change vetted to unreviewed and visibility to visible when self added article is edited by assistant curator/normal user'
  it 'should change vetted to trusted and visibility to visible when self added article is edited by full/master curator or admin'

end
