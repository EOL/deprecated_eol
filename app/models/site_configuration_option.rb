class SiteConfigurationOption < ActiveRecord::Base

  after_create :clear_caches
  after_update :clear_caches
  validates_uniqueness_of :parameter
  
  def self.reference_parsing_enabled
    cached_find(:parameter, 'reference_parsing_enabled')
  end
  
  def self.reference_parser_endpoint
    cached_find(:parameter, 'reference_parser_endpoint')
  end
  
  def self.reference_parser_pid
    cached_find(:parameter, 'reference_parser_pid')
  end

  def clear_caches
    $CACHE.fetch("application/#{self.parameter}") if self.parameter
  end

end
