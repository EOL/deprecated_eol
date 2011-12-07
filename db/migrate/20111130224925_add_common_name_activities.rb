class AddCommonNameActivities < ActiveRecord::Migration
  def self.up
    Activity.find_or_create('trust_common_name')
    Activity.find_or_create('untrust_common_name')
    Activity.find_or_create('inappropriate_common_name')
    Activity.find_or_create('unreview_common_name')
    Activity.find_or_create('add_common_name')
    Activity.find_or_create('remove_common_name')
  end
  def self.down
    # Doesn't matter
  end
end
