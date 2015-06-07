class CuratorsSuggestedSearch < ActiveRecord::Base
  # attr_accessible :title, :body
  def self.suggested_searches(lang)
    suggested_searches = CuratorsSuggestedSearch.find_all_by_language_id(lang.id)
    suggested_searches = CuratorsSuggestedSearch.find_all_by_language_id(Language.default.id) if suggested_searches.blank?
    suggested_searches
  end
end
