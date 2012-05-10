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
    @assistant_curator = build_curator(@tc, :level=>:assistant)
    @full_curator = build_curator(@tc, :level=>:full)
    @master_curator = build_curator(@tc, :level=>:master)
    @admin = User.gen(:admin=>1)
    @image = @tc.data_objects.select { |d| d.data_type.label == "Image" }[0]
    @extra_he = @another_tc.entry
    @image.add_curated_association(@full_curator, @extra_he)

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
    @user_submitted_text = @tc.add_user_submitted_text(:user => @full_curator)
    @user = User.gen
    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
  end

  it "should render" do
    visit("/data_objects/#{@image.id}")
    page.status_code.should == 200
  end

  it "should show data object attribution" do
    visit("/data_objects/#{@image.id}")
    body.should have_tag('.source', /Author:/)
  end

  it "should show image description for image objects" do
    visit("/data_objects/#{@image.id}")
    body.should have_tag('.article', /Description(\n|.)*?#{@image.description}/)
  end

  it "should not show comments section if there are no comments (obsolete?)" do
    visit("/data_objects/#{@dato_no_comments.id}")
    page.status_code.should == 200
    page.should have_no_xpath("//div[@id='commentsContain']")
  end

  it "should not show pagination if there are less than 10 comments (waiting on feed items adjustments)"

  it "should show pagination if there are more than 10 comments (waiting on feed items adjustments)"

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
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{taid} option[selected=selected]", :text => "Trusted")
      with_tag("select#visibility_id_#{taid} option[selected=selected]", :text => "Visible")
    end
    select "Unreviewed", :from => "vetted_id_#{taid}"
    select "Hidden", :from => "visibility_id_#{taid}"
    click_button "Save changes"
    page.body.should include("Curator should supply at least reason(s) to hide and/or curation comment")
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{taid} option[selected=selected]", :text => "Trusted")
      with_tag("select#visibility_id_#{taid} option[selected=selected]", :text => "Visible")
      without_tag("input[id=?][checked]", "#{taid}_untrust_reason_duplicate")
      without_tag("input[id=?][checked]", "#{taid}_untrust_reason_poor")
    end
    select "Unreviewed", :from => "vetted_id_#{taid}"
    select "Hidden", :from => "visibility_id_#{taid}"
    check "#{taid}_untrust_reason_duplicate"
    click_button "Save changes"
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{taid} option[selected=selected]", :text => "Unreviewed")
      with_tag("select#visibility_id_#{taid} option[selected=selected]", :text => "Hidden")
      with_tag("input[id=?][checked]", "#{taid}_untrust_reason_duplicate")
      without_tag("input[id=?][checked]", "#{taid}_untrust_reason_poor")
    end
    select "Untrusted", :from => "vetted_id_#{taid}"
    click_button "Save changes"
    page.body.should include("Curator should supply at least untrust reason(s) and/or curation comment")
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{taid} option[selected=selected]", :text => "Unreviewed")
      with_tag("select#visibility_id_#{taid} option[selected=selected]", :text => "Hidden")
      with_tag("input[id=?][checked]", "#{taid}_untrust_reason_duplicate")
      without_tag("input[id=?][checked]", "#{taid}_untrust_reason_poor")
    end
    select "Untrusted", :from => "vetted_id_#{taid}"
    check "#{taid}_untrust_reason_misidentified"
    click_button "Save changes"
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{taid} option[selected=selected]", :text => "Untrusted")
      with_tag("select#visibility_id_#{taid} option[selected=selected]", :text => "Hidden")
      with_tag("input[id=?][checked]", "#{taid}_untrust_reason_misidentified")
      without_tag("input[id=?][checked]", "#{taid}_untrust_reason_incorrect")
    end
    select "Trusted", :from => "vetted_id_#{taid}"
    select "Visible", :from => "visibility_id_#{taid}"
    check "#{taid}_untrust_reason_misidentified"
    click_button "Save changes"
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{taid} option[selected=selected]", :text => "Trusted")
      with_tag("select#visibility_id_#{taid} option[selected=selected]", :text => "Visible")
      without_tag("input[id=?][checked]", "#{taid}_untrust_reason_misidentified")
      without_tag("input[id=?][checked]", "#{taid}_untrust_reason_incorrect")
    end
    visit('/logout')
  end

  it 'should be able curate a CDOHE association as Unreviewed, Untrusted and Trusted' do
    login_as @full_curator
    visit("/data_objects/#{@image.id}")
    trusted_association = @image.all_associations.last
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Trusted")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Visible")
    end
    select "Unreviewed", :from => "vetted_id_#{trusted_association.id}"
    select "Hidden", :from => "visibility_id_#{trusted_association.id}"
    click_button "Save changes"
    page.body.should include("Curator should supply at least reason(s) to hide and/or curation comment")
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Trusted")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Visible")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_duplicate")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_poor")
    end
    select "Unreviewed", :from => "vetted_id_#{trusted_association.id}"
    select "Hidden", :from => "visibility_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_duplicate"
    click_button "Save changes"
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Unreviewed")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Hidden")
      with_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_duplicate")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_poor")
    end
    select "Untrusted", :from => "vetted_id_#{trusted_association.id}"
    click_button "Save changes"
    page.body.should include("Curator should supply at least untrust reason(s) and/or curation comment")
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Unreviewed")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Hidden")
      with_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_duplicate")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_poor")
    end
    select "Untrusted", :from => "vetted_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_misidentified"
    click_button "Save changes"
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Untrusted")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Hidden")
      with_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_misidentified")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_incorrect")
    end
    select "Trusted", :from => "vetted_id_#{trusted_association.id}"
    select "Visible", :from => "visibility_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_misidentified"
    click_button "Save changes"
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Trusted")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Visible")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_misidentified")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_incorrect")
    end
    visit('/logout')
  end

  it 'should be able curate a UDO association as Unreviewed, Untrusted and Trusted' do
    login_as @full_curator
    visit("/data_objects/#{@user_submitted_text.id}")
    trusted_association = @user_submitted_text.all_associations.first
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Trusted")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Visible")
    end
    select "Unreviewed", :from => "vetted_id_#{trusted_association.id}"
    select "Hidden", :from => "visibility_id_#{trusted_association.id}"
    click_button "Save changes"
    page.body.should include("Curator should supply at least reason(s) to hide and/or curation comment")
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Trusted")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Visible")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_duplicate")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_poor")
    end
    select "Unreviewed", :from => "vetted_id_#{trusted_association.id}"
    select "Hidden", :from => "visibility_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_duplicate"
    click_button "Save changes"
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Unreviewed")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Hidden")
      with_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_duplicate")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_poor")
    end
    select "Untrusted", :from => "vetted_id_#{trusted_association.id}"
    click_button "Save changes"
    page.body.should include("Curator should supply at least untrust reason(s) and/or curation comment")
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Unreviewed")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Hidden")
      with_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_duplicate")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_poor")
    end
    select "Untrusted", :from => "vetted_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_misidentified"
    click_button "Save changes"
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Untrusted")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Hidden")
      with_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_misidentified")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_incorrect")
    end
    select "Trusted", :from => "vetted_id_#{trusted_association.id}"
    select "Visible", :from => "visibility_id_#{trusted_association.id}"
    check "#{trusted_association.id}_untrust_reason_misidentified"
    click_button "Save changes"
    page.body.should have_tag("form.review_status") do
      with_tag("select#vetted_id_#{trusted_association.id} option[selected=selected]", :text => "Trusted")
      with_tag("select#visibility_id_#{trusted_association.id} option[selected=selected]", :text => "Visible")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_misidentified")
      without_tag("input[id=?][checked]", "#{trusted_association.id}_untrust_reason_incorrect")
    end
    visit('/logout')
  end

  it 'should not allow assistant curators to remove curated associations' do
    # Note there is a curated association added by @full_curator for @image. See before(:all) section.
    login_as @assistant_curator
    visit("/data_objects/#{@image.id}")
    page.body.should_not have_tag('form.review_status a', :text => 'Remove association')
    visit('/logout')
  end

  it 'should allow a full curators to remove self added associations' do
    # Note there is a curated association added by @full_curator for @image. See before(:all) section.
    login_as @full_curator
    visit("/data_objects/#{@image.id}")
    page.body.should have_tag('form.review_status a', :text => 'Remove association')
    page.body.should have_tag('form.review_status a', :text => @another_name)
    click_link "remove_association_#{@extra_he.id}"
    page.body.should_not have_tag('form.review_status a', :text => @another_name)
    visit('/logout')
  end

  it 'should allow a master curators to remove curated associations' do
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

  it 'should allow authors of user added articles to edit the latest published version of the data object' do
    udo_dato = @tc.add_user_submitted_text(:user => @user)
    visit logout_path
    visit data_object_path(udo_dato)
    body.should_not have_tag("#page_heading .page_actions a.button[href=?]", /#{edit_data_object_path(udo_dato)}/ )
    body.should_not include("Edit this article")
    login_as @user
    visit data_object_path(udo_dato)
    click_link("Edit this article")
    current_path.should == edit_data_object_path(udo_dato)
    fill_in 'data_object_description', :with => ''
    click_button("Save article")
    current_path.should == "/data_objects/#{udo_dato.id}"
    body.should have_tag('fieldset#errors') do
      with_tag("li", "Description can't be blank")
    end
    body.should have_tag("select#data_object_toc_items_id") do
      with_tag("option[value=?][selected=selected]", udo_dato.toc_items.first.id)
      without_tag("option[value=?][selected=selected]", /[^#{udo_dato.toc_items.first.id}]/)
    end
    fill_in 'data_object_description', :with => udo_dato.description
    click_button("Save article")
    new_udo_revision = DataObject.latest_published_version_of(udo_dato.id)
    current_path.should == data_object_path(new_udo_revision)
    DataObject.find(udo_dato).published.should be_false
    visit data_object_path(udo_dato)
    current_path.should == data_object_path(udo_dato)
    click_link("Edit this article")
    # When we try to edit the old udo we should actually end up at the new udo edit path
    current_path.should == edit_data_object_path(new_udo_revision)
    visit('/logout')
  end

  # This probably belongs in taxa_page_spec but shares expected behaviours with editing articles spec.
  it 'should allow logged in users and assistant curators to add text to EOL pages as Unreviewed' do
    users = [@user, @assistant_curator]
    users.each do |user|
      login_as user
      visit taxon_details_path(@tc)
      click_link "Add an article to this page"
      current_url.should match "/pages/#{@tc.id}/data_objects/new"
      select "Overview", :from => "data_object_toc_items_id"
      click_button("Add article")
      current_path.should == "/pages/#{@tc.id}/data_objects"
      body.should have_tag('fieldset#errors') do
        with_tag("li", "Description can't be blank")
      end
      body.should have_tag("select#data_object_toc_items_id") do
        with_tag("option[value=?][selected=selected]", TocItem.overview.id)
        without_tag("option[value=?][selected=selected]", /[^#{TocItem.overview.id}]/)
      end
      fill_in 'data_object_object_title', :with => "Unicorns"
      fill_in 'data_object_description', :with => "Unicorn is an imaginary animal."
      fill_in 'references', :with => "Wikipedia"
      select "public domain", :from => "data_object_license_id"
      click_button("Add article")
      body.should have_tag('fieldset#errors') do
        with_tag("li", "Rights holder must be blank for a Public Domain license")
      end
      fill_in 'data_object_rights_holder', :with => ""
      click_button("Add article")
      dato_id = DataObject.last.id
      body.should have_tag("#data_object_#{dato_id}") do
        with_tag('h4', :text => "Unicorns")
        with_tag('.copy', :text => "Unicorn is an imaginary animal.")
        with_tag('.references li', :text => "Wikipedia")
        with_tag('.attribution .copy p a', :text => "#{user.full_name}")
        with_tag('.flag', :text => "Unreviewed")
      end
      visit('/logout')
    end
  end

  # This probably belongs in taxa_page_spec but shares expected behaviours with editing articles spec.
  it 'should allow logged in full/master curators and admins to add text to EOL pages as Trusted' do
    [@full_curator, @master_curator, @admin].each do |user|
      login_as user
      visit taxon_details_path(@tc)
      click_link "Add an article to this page"
      current_url.should match "/pages/#{@tc.id}/data_objects/new"
      select "Overview", :from => "data_object_toc_items_id"
      fill_in 'data_object_object_title', :with => "Unicorns"
      fill_in 'data_object_description', :with => "Unicorn is an imaginary animal."
      fill_in 'references', :with => "Wikipedia"
      select "public domain", :from => "data_object_license_id"
      click_button "data_object_submit"
      dato_id = DataObject.last.id
      body.should have_tag("#data_object_#{dato_id}") do
        with_tag('h4', :text => "Unicorns")
        with_tag('.copy', :text => "Unicorn is an imaginary animal.")
        with_tag('.references li', :text => "Wikipedia")
        with_tag('.attribution .copy p a', :text => "#{user.full_name}")
        with_tag('.flag', :text => "Trusted")
      end
      visit('/logout')
    end
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
    body.should match('&copy;')
  end

  it "should link agents to their homepage, and add http if the link does not include it" do
    agent = Agent.new(:full_name => 'doesnt matter', :homepage => 'www.somesite.com')
    agent.send(:create_without_callbacks)
    @image.agents_data_objects << AgentsDataObject.gen(:agent => agent, :agent_role => AgentRole.author, :data_object => @image)
    @image.save
    visit("/data_objects/#{@image.id}")
    body.should have_tag("a[href=http://#{agent.homepage}]", :text => agent.full_name)
  end

  it "should allow assistant curators to add and/or remove associations, but not to curate them" do
    @image.add_curated_association(@assistant_curator, @extra_he)
    login_as @assistant_curator
    visit("/data_objects/#{@image.id}")
    page.body.should_not have_tag('ul.review_status select')
    page.body.should have_tag('#sidebar .header a', :text => 'Add new association')
    page.body.should have_tag('.review_status li a', :text => 'Remove association')
    page.body.should have_tag('.review_status li a', :text => @another_name)
    click_link "remove_association_#{@extra_he.id}"
    page.body.should_not have_tag('.review_status li a', :text => @another_name)
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

end
