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
end
