class ForumTopicLinkRenderer < WillPaginate::ActionView::LinkRenderer
  def url(page)
    @base_url_params ||= begin
      url_params = merge_get_params(default_url_params)
      merge_optional_params(url_params)
    end

    url_params = @base_url_params.dup
    add_current_page_param(url_params, page)
    @base_url_params ||= begin
      url_params = merge_get_params(default_url_params)
      merge_optional_params(url_params)
    end

    url_params = { :controller => 'forums/topics', :action => 'show', :id => @template.instance_variable_get('@topic').id }
    add_current_page_param(url_params, page)

    @template.url_for(url_params)
  end
end
