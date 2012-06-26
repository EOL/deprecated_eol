class AddDownloadStatus < ActiveRecord::Migration
  def self.up
    execute 'CREATE TABLE `media_download_statuses` (
      `id` int unsigned NOT NULL AUTO_INCREMENT,
      `target_row_type` varchar(255) NOT NULL,
      `target_row_id` int unsigned NOT NULL,
      `peer_site_id` tinyint unsigned NOT NULL,
      `status_id` smallint unsigned NOT NULL,
      `failed_attempts` tinyint unsigned NOT NULL DEFAULT 0,
      `last_attempted` timestamp NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`target_row_type`, `target_row_id`, `peer_site_id`),
      KEY `status_failed_attempts` (`peer_site_id`, `failed_attempts`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8'
    
    # create some new statuses for downloading media
    ['Download Pending', 'Download In Progress', 'Download Succeeded', 'Download Failed'].each do |status_label|
      unless Status.find_by_translated(:label, status_label)
        status = Status.create()
        TranslatedStatus.create(:label => status_label, :language => Language.english_for_migrations, :status => status)
      end
    end
  end

  def self.down
    drop_table :media_download_statuses
    ['Download Pending', 'Download In Progress', 'Download Succeeded', 'Download Failed'].each do |status_label|
      status = Status.find_by_translated(:label, status_label)
      status.translations.each{ |tr| tr.destroy }
      status.destroy
    end
  end
end
