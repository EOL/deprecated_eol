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
end
