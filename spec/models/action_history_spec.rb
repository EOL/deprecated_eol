require File.dirname(__FILE__) + '/../spec_helper'

describe ActionsHistory do

  load_foundation_cache
    
  describe '#new_actions_histories' do

    before(:all) do
      @taxon_concept = build_taxon_concept
      @dato_image    = @taxon_concept.images.last
      @dato_text     = DataObject.gen(:data_type_id =>
                                      DataType.text_type_ids.first)
      @user          = @taxon_concept.acting_curators.to_a.last
      @num_ah        = ActionsHistory.count
    end

    after(:all) do
      truncate_all_tables
    end
    
    it 'should set an actions history when a curator untrusts a data object' do
      comment_body = 'This is a bad image'
      untrust_reasons = [UntrustReason.misidentified.id, UntrustReason.incorrect.id]
      params = { :comment => comment_body,
                 :vetted_id => Vetted.untrusted.id,
                 :untrust_reasons => untrust_reasons,
                 :taxon_concept_id => @taxon_concept.id,
                 :visibility_id => Visibility.invisible.id }
      @dato_image.curate params[:vetted_id], params[:visibility_id], @user, params[:untrust_reasons], params[:comment], params[:taxon_concept_id]
      
      ah = ActionsHistory.find_by_user_id_and_object_id_and_action_with_object_id(@user.id, @dato_image.id, ActionWithObject.untrusted.id, :include => [:comment, :untrust_reasons])
      ah.should_not == nil
      ah.comment.body.should == comment_body
      
      saved_untrust_reason_ids = ah.untrust_reasons.collect{|ur| ur.id}
      untrust_reasons.each do |ur|
        saved_untrust_reason_ids.include?(ur).should == true
      end
      
    end
    
    it 'should set an actions history when a curator curates this data object' do
      current_count = ActionsHistory.count
      [Vetted.trusted.id, Vetted.untrusted.id].each do |vetted_method|
        [Visibility.invisible.id, Visibility.visible.id, Visibility.inappropriate.id].each do |visibility_method|
          @dato_image.curate vetted_method, visibility_method, @user
          ActionsHistory.count.should == (current_count += 2)
        end
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
    
    it 'should set an actions history when one creates, hides, or shows a comment' do
      @dato_image.comment(@user, "My test text")
      ActionsHistory.count.should                          == (@num_ah += 1)
      comment = @dato_image.comment(@user, "My test comment")
      ActionsHistory.count.should                          == (@num_ah += 1)
      comment = @dato_image.comment(@user, "My test comment")
      ActionsHistory.count.should                          == (@num_ah += 1)
    end
        
  end
  
end
