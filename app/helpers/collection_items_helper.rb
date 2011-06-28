module CollectionItemsHelper

  def collection_item_name_link_to(item)
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

  def collection_item_view_type_link_to(item)
    case item.object_type
    when 'TaxonConcept'
      link_to I18n.t(:view_taxon_link), taxon_concept_path(item.object), :title => strip_tags(item.name)
    when 'DataObject'
      if item.object.image?
        link_to I18n.t(:view_image_link), data_object_path(item.object)
      elsif item.object.video?   
        link_to I18n.t(:view_video_link), data_object_path(item.object)
      elsif item.object.sound?   
        link_to I18n.t(:listen_audio_link), data_object_path(item.object)
      elsif item.object.text?
        link_to I18n.t(:read_article_link), data_object_path(item.object)
      end
      # TODO: Confirm - not in HR mockup: 
      # TODO: Confirm - not in HR mockup: link_to I18n.t(:view_details_link), data_object_path(item.object)
    when 'Community'
      link_to I18n.t(:view_community_link), community_path(item.object), :title => strip_tags(item.name)
    when 'User'
      link_to I18n.t(:view_user_profile_link, :given_name => item.object.short_name), user_path(item.object)
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
      object_data_type(item.object, 'word')
    when 'Community'
      # TODO: Not in HR mockup
      'community'
    when 'User'
      'person'
    when 'Collection'
      # TODO: Not in HR mockup collection.collection won't make sense ?
      'collection'
    else
    end
  end

  def collection_item_icon(item)
    case item.object_type
    when 'TaxonConcept'
      if thumb = item.object.smart_medium_thumb
        image_tag(thumb, :alt => '')
      else
        #TODO: put this in model
        image_tag '/images/v2/icon_taxa_tabs.png', :alt => ''
      end
    when 'DataObject'
      if (thumb = item.object.smart_thumb) && (item.object.image?)
        image_tag(thumb, :alt => "")
      else
        #TODO: put this in model
        image_tag '/images/v2/icon_' + object_data_type(item.object, 'icon') + '_tabs.png', :alt => ''
      end
    when 'Community'
      image_tag item.object.logo_url, :alt => ''
    when 'User'
      image_tag item.object.logo_url, :alt => ''
    when 'Collection'
      image_tag item.object.logo_url, :alt => ''
    else
      image_tag '/images/v2/icon_taxa_tabs.png', :alt => ''
    end
  end

  def collection_item_detail(item)
    case item.object_type
    when 'TaxonConcept'
      taxon_concept = TaxonConcept.find(item['object_id'])
      if common_name = taxon_concept.common_name
        common_name
      end
    when 'DataObject'
      en_type = item.object.data_type.label("en").downcase
      I18n.t("in_this_#{en_type}_") + " " + item.object.first_concept_name
    when 'Community'
      item.object.description
    when 'User'
      I18n.t(:expertise_) + " " + item.object.expertise
    when 'Collection'
    else
    end
  end

  def object_data_type(data_object, use)
    if use == 'icon'
      return "images"   if data_object.image?
      return "videos"   if data_object.video?
      return "sounds"   if data_object.sound?
      return "articles" if data_object.text?
    elsif use == 'word'
      return "image"   if data_object.image?
      return "video"   if data_object.video?
      return "audio"   if data_object.sound?
      return "article" if data_object.text?
    end
  end

end
