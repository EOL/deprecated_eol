require 'redcarpet'
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

  def sort_refs(references)
    references.sort_by!{ |r| r.full_reference.to_s }
  end

  def markdown(text)
    options = {
      filter_html:     true,
      hard_wrap:       true,
      space_after_headers: true,
      fenced_code_blocks: true
    }

    extensions = {
      autolink:           true,
      superscript:        true,
      disable_indented_code_blocks: true
    }

    renderer = ::Redcarpet::Render::HTML.new(options)
    markdown = ::Redcarpet::Markdown.new(renderer, extensions)

    markdown.render(text).html_safe
  end

end
