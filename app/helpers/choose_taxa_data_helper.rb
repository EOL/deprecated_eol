module ChooseTaxaDataHelper
  
 def get_uri_name(uri)
   KnownUri.find_by_uri(uri).name
 end
  
end