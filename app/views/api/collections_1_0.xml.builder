xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response do

  xml.name @json_response['name']
  xml.description @json_response['description']
  xml.logo_url @json_response['logo_url']
  xml.created @json_response['created']
  xml.modified @json_response['modified']
  xml.total_items @json_response['total_items']

  xml.item_types do
    @json_response['item_types'].each do |item_type|
      xml.item_type do
        xml.label item_type['item_type']
        xml.item_count item_type['item_count']
      end
    end
  end

  xml.collection_items do
    @json_response['collection_items'].each do |item|
      xml.item do
        xml.name item['name']
        xml.object_id item['object_id']
        xml.title item['title']
        xml.created item['created']
        xml.updated item['updated']
        xml.annotation item['annotation']
        xml.sort_field item['sort_field']

        if item['references']
          xml.references do
            item['references'].each do |ref|
              xml.reference ref['reference']
            end
          end
        end

        # fields specific to TaxonConcept
        xml.richness_score item['richness_score'] if item['richness_score']
        xml.taxonRank item['taxonRank'] if item['taxonRank']

        # fields specific to DataObject
        xml.data_rating item['data_rating'] if item['data_rating']
        xml.object_guid item['object_guid'] if item['object_guid']
        xml.source item['source'] if item['source']

        xml.object_type item['object_type']
      end
    end
  end
end
