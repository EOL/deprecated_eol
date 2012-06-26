class MediaDownloadStatus < ActiveRecord::Base
  belongs_to :target_row, :polymorphic => true
  belongs_to :peer_site
  belongs_to :status
end
