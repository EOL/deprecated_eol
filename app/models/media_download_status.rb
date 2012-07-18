class MediaDownloadStatus < ActiveRecord::Base
  belongs_to :target_row, :polymorphic => true
  belongs_to :peer_site
  belongs_to :status
  
  # put the status from this peer first in the last
  def self.sort_by_peer(media_download_statuses)
    media_download_statuses.sort_by do |status|
      (status.peer_site_id == PEER_SITE_ID) ? 0 : 1
    end
  end
  
  def self.media_exists_on_this_peer?(klass_instance)
    MediaDownloadStatus.find(:all, :conditions =>
      { :target_row_type => klass_instance.class.name,
        :target_row_id => klass_instance.id,
        :status_id => Status.download_succeeded.id,
        :peer_site_id => PEER_SITE_ID }) != []
  end

  def self.media_host(klass_instance)
    all_statuses = MediaDownloadStatus.sort_by_peer(
      MediaDownloadStatus.find(:all, :conditions =>
        { :target_row_type => klass_instance.class.name,
          :target_row_id => klass_instance.id,
          :status_id => Status.download_succeeded.id }))
    return nil if all_statuses.blank?
    return all_statuses.first.peer_site.content_host_url_prefix
  end
  
end
