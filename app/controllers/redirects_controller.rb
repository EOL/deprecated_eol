# Rails 2.3.x does not allow redirects in routes file so using this to conveniently and
# centrally manage 301 redirects for legacy URLs, these can be moved to routes file if we
# upgrade to Rails 3
class RedirectsController < ApplicationController

  def show
    if params[:url]
      to_url = params[:url]

    elsif params[:cms_page_id]
      to_url = cms_page_path(params[:cms_page_id])

    elsif params[:taxon_id]
      case params[:sub_tab]
      when 'curators'
        to_url = curators_taxon_communities_path(params[:taxon_id])
      when 'maps'
        to_url = taxon_maps_path(params[:taxon_id])
      when 'media'
        to_url = taxon_media_path(params[:taxon_id])
      else
        to_url = taxon_overview_path(params[:taxon_id])
      end

    elsif params[:user_id]
      if params[:recover_account_token]
        to_url = temporary_login_user_url(params[:user_id], params[:recover_account_token])
      else
        to_url = user_path(params[:user_id])
      end

    elsif params[:conditional_redirect_id]
      case params[:conditional_redirect_id]
      when 'recover_account'
        to_url = recover_account_users_url
      when 'exemplars'
        collection_ids = {
          :en => 34,
          :ar => 7745,
          :es => 6496 }
        to_url = collection_path(collection_ids[I18n.locale] || collection_ids[:en])
      end

    elsif params[:collection_id]
      to_url = collection_path(params[:collection_id])
    end

    redirect_to to_url || :root, :status => :moved_permanently
  end

end
