# encoding: utf-8

# TODO: NEEDS SPECS!
module EOL
  # Uses paperclip to handle logo icons
  module Logos
    extend ActiveSupport::Concern

    included do
      has_attached_file :logo,
        path: Rails.configuration.logo_uploads.paperclip_path,
        url: Rails.configuration.logo_uploads.paperclip_path,
        default_url: "/assets/blank.gif"
      validates_attachment_content_type :logo,
        message: I18n.t(:logo_type_error),
        content_type: %w(image/pjpeg image/jpeg image/png image/gif image/x-png)
      validates_attachment_size :logo,
        in: 0..Rails.configuration.logo_uploads.max_size
    end

    def reload_if_missing_logo_attributes
      reload unless self.has_attribute?(:logo_file_name) &&
        self.has_attribute?(:logo_cache_url)
    end

    def logo_url(opts = {})
      reload_if_missing_logo_attributes
      if !logo_file_name.blank? &&
        !Rails.configuration.use_content_server_for_thumbnails
        Rails.configuration.logo_uploads.relative_path +
          ImageManipulation.local_file_name(self)
      elsif logo_cache_url.blank?
        "v2/logos/#{self.class.name.underscore.sub(%r{/.*\z}, '')}_default.png"
      else
        link = opts[:linked?] ? Rails.configuration.asset_host : nil
        DataObject.image_cache_path(
          logo_cache_url,
          opts[:size] == :small ? "88_88" : "130_130",
          specified_content_host: link
        )
      end
    end
  end
end
