# Rails 2.3.x does not allow redirects in routes file so using this to conveniently and
# centrally manage 301 redirects for legacy URLs, these can be moved to routes file if we
# upgrade to Rails 3
class RedirectsController < ApplicationController

  def show
    if params[:url]
      redirect_to params[:url], :status => :moved_permanently and return
    elsif params[:cms_page_id]
      redirect_to cms_page_path(params[:cms_page_id]), :status => :moved_permanently and return
    elsif params[:taxon_id]
      redirect_to taxon_overview_path(params[:taxon_id]), :status => :moved_permanently and return
    elsif params[:conditional_redirect_id] == 'exemplars'
      collection_ids = {
        :en => 34,
        :ar => 7745,
        :es => 6496
      }
      redirect_to collection_path(collection_ids[I18n.locale] || collection_ids[:en]), :status => :moved_permanently and return
    else
      redirect_to :root, :status => :moved_permanently
    end
  end

end
