# This represents a single entry in the TOC on a specific page. It's built from a TocItem (q.v.) and affected by
# other TocItems (basically, each text DataObject associated with the page gets a chance to change the attributes of
# the TocEntry that is displayed on the page)
class TocEntry

  attr_reader :category_id
  attr_reader :has_content
  attr_reader :has_unpublished_content
  attr_reader :has_published_content
  attr_reader :has_inappropriate_content
  attr_reader :has_invisible_content
  attr_reader :label
  attr_reader :parent_id
  attr_reader :view_order

  def initialize(toc_item, options = {})
    set_fixed_attributes_from(toc_item)
    merge_attribues_with(toc_item)
    @has_content = options[:has_content] || true
  end

  # If the TocItem passed in was built from a DataObject (using DataObject.for_taxon), it has some information about
  # what its content looks like, and we need to set those flags as necessary.  ...If not, nothing happens.
  def merge_attribues_with(toc_item)
    if toc_item.respond_to? :published
      @has_unpublished_content = true if toc_item.published.to_i == 0
    end
    @has_published_content = true if false # TODO ... to properly set this, we have to know about the logged-in
                                           # agent, which seems WAY beyond the scope of this class. The view that
                                           # uses this variable needs to know whether the agent exists, NOT this
                                           # class.
    if toc_item.respond_to? :visibility_id 
      @has_invisible_content     = true if toc_item.visibility_id.to_i == Visibility.invisible.id
      @has_inappropriate_content = true if toc_item.visibility_id.to_i == Visibility.inappropriate.id
    end
  end

  # Tells us if this entry is at the top level of the TOC
  def is_parent?
    @parent_id == 0
  end

  # Tells us if this entry is nested under another entry.
  def is_child?
    @parent_id > 0
  end

  # Tells us if this entry actually has content. Parent entries in particular can be displayed in the TOC, but not
  # have any actual content of their own.
  def has_content?
    @has_content
  end

  def allow_user_text?
    @allow_user_text
  end

  def set_fixed_attributes_from(toc_item)
    @category_id     = toc_item.id
    @label           = toc_item.label
    @allow_user_text = toc_item.allow_user_text?
    @parent_id       = toc_item.parent_id.to_i
    @view_order      = toc_item.view_order
  end

  # Equality is based on the label.  These are required for #uniq to work on array of TocEntry instances.
  def eql?(other)
    return label == other.label
  end
  def ==(other)
    return self.eql? other
  end
  def hash
    return {:label => label}.hash # slightly dangerous, since this object is now "equal" to this hash, but...
  end

  # Sorting is based on view_order:
  def <=>(other)
    return view_order <=> other.view_order
  end

end
