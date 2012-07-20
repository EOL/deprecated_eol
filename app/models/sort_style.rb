class SortStyle < ActiveRecord::Base
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :collections

  # Creates the default sort names with some logic around translations.
  def self.create_defaults
    TranslatedSortStyle.reset_cached_instances
    SortStyle.reset_cached_instances
    ['Recently Added', 'Oldest', 'Alphabetical', 'Reverse Alphabetical', 'Richness', 'Rating', 'Sort Field', 'Reverse Sort Field'].each do |name|
      sstyle = SortStyle.create
      begin
        TranslatedSortStyle.create(:name => name, :sort_style_id => sstyle.id, :language_id => Language.english.id)
      rescue ActiveRecord::StatementInvalid => e
        sstyle.name = name
        sstyle.save!
      end
    end
  end

  def self.newest
    cached_find_translated(:name, 'Recently Added', 'en')
  end

  def self.oldest
    cached_find_translated(:name, 'Oldest', 'en')
  end

  def self.alphabetical
    cached_find_translated(:name, 'Alphabetical', 'en')
  end

  def self.reverse_alphabetical
    cached_find_translated(:name, 'Reverse Alphabetical', 'en')
  end

  def self.richness
    cached_find_translated(:name, 'Richness', 'en')
  end

  def self.rating
    cached_find_translated(:name, 'Rating', 'en')
  end
  
  def self.sort_field
    cached_find_translated(:name, 'Sort Field', 'en')
  end
  
  def self.reverse_sort_field
    cached_find_translated(:name, 'Reverse Sort Field', 'en')
  end
  

end
