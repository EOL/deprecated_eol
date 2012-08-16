require File.dirname(__FILE__) + '/../spec_helper'

describe Notifier do

  before(:all) do
    unless @user = User.find_by_username('notifier_model')
      truncate_all_tables
      load_foundation_cache
      @user = User.gen(:username => "notifier_model", :email => "johndoe@example.com",
                       :given_name => "John", :family_name => "Doe")
    end
  end

  shared_examples_for 'email_to_user' do
    it "should be set to be delivered to the user" do
      @email.should deliver_to(@user.email)
    end
    it "should contain a greeting with user's name" do
      @email.should have_text(/Dear #{@user.full_name},/)
    end
    it "should contain 'The Encyclopedia of Life Team' signature" do
      @email.should have_text(/The Encyclopedia of Life Team/)
    end
    it "should contain a contact us link" do
      @email.should have_text(/If you experience any problems, please contact us at http.*?contact_us/)
    end
  end

  describe 'curator_approved' do
    before(:all) do
      @curator_level = CuratorLevel.full
      @user.update_attributes(:curator_level_id => @curator_level.id, :credentials => 'I am awesome.',
                              :curator_scope => 'I study awesomeness.')
      @email = Notifier.create_curator_approved(@user)
    end

    it_should_behave_like 'email_to_user'

    it "should have a relevant subject" do
      @email.should have_subject(/Encyclopedia of Life.+?#{@curator_level.label}.+?approved/i)
    end

    it "should tell the user their curator level request has been approved" do
      @email.should have_text(/#{@curator_level.label}.+?approved/)
    end

    it "should contain a more information url" do
      @email.should have_text(/http:\/\/eol.org\/curators/i)
    end

  end

  describe 'content_partner_statistics_reminder' do
    before(:all) do
      @content_partner = ContentPartner.gen(:user => @user)
      @content_partner.content_partner_contacts.build(:email => 'test@test.tes', :full_name => 'Test Tester')
      @content_partner.save
      @content_partner_contact = @content_partner.content_partner_contacts.first
      @year = 1.month.ago.year
      @month = 1.month.ago.month
      @partner_summary = GoogleAnalyticsPartnerSummary.gen(:year => @year, :month => @month, :user => @user)
      @email = Notifier.create_content_partner_statistics_reminder(@content_partner, @content_partner_contact, @month, @year)
    end

    it "should be set to be delivered to the content partner contact" do
      @email.should deliver_to(@content_partner_contact.email)
    end

    it "should have a relevant subject" do
      @email.should have_subject(/Encyclopedia of Life.+?#{@content_partner.full_name}.+?#{@month}.+?#{@year}/i)
    end

    it "should contain a greeting with contact's name" do
      @email.should have_text(/Dear #{@content_partner_contact.full_name},/)
    end

    it "should tell the contact their content partner stats are available for viewing and provide link" do
      @email.should have_text(/automated e-mail reminder from the Encyclopedia of Life/i)
      @email.should have_text(/web usage statistics.+?#{@content_partner.full_name}.+?#{@month}.+?#{@year}/i)
      @email.should have_text(/\/content_partners\/#{@content_partner.id}\/statistics/i)
    end

    it "should contain a signature with species pages group contact" do
      @email.should have_text(/#{$SPECIES_PAGES_GROUP_EMAIL_ADDRESS}.+?The Encyclopedia of Life Team/im)
    end
  end

  describe 'activity_on_content_partner_content' do
    before(:all) do
      @curator = User.gen(:curator_level => CuratorLevel.full_curator, :credentials => 'Blah', :curator_scope => 'More blah')
      if @user.content_partners.blank?
        @content_partner = ContentPartner.gen(:user => @user)
      else
        @content_partner = @user.content_partners.first
      end
      if @content_partner.content_partner_contacts.blank?
        @content_partner_contact = ContentPartnerContact.gen(:content_partner => @content_partner)
      else
        @content_partner_contact = @content_partner.content_partner_contacts.first
      end
      @hierarchy = Hierarchy.gen
      @taxon_concept = TaxonConcept.gen
      @hierarchy_entry = HierarchyEntry.gen(:taxon_concept => @taxon_concept, :hierarchy => @hierarchy)
      @resource = Resource.gen(:content_partner => @content_partner, :hierarchy => @hierarchy)
      @harvest_event = HarvestEvent.gen(:resource => @resource, :published_at => nil)
      @data_object = DataObject.gen(:object_title => 'Content partner provided text object')
      DataObjectsHierarchyEntry.gen(:hierarchy_entry => @hierarchy_entry, :data_object => @data_object)
      # Using ChangeableObjectType.data_objects_hierarchy_entry and object_id is DataObject.id because thats
      # what the log_action method in DataObject controller is doing... but its a little weird
      @trusted_action = CuratorActivityLog.gen(:changeable_object_type_id => ChangeableObjectType.data_objects_hierarchy_entry.id,
                                               :activity_id => Activity.trusted.id, :user => @curator, :object_id => @data_object.id,
                                               :hierarchy_entry_id => @hierarchy_entry.id, :created_at => Time.now)
      @comment_on_dato = Comment.gen(:user => @curator, :body => 'Comment on dato.', :parent_type => 'DataObject',
                                     :parent_id => @data_object, :created_at => Time.now)
      @comment_on_page = Comment.gen(:user => @curator, :body => 'Comment on page.', :parent_type => 'TaxonConcept',
                                     :parent_id => @taxon_concept, :created_at => Time.now)
      all_activity = PartnerUpdatesEmailer.all_activity_since_hour(1)
      @activity = all_activity[:partner_activity][@content_partner.id]
      @email = Notifier.create_activity_on_content_partner_content(@content_partner, @content_partner_contact, @activity)
    end

    it "should be set to be delivered to the content partner contact" do
      @email.should deliver_to(@content_partner_contact.email)
    end

    it "should have a relevant subject" do
      @email.should have_subject(/Encyclopedia of Life.+?#{@content_partner.full_name}/i)
    end

    it "should contain a greeting with contact's name" do
      @email.should include_text("Dear #{@content_partner_contact.full_name},")
    end

    it "should list recent curator actions on content provided by the content partner" do
      @email.should have_text(/Curatorial actions.*?#{@curator.full_name} \(.*?users\/#{@curator.id}\) marked as #{@trusted_action.activity.name}.*?#{@data_object.summary_name} \(.*?data_objects\/#{@data_object.id}\) for #{@hierarchy_entry.name.string} \(.*?entries\/#{@hierarchy_entry.id}\).*?#{Time.now.year}/im)
    end

    it "should list recent comments on content provided by the content partner" # do
#      @email.should have_text(/Comments on data objects.*?#{@curator.full_name} commented on #{@data_object.summary_name}.*?#{@comment_on_dato.body}/mi)
#    end

    it "should list recent comments on pages containing content provided by the content partner" # do
#      @email.should have_text(/Comments on pages.*?#{@curator.full_name} commented on #{@taxon_concept.summary_name}.*?#{@comment_on_page.body}/mi)
#    end

    it "should contain a signature with species pages group contact" do
      @email.should have_text(/#{$SPECIES_PAGES_GROUP_EMAIL_ADDRESS}.+?The Encyclopedia of Life Team/im)
    end
  end

  describe 'user_activated' do
    before(:all) do
      @email = Notifier.create_user_activated(@user)
    end

    it_should_behave_like 'email_to_user'

    it "should have a relevant subject" do
      @email.should have_subject('Your Encyclopedia of Life account has been activated')
    end

    it "should contain the user's username, profile, login and help urls" do
      @email.should have_text(/your username is #{@user.username} and your profile URL.+?\/users\/#{@user.id}.+?http:\/\/eol.org\/login.+?http:\/\/eol.org\/help/im)
    end

  end

  describe '#user_activated_with_open_authentication' do
    before(:all) do
      @email = Notifier.create_user_activated_with_open_authentication(@user, 'facebook')
    end

    it_should_behave_like 'email_to_user'

    it "should have a relevant subject" do
      @email.should have_subject('Your Encyclopedia of Life account has been activated')
    end

    it "should contain the user's open authentication provider, profile, login and help urls" do
      @email.should have_text(/you signed up using Facebook.+?your profile URL on eol is .+?\/users\/#{@user.id}.+?http:\/\/eol.org\/login.+?http:\/\/eol.org\/help/im)
    end

  end

  describe '#user_recover_account' do
    before(:all) do
      @user.update_attribute(:recover_account_token, User.generate_key)
      @temporary_login_url = "http://www.eol.org/users/#{@user.id}/temporary_login/#{@user.recover_account_token}"
      @email = Notifier.create_user_recover_account(@user, @temporary_login_url)
    end

    it_should_behave_like 'email_to_user'

    it "should have a relevant subject" do
      @email.should have_subject('Recover your Encyclopedia of Life account')
    end

    it "should contain a temporary login url" do
      @email.should have_text(/#{@temporary_login_url}/)
    end

  end

  describe '#user_verification' do
    before(:all) do
      @user.update_attribute(:validation_code, User.generate_key)
      @verify_user_url = "http://www.eol.org/users/#{@user.id}/verify/#{@user.validation_code}"
      @email = Notifier.create_user_verification(@user, @verify_user_url)
    end

    it_should_behave_like 'email_to_user'

    it "should have a relevant subject" do
      @email.should have_subject(/verify.*?Encyclopedia of Life account/i)
    end

    it "should contain a verification url" do
      @email.should have_text(/#{@verify_user_url}/)
    end

  end
  
  describe '#unsubscribed_to_notifications' do
    before(:all) do
      @edit_user_notification_url = "http://eol.org/users/#{@user.id}/notification/edit"
      @email = Notifier.deliver_unsubscribed_to_notifications(@user)
    end

    it_should_behave_like 'email_to_user'

    it "should have a relevant subject" do
      @email.should have_subject(/Sorry to see you go/i)
    end

    it "should contain a verification url" do
      @email.should have_text(/#{@edit_user_notification_url}/)
    end

  end

end
