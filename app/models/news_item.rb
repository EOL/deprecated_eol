class NewsItem < ActiveRecord::Base
  uses_translations
  include EOL::PeerSites

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
  
end
