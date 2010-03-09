module ModelQueryHelper
  def self.group_array_by_key(array, key)
    new_hash = {}
    array.each do |e|
      # element with index `key` is converted to INT and becomes the hash key
      id = e[key].to_i
      # array elements are grouped by the `key`
      new_hash[id] ||= []
      new_hash[id] << e
    end
    return new_hash
  end
  
  # given an array of ActiveRecord models, loop through the objects and add a hash key of `key` if there exists
  # a corresponding entry in `hash` for the object
  def self.add_hash_to_object_array_as_key(object_array, hash, key)
    object_array.each do |obj|
      if arr = hash[obj.id.to_i]
        obj[key] = arr
      end
    end
    return object_array
  end
  
  # same as the obove, but expecting id to be hash element, not object attribute
  def self.add_hash_to_hash_as_key(details_hash, hash, key)
    details_hash.each do |obj|
      if arr = hash[obj['id'].to_i]
        obj[key] = arr
      else
        obj[key] = []
      end
    end
    return details_hash
  end
  
  
  
  def self.sort_objects_by_display_order(objects)
    objects.sort do |a, b|
      if a.vetted_view_order == b.vetted_view_order
        # TODO - this should probably also sort on visibility.
        if a.data_rating == b.data_rating
          b.id <=> a.id # essentially, orders images by date.
        else
          b.data_rating <=> a.data_rating # Note this is reversed; higher ratings are better.
        end
      else
        a.vetted_view_order <=> b.vetted_view_order
      end
    end
  end
  
  # # same as the obove method expecting a hash instead of an object
  # def self.sort_object_hash_by_display_order(hash)
  #   hash.sort do |a, b|
  #     if a['vetted_view_order'] == b['vetted_view_order']
  #       if a['data_rating'] == b['data_rating']
  #         b['id'] <=> a['id']
  #       else
  #         b['data_rating'] <=> a['data_rating']
  #       end
  #     else
  #       a['vetted_view_order'] <=> b['vetted_view_order']
  #     end
  #   end
  # end
  
  
  # custom sorting for a generic data object
  def self.sort_object_hash_by_display_order(hash)
    hash.sort do |a, b|
      if a['data_type_id'] != b['data_type_id']
        a['data_type_id'] <=> b['data_type_id']                 # data type ID ASC
      elsif a['toc_view_order'] != b['toc_view_order']
        a['toc_view_order'].to_i <=> b['toc_view_order'].to_i   # toc view_order ASC
      elsif a['vetted_view_order'] != b['vetted_view_order']
        a['vetted_view_order'] <=> b['vetted_view_order']       # vetted view_order ASC
      elsif a['data_rating'] != b['data_rating']
        b['data_rating'] <=> a['data_rating']                   # data rating DESC
      else
        b['id'] <=> a['id']                                     # ID DESC
      end
    end
  end
  
  
end
