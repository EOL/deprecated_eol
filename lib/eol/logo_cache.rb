# Models using this will need to have a logo_cache_url
module EOL
  module LogoCache

    def self.included(base)
      base.before_save :create_media_download_status
    end

    def create_media_download_status
      if self.logo_cache_url_changed? && MediaDownloadStatus.table_exists? && Status.download_succeeded
        MediaDownloadStatus.delete_all(:target_row_type => self.class.name, :target_row_id => self.id)
        MediaDownloadStatus.create(:target_row_type => self.class.name, :target_row_id => self.id, :status_id => Status.download_succeeded.id, :peer_site_id => PEER_SITE_ID, :last_attempted => Time.now)
      end
    end

    def logo_url(size = 'large', options = {})
      if logo_cache_url.blank?
        case self.class.name
        when 'Collection'
          return "v2/logos/collection_default.png"
        when 'Community'
          return "v2/logos/community_default.png"
        when 'ContentPartner'
          return "v2/logos/partner_default.png"
        when 'User'
          if options[:mail]
            return "http://#{Rails.configuration.action_mailer.default_url_options[:host]}/images/v2/logos/user_default.png"
          end
          return "v2/logos/user_default.png"
        end
        
        return "#"
      elsif size.to_s == 'small'
        ContentServer.image_cache_path(logo_cache_url, '88_88', options.merge({ :source_object => self }))
      else
        ContentServer.image_cache_path(logo_cache_url, '130_130', options.merge({ :source_object => self }))
      end
    end

    def media_exists_on_this_peer?
      MediaDownloadStatus.find(:all, :conditions =>
        { :target_row_type => self.class.name,
          :target_row_id => self.id,
          :status_id => Status.download_succeeded.id,
          :peer_site_id => PEER_SITE_ID }) != []
    end

    def media_host
      all_statuses = MediaDownloadStatus.sort_by_peer(
        MediaDownloadStatus.find(:all, :conditions =>
          { :target_row_type => self.class.name,
            :target_row_id => self.id,
            :status_id => Status.download_succeeded.id }))
      return nil if all_statuses.blank?
      return all_statuses.first.peer_site.content_host_url_prefix
    end

  end
end
