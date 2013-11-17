class SortStyle < ActiveRecord::Base

  CACHE_ALL_ROWS = true
  uses_translations
  has_many :collections

  include Enumerated
  enumerated :name, 
        [{newest: 'Recently Added'},
         'Oldest',
         'Alphabetical',
         'Reverse Alphabetical',
         'Richness',
         'Rating',
         'Sort Field',
         'Reverse Sort Field']

  def self.create_defaults
    ['Recently Added', 'Oldest', 'Alphabetical', 'Reverse Alphabetical', 'Richness', 'Rating', 'Sort Field', 'Reverse Sort Field'].each do |name|
      unless TranslatedSortStyle.exists?(:language_id => Language.english.id, :name => name)
        sstyle = SortStyle.create
        TranslatedSortStyle.create(:name => name, :sort_style_id => sstyle.id, :language_id => Language.english.id)
        sstyle.save!
      end
    end
  end

end
