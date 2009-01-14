class DataObjectObserver < ActiveRecord::Observer
  
  observe :data_object
  
  def before_save data_object
    if data_object.vetted_id_changed? and data_object.vetted_by
      was = Vetted.find data_object.vetted_id_was
      is  = Vetted.find data_object.vetted_id

      if is == Vetted.trusted
        CuratorDataObjectLog.create :data_object => data_object, :user => data_object.vetted_by, :curator_activity => CuratorActivity.approve!
      elsif is == Vetted.untrusted
        CuratorDataObjectLog.create :data_object => data_object, :user => data_object.vetted_by, :curator_activity => CuratorActivity.disapprove!
      end
    end
  end
  
end
