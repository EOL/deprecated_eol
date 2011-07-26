class MoveInappropriateFromVisibilityToVetted < ActiveRecord::Migration
  def self.up
    if inappropriate_visibility = Visibility.find_by_translated(:label, 'Inappropriate', 'en')
      inappropriate_visibility.translations.destroy_all
      
      inappropriate_vetted = Vetted.create(:view_order => 4)
      TranslatedVetted.create(:vetted => inappropriate_vetted, :label => 'Inappropriate',
        :language => Language.english)
      
      # Convert all the data objects of any vetted statuses and visibility status as inappropriate
      # to vetted status as inappropriate and visibility status as hidden
      execute("update data_objects set
        vetted_id = #{inappropriate_vetted.id},
        visibility_id = #{Visibility.invisible.id}
        where visibility_id = #{inappropriate_visibility.id}")
      inappropriate_visibility.destroy
    end
  end

  def self.down
    if inappropriate_vetted = Vetted.find_by_translated(:label, 'Inappropriate', 'en')
      inappropriate_vetted.translations.destroy_all
      
      inappropriate_visibility = Visibility.create()
      TranslatedVisibility.create(:visibility => inappropriate_visibility, :label => 'Inappropriate',
        :language => Language.english)
      
      # Data objects are irreversibile to their previous vetted statuses if they were trusted or unreviewed
      # but either way it doesn't make sense to have data objects with vetted and visibility statuses as 
      # (trusted and inappropriate) or (unreviewed and inappropriate) respectively.
      # So here I'm reverting them to (untrusted and inappropriate).
      execute("update data_objects set
        vetted_id = #{Vetted.untrusted.id},
        visibility_id = #{inappropriate_visibility.id}
        where vetted_id = #{inappropriate_vetted.id}")
      inappropriate_vetted.destroy
    end
  end
end
