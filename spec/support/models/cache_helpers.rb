module Models
  module CacheHelpers

    def clear_rank_caches
      Rank.class_variable_set('@@italicized_rank_ids', nil)
      Rails.cache.delete(Rank.cached_name_for('italicized'))
    end
    
  end
end
