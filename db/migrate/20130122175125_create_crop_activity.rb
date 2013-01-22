class CreateCropActivity < ActiveRecord::Migration
  def self.up
    Activity.find_or_create('crop')
  end

  def self.down
    # Nothing to do.
  end
end
