class UnpublishPreviousRevisionsOfUdo < ActiveRecord::Migration
  def self.up
    udos = UsersDataObject.find(:all, :include => :data_object)
    udos.each do |udo|
      if udo.data_object_id != udo.data_object.revisions.last.id
        udo.data_object.published = 0
        udo.data_object.save
      end
    end
  end
  def self.down
  end
end
