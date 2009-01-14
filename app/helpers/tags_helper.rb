module TagsHelper

  # returns a hash in the format { 'tag_key' => ['value1','value2'] }
  def tag_hash tags
    tags.inject({}) do |all,this|
      all[this.key] = (all[this.key] || []) + [this.value]
      all
    end
  end

  # returns an array of all of the keys an object is tagged with
  def tag_keys tags
    tags.map {|t| t.key }.uniq
  end

  def tag_values_for_key key, tags
    tag_hash(tags)[key].sort
  end

  def tag_categories
    ( DataObjectTag.public_keys + current_user.tag_keys + (session[:user_added_data_object_tag_keys] || []) ).uniq.sort
  end

end
