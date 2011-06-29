require File.dirname(__FILE__) + '/../spec_helper'

describe CuratorActivityLog do
  truncate_all_tables
  load_foundation_cache

  describe '#new_curator_activity_logs' do

    before(:all) do
      @taxon_concept = build_taxon_concept
      @dato_image    = @taxon_concept.images.last
      @dato_text     = DataObject.gen(:data_type_id =>
                                      DataType.text_type_ids.first)
      @user          = @taxon_concept.acting_curators.to_a.last
    end

    before(:each) do
      @num_ah = CuratorActivityLog.count
    end

    after(:all) do
      truncate_all_tables
    end

    it 'should log curator activity when a curator untrusts a data object'
    #   comment_body = 'This is a bad image'
    #   untrust_reasons = [UntrustReason.misidentified.id, UntrustReason.incorrect.id]
    #   params = { :comment => comment_body,
    #              :vetted_id => Vetted.untrusted.id,
    #              :untrust_reasons => untrust_reasons,
    #              :taxon_concept_id => @taxon_concept.id,
    #              :visibility_id => Visibility.invisible.id }
    #   @dato_image.curate(@user, :vetted_id =>  params[:vetted_id], :visibility_id => params[:visibility_id], :untrust_reason_ids => params[:untrust_reasons], :comment => params[:comment], :taxon_concept_id => params[:taxon_concept_id])
    #
    #   ah = CuratorActivityLog.find_by_user_id_and_object_id_and_activity_id(@user.id, @dato_image.id, Activity.untrusted.id, :include => [:comment, :untrust_reasons])
    #   ah.should_not == nil
    #   ah.comment.body.should == comment_body
    #
    #   saved_untrust_reason_ids = ah.untrust_reasons.collect{|ur| ur.id}
    #   untrust_reasons.each do |ur|
    #     saved_untrust_reason_ids.include?(ur).should == true
    #   end
    #
    # end

    it 'should log curator activity when a curator curates this data object'
    #   current_count = CuratorActivityLog.count
    #   [Vetted.trusted.id, Vetted.untrusted.id].each do |vetted_method|
    #     [Visibility.invisible.id, Visibility.visible.id, Visibility.inappropriate.id].each do |visibility_method|
    #       @dato_image.curate(@user, :vetted_id => vetted_method, :visibility_id => visibility_method)
    #       CuratorActivityLog.count.should == (current_count += 2)
    #     end
    #   end
    # end

    it 'should log curator activity when a curator creates a new text object' do
      DataObject.create_user_text(
        {:data_object => {:description => "fun!",
                          :title => 'funnerer',
                          :license_id => License.last.id,
                          :language_id => Language.english.id},
         :taxon_concept_id => @taxon_concept.id,
         :data_objects_toc_category => {:toc_id => TocItem.overview.id}},
        @user)
      CuratorActivityLog.count.should == @num_ah + 1
    end

    it 'should log curator activity when a curator updates a text object' do
      # I tried gen here, but it wasn't working (JRice):
      UsersDataObject.create(:data_object_id => @dato_image.id, :user_id => @user.id)
      DataObject.update_user_text(
        {:data_object => {:description => "fun!",
                          :title => 'funnerer',
                          :license_id => License.last.id,
                          :language_id => Language.english.id},
         :id => @dato_image.id,
         :taxon_concept_id => @taxon_concept.id,
         :data_objects_toc_category => {:toc_id => TocItem.overview.id}},
        @user)
      CuratorActivityLog.count.should >= @num_ah + 1 # >= because it could have created two logs.
    end

  end

end
