class AddPublishToHarvestEvents < ActiveRecord::Migration
  def self.up
    add_column :harvest_events, :publish, :boolean, :default => 0, :null => false
    unless ResourceStatus.all.blank? # don't try to move data if we haven't don't have any
      statuses = [ResourceStatus.published.id, ResourceStatus.publish_pending.id, ResourceStatus.unpublish_pending.id]
      Resource.all(:conditions => { :resource_status_id => statuses }).each do |resource|
        if resource.resource_status_id == ResourceStatus.publish_pending.id
          resource.latest_harvest_event.update_attributes(:publish => true) unless resource.latest_harvest_event.blank?
        end
        resource.update_attributes(:resource_status_id => ResourceStatus.processed.id)
      end
    end
  end

  def self.down
    unless ResourceStatus.all.blank?
      Resource.all(:conditions => { :resource_status_id => ResourceStatus.processed.id }).each do |resource|
        if ! resource.latest_harvest_event.blank?
          if resource.latest_harvest_event.publish? && resource.latest_harvest_event.published_at.nil?
            resource.update_attributes(:resource_status_id => ResourceStatus.publish_pending.id)
          elsif resource.latest_harvest_event.published_at.is_a? Time
            resource.update_attributes(:resource_status_id => ResourceStatus.published.id)
          end
        end
      end
    end
    remove_column :harvest_events, :publish
  end
end
