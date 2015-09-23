known_uris =
  [ 'http://rs.tdwg.org/dwc/terms/measurementDeterminedDate',
  'http://eol.org/schema/terms/BloomPeriod',
  'http://eol.org/schema/terms/BloomPeriodBegin',
  'http://eol.org/schema/terms/BloomPeriodEnd',
  'http://rs.tdwg.org/dwc/terms/catalogNumber',
  'http://rs.tdwg.org/dwc/terms/collectionCode',
  'http://rs.tdwg.org/dwc/terms/dateIdentified',
  'http://purl.org/dc/terms/modified',
  'http://rs.tdwg.org/dwc/terms/institutionCode',
  'http://eol.org/schema/terms/SeedPeriodBegin',
  'http://eol.org/schema/terms/SeedPeriodEnd',
  'http://eol.org/schema/terms/SeedRipeningDate',
  'http://rs.tdwg.org/dwc/terms/verbatimLatitude',
  'http://rs.tdwg.org/dwc/terms/verbatimLongitude',
  'http://eol.org/schema/terms/EggLayingBegins' ]

namespace :known_uris do
  desc 'sets the value of selected known_uris to verbatim value'
  task :verbatim_value => :environment do
    known_uris.each do |u|
      uri= KnownUri.find_by_uri(u)
      uri.update_attribute(value_is_verbatim: 1) if uri 
    end
  end
end
