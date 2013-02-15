module DataObjectsHelper

  def link_to_full_size
    if @data_object.is_image?
      if @data_object.access_image_from_remote_server?(:orig)
        content_tag('p', link_to(I18n.t(:view_full_size_image), @data_object.object_url))
      else
        content_tag('p', link_to(I18n.t(:view_full_size_image), @data_object.thumb_or_object(:orig)))
      end
    end
  end

end
