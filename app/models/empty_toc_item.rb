class EmptyTocItem
  def id
    "other"
  end

  def label
    I18n.t(:other_category_subtab)
  end

  def view_order
    64_000 # Just ... very high. ;)
  end
end
