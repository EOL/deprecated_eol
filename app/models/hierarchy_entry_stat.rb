class HierarchyEntryStat < ActiveRecord::Base
  belongs_to :hierarchy_entry
  
  def pecent_with_images
    if total_children == 0
      return 100 if image_trusted > 0 || image_untrusted > 0
    else
      children_with_images = have_images
      children_with_images -= 1 if image_trusted > 0 || image_untrusted > 0
      return (children_with_images.to_f / total_children.to_f * 100).round_to(1)
    end
    return 0
  end
  def pecent_with_text
    if total_children == 0
      return 100 if text_trusted > 0 || text_untrusted > 0
    else
      children_with_text = have_text
      children_with_text -= 1 if text_trusted > 0 || text_untrusted > 0
      return (children_with_text.to_f / total_children.to_f * 100).round_to(1)
    end
    return 0
  end
end
