class NewsItemsController < ApplicationController
  
  layout 'v2/basic'
  
  def index
    @page_title = I18n.t(:page_title, :scope => [:news_items, :index])
    if current_user.news_in_preferred_language
      @translated_news_items = TranslatedNewsItem.paginate(
        :conditions=>['translated_news_items.language_id = ? and translated_news_items.active_translation=1 and news_items.active=1 and news_items.activated_on<=?', Language.from_iso(current_language.iso_639_1), DateTime.now.utc],
        :joins => "inner join news_items on news_items.id = translated_news_items.news_item_id",
        :order=>'news_items.display_date desc', :page => params[:page], :per_page => 25)
    else
      news_items = NewsItem.find(:all, :conditions=>['news_items.active=1 and news_items.activated_on<=?', DateTime.now.utc],
        :order=>'news_items.display_date desc', :include => :translations)
      translated_news_items = []
      news_items.each do |news_item|
        translations = news_item.translations
        if translated_news_item = translations.detect{|tr| tr.language_id == current_language.id}
          translated_news_items << translated_news_item
        else
          translated_news_items << translations.sort_by(&:created_at).first
        end
      end
      @translated_news_items = translated_news_items.paginate(:page => params[:page], :per_page => 25)
    end

    # @rel_canonical_href = recent_activities_url(:page => rel_canonical_href_page_number(@log))
    # @rel_prev_href = rel_prev_href_params(@log) ? recent_activities_url(@rel_prev_href_params) : nil
    # @rel_next_href = rel_next_href_params(@log) ? recent_activities_url(@rel_next_href_params) : nil
  end
  
  def show
    @selected_language = params[:language] ? Language.from_iso(params[:language]) :
      Language.from_iso(current_language.iso_639_1)
    @translated_news_item = TranslatedNewsItem.find_by_news_item_id_and_language_id(params[:id], @selected_language)
    @page_title = @translated_news_item.title
  end
    
end
