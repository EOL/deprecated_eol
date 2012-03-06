class GoogleAnalyticsPartnerTaxon < ActiveRecord::Base
    belongs_to :user
    belongs_to :taxon_concept
end