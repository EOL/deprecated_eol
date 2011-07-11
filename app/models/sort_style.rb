class SortStyle < ActiveRecord::Base

  CACHE_ALL_ROWS = true
  uses_translations
  has_many :collections

  # Creates the default sort names with some logic around translations.
  def self.create_defaults
    ['Recently Added', 'Oldest'].each do |name|
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
    cached_find_translated(:name, 'Recently Added')
  end

  def self.oldest
    cached_find_translated(:name, 'Oldest')
  end

end
