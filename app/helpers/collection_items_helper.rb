module CollectionItemsHelper

  def collection_item_link_to(item)
    case item.object_type
    when 'TaxonConcept'
      link_to I18n.t(:view_taxon_link), taxon_concept_path(item.object), :title => strip_tags(item.name)
    when 'DataObject'
      # TODO: Needs to change depending on object type
      link_to I18n.t(:view_image_link), data_object_path(item.object)
      # TODO: Confirm - not in HR mockup: link_to I18n.t(:view_video_link), data_object_path(item.object)
      # TODO: Confirm - not in HR mockup: link_to I18n.t(:view_details_link), data_object_path(item.object)
    when 'Community'
      link_to I18n.t(:view_community_link), community_path(item.object), :title => strip_tags(item.name)
    when 'User'
      #TODO is given name required? otherwise the link will say "View 's profile"
      link_to I18n.t(:view_user_profile_link, :given_name => item.user.given_name), user_infor_path(item.object)
    when 'Collection'
      link_to I18n.t(:view_collection_link), collection_path(item.object), :title => strip_tags(item.name)
    else
    end
  end

  def collection_item_get_type(item)
    case item.object_type
    when 'TaxonConcept'
      'taxon'
    when 'DataObject'
      # TODO: This needs to be image, video etc
    when 'Community'
      # TODO: Not in HR mockup
      'community'
    when 'User'
      'person'
    when 'Collection'
      # TODO: Not in HR mockup collection.collection won't make sense ?
    else
    end
  end

end
