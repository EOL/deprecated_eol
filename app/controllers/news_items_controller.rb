class NewsItemsController < ApplicationController
  
  layout 'v2/basic'
  
  def index
    @page_title = I18n.t(:page_title, :scope => [:news_items, :index])
    @news_items=NewsItem.paginate(:conditions=>['language_id=? and active=1 and activated_on<=?',Language.from_iso(I18n.locale.to_s), DateTime.now],:order=>'display_date desc',:page => params[:page], :per_page => 25)
    # @rel_canonical_href = recent_activities_url(:page => rel_canonical_href_page_number(@log))
    # @rel_prev_href = rel_prev_href_params(@log) ? recent_activities_url(@rel_prev_href_params) : nil
    # @rel_next_href = rel_next_href_params(@log) ? recent_activities_url(@rel_next_href_params) : nil
  end
  
  def show
    @news_item = NewsItem.find_by_id(params[:id])
    @page_title = @news_item.title
  end
    
end
