class NewsItem < ActiveRecord::Base
  uses_translations
  belongs_to :user
  
  
  def visible?
    self.activated_on <= Time.now && self.active
  end
  
  # title or body (max 250 chars), stripped of HTML
  def summary
    if self.title.blank?
      result=self.body.length < 250 ? self.body : self.body[0..250] + "..."
    else
      result=self.title
    end
    result.gsub(/<\/?[^>]*>/, "")
  end

  def value
    self.title.blank? ? self.body : self.title
  end
  
  def not_available_in_languages(force_exist_language)
    if self.id
      if force_exist_language
        return Language.find_by_sql("select * from languages where (not exists (select * from translated_news_items where language_id=languages.id and news_item_id=#{self.id}) or languages.id=#{force_exist_language.id}) and activated_on <= '#{Time.now.to_s(:db)}' order by sort_order ASC")
      else
        return Language.find_by_sql("select * from languages where (not exists (select * from translated_news_items where language_id=languages.id and news_item_id=#{self.id})) and activated_on <= '#{Time.now.to_s(:db)}' order by sort_order ASC")
      end
    else
      return Language.find_active
    end
  end

  def page_url
    all_pages_with_this_name = NewsItem.find_all_by_page_name(page_name)
    if all_pages_with_this_name.count > 1 && all_pages_with_this_name.first != self
      return self.id
    else
      return self.page_name.gsub(' ', '_').downcase
    end
  end

  def alternate_page_url
    all_pages_with_this_name = NewsItem.find_all_by_page_name(page_name)
    if all_pages_with_this_name.count == 1
      return self.id
    end
  end
  
  def self.homepage_news_for_user(current_user, current_language)
    if current_user.news_in_preferred_language
      translated_news_items = TranslatedNewsItem.find(:all, :conditions=>['translated_news_items.language_id = ? and translated_news_items.active_translation=1 and news_items.active=1 and news_items.activated_on<=?', Language.from_iso(current_language.iso_639_1), DateTime.now.utc], :joins => "inner join news_items on news_items.id = translated_news_items.news_item_id", :order=>'news_items.display_date desc', :limit => $NEWS_ON_HOME_PAGE)
    else
      news_items = NewsItem.find(:all, :conditions=>['news_items.active=1 and news_items.activated_on<=?', DateTime.now.utc],
        :order=>'news_items.display_date desc', :include => :translations, :limit => $NEWS_ON_HOME_PAGE)
      translated_news_items = []
      news_items.each do |news_item|
        translations = news_item.translations
        if translated_news_item = translations.detect{|tr| tr.language_id == current_language.id && tr.active_translation == 1}
          translated_news_items << translated_news_item
        else
          active_translations = translations.collect{|tr| tr if tr.active_translation == 1}.compact
          translated_news_items << active_translations.sort_by{|t| t.created_at || 0}.first unless active_translations.blank?
        end
      end
    end
    translated_news_items
  end

private

  def destroy_translations
    translations.each do |translated_news_item|
      translated_news_item.destroy
    end
  end

end
