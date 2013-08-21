class RefIdentifierType < ActiveRecord::Base
  has_many :ref_identifiers

  def self.url
    @@url ||= cached_find(:label, 'url')
  end

  def self.doi
    @@doi ||= cached_find(:label, 'doi')
  end

end
