class RemovePublishingRelatedResourceStatuses < ActiveRecord::Migration
  def self.up
    status_ids_to_remove = TranslatedResourceStatus.find_all_by_label(['Publish Pending', 'Unpublish Pending']).collect{|trs| trs.resource_status_id}.compact
    unless status_ids_to_remove.blank?
      execute("DELETE FROM `resource_statuses` WHERE `id` IN(#{status_ids_to_remove.join(',')})")
      execute("DELETE FROM `translated_resource_statuses` WHERE `resource_status_id` IN(#{status_ids_to_remove.join(',')})")
    end
  end

  def self.down
    if Language.english
      ['Publish Pending', 'Unpublish Pending'].each do |status_label|
        ResourceStatus.create(
          :translations => [TranslatedResourceStatus.new(:label => status_label, :language_id => english.id)]
        )
      end
    end
  end
end
