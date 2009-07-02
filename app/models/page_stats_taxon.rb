# This table provides access to some cached species page stastics generated nightly by an automated script that runs the appropriate queries
class PageStatsTaxon < SpeciesSchemaModel
    
    def self.latest
      stats=self.find(:all,:limit=>1,:order=>'timestamp desc')
      return stats[0] unless stats.blank? 
    end
    
end