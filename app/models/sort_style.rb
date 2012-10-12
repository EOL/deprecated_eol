class SortStyle < ActiveRecord::Base
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :collections

  def self.create_defaults
    TranslatedSortStyle.reset_cached_instances
    SortStyle.reset_cached_instances
    ['Recently Added', 'Oldest', 'Alphabetical', 'Reverse Alphabetical', 'Richness', 'Rating', 'Sort Field', 'Reverse Sort Field'].each do |name|
      unless TranslatedSortStyle.exists?(:language_id => Language.english.id, :name => name)
        sstyle = SortStyle.create
        TranslatedSortStyle.create(:name => name, :sort_style_id => sstyle.id, :language_id => Language.english.id)
        sstyle.save!
      end
    end
  end

  def self.newest
    cached_find_translated(:name, 'Recently Added')
  end

  def self.oldest
    cached_find_translated(:name, 'Oldest')
  end

  def self.alphabetical
    cached_find_translated(:name, 'Alphabetical')
  end

  def self.reverse_alphabetical
    cached_find_translated(:name, 'Reverse Alphabetical')
  end

  def self.richness
    cached_find_translated(:name, 'Richness')
  end

  def self.rating
    cached_find_translated(:name, 'Rating')
  end
  
  def self.sort_field
    cached_find_translated(:name, 'Sort Field')
  end
  
  def self.reverse_sort_field
    cached_find_translated(:name, 'Reverse Sort Field')
  end
  

end
