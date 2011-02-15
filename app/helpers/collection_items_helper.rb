module CollectionItemsHelper

  def collection_item_link_to(item)
    case item.object_type
    when 'TaxonConcept'
      link_to item.name, taxon_concept_path(item.object)
    when 'DataObject'
      link_to item.name, data_object_path(item.object)
    when 'Community'
      link_to item.name, community_path(item.object)
    when 'User'
      link_to item.name, user_infor_path(item.object)
    when 'Collection'
      link_to item.name, collection_path(item.object)
    else
    end
  end

end
