class MoveInappropriateFromVisibilityToVetted < ActiveRecord::Migration
  def self.up    
    Language.all.each do |lang|
      visibility_inap = TranslatedVisibility.find_by_label_and_language_id('Inappropriate', lang.id)
      unless visibility_inap.blank?
        TranslatedVisibility.find_by_label_and_language_id('Inappropriate', lang.id).destroy
        Visibility.find(visibility_inap.visibility_id).destroy if lang.id == TranslatedLanguage.find_by_label("english").id
      
        vetted_inap = Vetted.create(:view_order => 4)
        TranslatedVetted.create(:vetted_id => vetted_inap.id, :label => 'Inappropriate', :language_id => lang.id)
      
        # Convert all the data objects of any vetted statuses and visibility status as inappropriate
        # to vetted status as inappropriate and visibility status as hidden
        execute("update data_objects set vetted_id = #{TranslatedVetted.find_by_label('inappropriate').id}, visibility_id = #{TranslatedVisibility.find_by_label('hidden').id} 
                  where visibility_id = #{visibility_inap.id}") if lang.id == TranslatedLanguage.find_by_label("english").id
      end
    end
  end

  def self.down
    Language.all.each do |lang|
      vetted_inap = TranslatedVetted.find_by_label_and_language_id('Inappropriate', lang.id)
      unless vetted_inap.blank?
        TranslatedVetted.find_by_label_and_language_id('Inappropriate', lang.id).destroy
        Vetted.find(vetted_inap.vetted_id).destroy if lang.id == TranslatedLanguage.find_by_label("english").id
      
        visibility_inap = Visibility.create()
        TranslatedVisibility.create(:visibility_id => visibility_inap.id, :label => 'Inappropriate', :language_id => lang.id)
      
        # Data objects are irreversibile to their previous vetted statuses if they were trusted or unreviewed
        # but either way it doesn't make sense to have data objects with vetted and visibility statuses as 
        # (trusted and inappropriate) or (unreviewed and inappropriate) respectively.
        # So here I'm reverting them to (untrusted and inappropriate).
        execute("update data_objects set vetted_id = #{TranslatedVetted.find_by_label('untrusted').id}, visibility_id = #{TranslatedVisibility.find_by_label('inappropriate').id} 
                  where vetted_id = #{vetted_inap.id}") if TranslatedLanguage.find_by_label("english").id
      end
    end
  end
end
