class SiteConfigurationOption < ActiveRecord::Base
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
end
