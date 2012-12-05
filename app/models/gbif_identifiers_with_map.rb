class GbifIdentifiersWithMap < ActiveRecord::Base
  # I don't understand why this is required, since we turned whitelist_attributes off in the config, but I'm running
  # out of ideas, so:
  attr_accessible :gbif_taxon_id
end
