require File.dirname(__FILE__) + '/../spec_helper'

  #------- Actions History ----------
  describe '#new_actions_histories' do

    scenario :foundation # Just so we have DataType IDs and the like.
    
    before(:each) do
      commit_transactions
      @taxon_concept = build_taxon_concept
      @dato_image    = @taxon_concept.images.last
      @dato_text     = DataObject.gen(:data_type_id =>
                                      DataType.text_type_ids.first)
      @user          = @taxon_concept.acting_curators.to_a.last
      @num_ah        = ActionsHistory.count
    end

    after(:each) do
      truncate_all_tables
    end
    
    #? loop over all actions with all objects (not only image/text, e.g. sounds too)? 
    #? test if non curator?
    
    
    it 'should create a new ActionsHistory pointing to the right object, user, type and action' do      
      action_c       = ActionWithObject.find_by_action_code('untrusted')
      ch_object_type = ChangeableObjectType.find_by_ch_object_type('data_object')
      @dato_image.new_actions_histories(@user, @dato_image, ch_object_type.ch_object_type, action_c.action_code)     
      
      ActionsHistory.count.should                          == @num_ah + 1
      ActionsHistory.last.user_id.should                   == @user.id
      ActionsHistory.last.object_id.should                 == @dato_image.id
      ActionsHistory.last.changeable_object_type_id.should == ch_object_type.id
      ActionsHistory.last.action_with_object_id.should     == action_c.id
    end

    it 'should set an actions history when a curator curates this data object' do
      current_count = @num_ah
      ['hide', 'show', 'inappropriate', 'approve', 'disapprove'].each do |method|
        @dato_image.curate! CuratorActivity.send("#{method}!"), @user
        ActionsHistory.count.should == (current_count += 1)
      end
    end
    
    it 'should set an actions history when a curator creates a new text object' do
      DataObject.create_user_text(
        {:data_object => {:description => "fun!",
                          :title => 'funnerer',
                          :license_id => License.last.id,
                          :language_id => Language.english.id},
         :taxon_concept_id => @taxon_concept.id,
         :data_objects_toc_category => {:toc_id => TocItem.overview.id}},
        @user)
      ActionsHistory.count.should == @num_ah + 1
    end
    
    it 'should set an actions history when a curator updates a text object' do
      # I tried gen here, but it wasn't working (JRice)
      UsersDataObject.create(:data_object_id => @dato_image.id,
                             :user_id => @user.id)
      DataObject.update_user_text(
        {:data_object => {:description => "fun!",
                          :title => 'funnerer',
                          :license_id => License.last.id,
                          :language_id => Language.english.id},
         :id => @dato_image.id,
         :taxon_concept_id => @taxon_concept.id,
         :data_objects_toc_category => {:toc_id => TocItem.overview.id}},
        @user)
      ActionsHistory.count.should == @num_ah + 1
    end
    
      # it 'should create a new ActionsHistory when smb delete an user submitted text'
      #there is no "delete" in a model yet
    
    it 'should set an actions history when one create a comment' do
      action_c       = ActionWithObject.find_by_action_code("create")
      ch_object_type = ChangeableObjectType.find_by_ch_object_type("comment")
      
      @dato_image.comment(@user, "My test text")
      
      ActionsHistory.count.should                          == (@num_ah += 1)
    end
        
    # join this two tests
    
    it 'should set an actions history when one hide a comment' do
      action_c       = ActionWithObject.find_by_action_code("hide")
      ch_object_type = ChangeableObjectType.find_by_ch_object_type("comment")
      
      comment = @dato_image.comment(@user, "My test comment")
      comment.hide! @user
      
      ActionsHistory.count.should                          == (@num_ah += 2)
    end
    
    it 'should set an actions history when one show a comment' do
      action_c       = ActionWithObject.find_by_action_code("show")
      ch_object_type = ChangeableObjectType.find_by_ch_object_type("comment")
      
      comment = @dato_image.comment(@user, "My test comment")
      comment.show! @user
      
      ActionsHistory.count.should                          == (@num_ah += 2)
    end

  end
  