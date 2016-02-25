require "spec_helper"

describe 'Curator' do

  before(:all) do
    @password = 'dragonmaster'
    load_foundation_cache
    @user = User.gen username: 'KungFuPanda', password: @password
    @user.should_not be_a_new_record
    @curator = User.gen(credentials: 'whatever', curator_scope: 'whatever')
  end

  it 'should fail validation if master or full curator does not provide credentials or scope' do
    [CuratorLevel.master.id, CuratorLevel.full.id].each do |curator_level_id|
      user1 = User.new(requested_curator_level_id: curator_level_id)
      user2 = User.new(curator_level_id: curator_level_id)
      [user1, user2].each do |user|
        user.valid?.should be_false
        user.errors[:credentials].to_s.should =~ /can't be blank/
        user.errors[:curator_scope].to_s.should =~ /can't be blank/
      end
    end
  end

  it 'should NOT check credentials if assistant curator' do
    user = User.new(curator_level_id: CuratorLevel.assistant.id)
    user.valid? # We don't actually care if this passes or fails; we only want to check two errors:
    user.errors[:credentials].should be_blank
    user.errors[:curator_scope].should be_blank
  end

  it 'should save some variables temporarily (by responding to some methods)' do
    @user.respond_to?(:curator_request).should be_true
    @user.respond_to?(:curator_request=).should be_true
  end

  it 'should not allow you to add a user that already exists' do
    user = User.new(username: @user.username)
    user.save.should be_false
    user.errors[:username].to_s.should =~ /taken/
  end

  it '(curator user) should allow curator rights to be revoked' do
    Role.gen(title: 'Curator') rescue nil
    @curator.grant_curator
    @curator.save!
    @curator.curator_level_id.nil?.should_not be_true
    @curator.revoke_curator
    @curator.reload
    @curator.curator_level_id.nil?.should be_true
  end

  it 'should increase no. of curated data objects for a curator' do
      temp_count = Curator.total_objects_curated_by_action_and_user(nil, @curator.id)

      data_object = DataObject.gen()
      activity = CuratorActivityLog.gen(user: @curator, target_id: data_object.id, changeable_object_type_id: ChangeableObjectType.data_objects_hierarchy_entry.id, activity_id: TranslatedActivity.find_by_name("trusted").id )
      temp_count2 = Curator.total_objects_curated_by_action_and_user(nil, @curator.id)
      temp_count2.should > temp_count

      data_object = DataObject.gen()
      activity = CuratorActivityLog.gen(user: @curator, target_id: data_object.id, changeable_object_type_id: ChangeableObjectType.curated_data_objects_hierarchy_entry.id, activity_id: TranslatedActivity.find_by_name("trusted").id )
      temp_count = Curator.total_objects_curated_by_action_and_user(nil, @curator.id)
      temp_count.should > temp_count2

      data_object = DataObject.gen()
      activity = CuratorActivityLog.gen(user: @curator, target_id: data_object.id, changeable_object_type_id: ChangeableObjectType.users_data_object.id, activity_id: TranslatedActivity.find_by_name("trusted").id )
      temp_count2 = Curator.total_objects_curated_by_action_and_user(nil, @curator.id)
      temp_count2.should > temp_count

      data_object = DataObject.gen()
      activity = CuratorActivityLog.gen(user: @curator, target_id: data_object.id, changeable_object_type_id: ChangeableObjectType.data_object.id, activity_id: TranslatedActivity.find_by_name("trusted").id )
      temp_count = Curator.total_objects_curated_by_action_and_user(nil, @curator.id)
      temp_count.should > temp_count2
  end

  it 'should increase no. of curated taxa for a curator' do
      temp_count = @curator.total_species_curated

      taxon_concept = TaxonConcept.gen()
      data_object = DataObject.gen()
      dotc = DataObjectsTaxonConcept.gen(taxon_concept: taxon_concept, data_object: data_object)
      activity = CuratorActivityLog.gen(user: @curator, target_id: data_object.id, changeable_object_type_id: ChangeableObjectType.data_objects_hierarchy_entry.id, activity_id: TranslatedActivity.find_by_name("trusted").id )
      Rails.cache.clear
      temp_count2 = @curator.total_species_curated
      temp_count2.should > temp_count

      taxon_concept = TaxonConcept.gen()
      data_object = DataObject.gen()
      dotc = DataObjectsTaxonConcept.gen(taxon_concept: taxon_concept, data_object: data_object)
      activity = CuratorActivityLog.gen(user: @curator, target_id: data_object.id, changeable_object_type_id: ChangeableObjectType.data_objects_hierarchy_entry.id, activity_id: TranslatedActivity.find_by_name("trusted").id )
      Rails.cache.clear
      temp_count = @curator.total_species_curated
      temp_count.should > temp_count2
  end

  it 'should increase no. of articles added for a curator' do
    temp_count = UsersDataObject.count(conditions: ['user_id = ?',@curator.id])

    taxon_concept = TaxonConcept.gen()
    data_object = DataObject.gen()
    udo = UsersDataObject.gen(user: @curator, taxon_concept: taxon_concept, data_object: data_object, vetted: Vetted.trusted)
    temp_count2 = UsersDataObject.count(conditions: ['user_id = ?',@curator.id])
    temp_count2.should > temp_count

    taxon_concept = TaxonConcept.gen()
    data_object = DataObject.gen()
    udo = UsersDataObject.gen(user: @curator, taxon_concept: taxon_concept, data_object: data_object, vetted: Vetted.trusted)
    temp_count = UsersDataObject.count(conditions: ['user_id = ?',@curator.id])
    temp_count.should > temp_count2
  end

  it 'should add a user to the curator community when they become a curator' do
    user = User.gen(curator_level_id: nil)
    user.is_member_of?(CuratorCommunity.get).should_not be_true
    user.grant_curator(:assistant)
    user.is_member_of?(CuratorCommunity.get).should be_true
    # 'It should also work when instantly self-approved'
    user = User.gen(curator_level_id: nil)
    user.is_member_of?(CuratorCommunity.get).should_not be_true
    user.update_attributes(requested_curator_level_id: CuratorLevel.assistant.id)
    user.is_member_of?(CuratorCommunity.get).should be_true
  end

  it 'should remove a user from the curator community when they lose curator status' do
    user = User.gen(curator_level_id: CuratorLevel.assistant.id)
    user.is_member_of?(CuratorCommunity.get).should be_true
    user.revoke_curator
    user.is_member_of?(CuratorCommunity.get).should_not be_true
  end
  
end
