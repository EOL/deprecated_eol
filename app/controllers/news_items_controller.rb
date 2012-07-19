class NewsItemsController < ApplicationController
  
  layout 'v2/basic'
  
  # GET /news_items
  def index
    @rel_canonical_href = root_url.sub!(/\/+$/,'')
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
        if translated_news_item = translations.detect{|tr| tr.language_id == current_language.id && tr.active_translation == 1}
          translated_news_items << translated_news_item
        else
          active_translations = translations.collect{|tr| tr if tr.active_translation == 1}.compact
          translated_news_items << active_translations.sort_by(&:created_at).first unless active_translations.blank?
        end
      end
      @translated_news_items = translated_news_items.paginate(:page => params[:page], :per_page => 25)
    end
  end
  
  # GET /news/:id
  # GET /news_items/:id
  def show
    page_id = params[:id] # get the id parameter, which can be either a page ID # or a page name

    if page_id.is_int?
      news_item = NewsItem.find(page_id, :include => :translations)
    else # assume it's a page name
      news_item = NewsItem.find_by_page_name(page_id, :include => :translations)
      debugger
      news_item ||= NewsItem.find_by_page_name(page_id.gsub(' ', '_'), :include => :translations) # will become obsolete once validation on page_name is in place
      raise ActiveRecord::RecordNotFound, "Couldn't find NewsItem with page_name=#{page_id}" if news_item.nil?
    end

    if ! news_item.nil? && ! current_user.can_read?(news_item) && ! logged_in?
      raise EOL::Exceptions::MustBeLoggedIn, "Non-authenticated user does not have read access to NewsItem with ID=#{news_item.id}"
    elsif ! current_user.can_read?(news_item)
      raise EOL::Exceptions::SecurityViolation, "User with ID=#{current_user.id} does not have read access to NewsItem with ID=#{news_item.id}"
    else # page exists so now we look for actual content i.e. a translated page
      if news_item.translations.blank?
        raise ActiveRecord::RecordNotFound, "Couldn't find TranslatedNewsItem with content_page_id=#{news_item.id}"
      else
        translations_available_to_user = news_item.translations.select{|t| current_user.can_read?(t)}.compact
        if translations_available_to_user.blank?
          if logged_in?
            raise EOL::Exceptions::SecurityViolation, "User with ID=#{current_user.id} does not have read access to any TranslatedNewsItem with news_item_id=#{news_item.id}"
          else
            raise EOL::Exceptions::MustBeLoggedIn, "Non-authenticated user does not have read access to any TranslatedNewsItem with news_item_id=#{news_item.id}"
          end
        else
          # try and render preferred language translation, otherwise links to other available translations will be shown
          @selected_language = params[:language] ? Language.from_iso(params[:language]) :
            Language.from_iso(current_language.iso_639_1)
          @translated_news_items = translations_available_to_user
          @translated_news_item = translations_available_to_user.select{|t| t.language_id == @selected_language.id}.compact.first
          @page_title = @translated_news_item.nil? ? I18n.t(:news_missing_content_title) : @translated_news_item.title
          current_user.log_activity(:viewed_content_page_id, :value => page_id)
          @rel_canonical_href = news_url(news_item)
        end
      end
    end
  end

end
