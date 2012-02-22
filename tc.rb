class TaxonConcept << ActiveRecord::Base

  attr...

  validations

end

class TcPage

  have_one taxon_concept

  # interfaces to solr for getting more data...

end

