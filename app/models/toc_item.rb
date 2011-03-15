class TocItem < SpeciesSchemaModel
  set_table_name 'table_of_contents'
  CACHE_ALL_ROWS = true
  acts_as_tree :order => 'view_order'
  
  attr_writer :has_content
  
  has_many :info_items, :foreign_key => :toc_id
  
  has_and_belongs_to_many :data_objects, :join_table => 'data_objects_table_of_contents', :foreign_key => 'toc_id'
  
  @@reserved_toc_labels = ['Biodiversity Heritage Library', 'Content Partners', 'Names and Taxonomy', 'Related Names', 'Synonyms', 'Common Names', 'Page Statistics', 'Content Summary', 'Education', 'Barcode', 'Wikipedia', 'Search the Web', 'Biomedical Terms', 'Literature References', 'Nucleotide Sequences']
  
  def self.toc_object_counts
    cached('toc_object_counts') do
      TocItem.count_objects
    end
  end
  
  def self.count_objects
    counts = []
    count_hash = TocItem.connection.select_rows("select toc.id, count(*) from table_of_contents toc join data_objects_table_of_contents dotoc on (toc.id=dotoc.toc_id) join data_objects do on (dotoc.data_object_id=do.id) where do.published=1 and do.visibility_id=#{Visibility.visible.id} group by toc.id")
    count_hash.each do |id, count|
      counts[id.to_i] = count.to_i
    end
    return counts
  end
  
  def self.bhl
    # because TocItems are cached with info_items already loaded, we need to have the InfoItem class loaded
    # before this block. The only way I could see was to just reference the model here, which removed those errors
    InfoItem
    cached_find(:label, 'Biodiversity Heritage Library', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.content_partners
    InfoItem
    cached_find(:label, 'Content Partners', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.name_and_taxonomy
    InfoItem
    cached_find(:label, 'Names and Taxonomy', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.related_names
    InfoItem
    cached_find(:label, 'Related Names', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.synonyms
    InfoItem
    cached('synonyms') do
      r = TocItem.find_all_by_parent_id(self.name_and_taxonomy.id, :include => [ :info_items, { :parent => :info_items } ]).select{ |t| t.label == 'Synonyms' }
      r.blank? ? nil : r[0]
    end
  end
  def self.common_names
    InfoItem
    cached('common_names') do
      r = TocItem.find_all_by_parent_id(self.name_and_taxonomy.id, :include => [ :info_items, { :parent => :info_items } ]).select{ |t| t.label == 'Common Names' }
      r.blank? ? nil : r[0]
    end
  end
  def self.page_statistics
    InfoItem
    cached_find(:label, 'Page Statistics', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.content_summary
    InfoItem
    cached_find(:label, 'Content Summary', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.overview
    InfoItem
    cached_find(:label, 'Overview', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.education
    InfoItem
    cached_find(:label, 'Education', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.search_the_web
    InfoItem
    cached_find(:label, 'Search the Web', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.biomedical_terms
    InfoItem
    cached_find(:label, 'Biomedical Terms', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.literature_references
    InfoItem
    cached_find(:label, 'Literature References', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.nucleotide_sequences
    InfoItem
    cached_find(:label, 'Nucleotide Sequences', :include => [ :info_items, { :parent => :info_items } ])
  end
  def self.wikipedia
    InfoItem
    cached_find(:label, 'Wikipedia', :include => [ :info_items, { :parent => :info_items } ])
  end
  
  def object_count
    counts = TocItem.toc_object_counts
    return counts[id] || 0
  end
  
  def label_as_method_name
    label.gsub(/\W/, '_').downcase
  end

  
  def is_child?
    !(self.parent_id.nil? or self.parent_id == 0) 
  end

  def allow_user_text?
    self.info_items.length > 0 && !["Wikipedia", "Barcode"].include?(self.label)
  end
  
  def self.selectable_toc
    cached('selectable_toc') do
      InfoItem
      all = TocItem.find(:all, :include => :info_items).sort_by{ |toc| toc.label }
      all.delete_if{ |toc| toc.info_items.empty? || ['Wikipedia', 'Barcode'].include?(toc.label) }
      all.collect{ |c| [c.label, c.id] }
    end
  end

  def wikipedia?
    self.label == "Wikipedia" 
  end
  
  def self.roots
    TocItem.find_all_by_parent_id(0, :order => 'view_order', :include => :info_items)
  end
  
  def children
    TocItem.find_all_by_parent_id(self.id, :order => 'view_order', :include => :info_items)
  end
  
  def self.whole_tree
    TocItem.all(:order => 'view_order', :include => :info_items)
  end
  
  def add_child(new_label)
    return if new_label.blank?
    return unless is_major?
    max_view_order = TocItem.connection.select_values("SELECT max(view_order) FROM table_of_contents WHERE id=#{id} OR parent_id=#{id}")[0].to_i
    next_view_order = max_view_order + 1
    TocItem.connection.execute("UPDATE table_of_contents SET view_order=view_order+1 WHERE view_order >= #{next_view_order}")
    TocItem.create(:label => new_label, :parent_id => id, :view_order => next_view_order)
  end
  def self.add_major_chapter(new_label)
    return if new_label.blank?
    max_view_order = TocItem.connection.select_values("SELECT max(view_order) FROM table_of_contents")[0].to_i
    next_view_order = max_view_order + 1
    TocItem.create(:label => new_label, :parent_id => 0, :view_order => next_view_order)
  end
  
  # I suppose we just need a move_up method and move_down could fire off a move_up to its next chapter
  # but having two methods will save a few queries. Also need to figure about about moving all the way down
  def move_down(all_the_way = false)
    if is_major?
      if all_the_way
        move_to_last
      elsif chapter_after = next_of_type
        TocItem.swap_enries(self, chapter_after)
      end
    else  # sub chapter
      if all_the_way
        move_to_last
      elsif next_toc = next_of_type
        if next_toc.is_sub?
          TocItem.swap_enries(self, next_toc)
        end
      end
    end
  end
  
  def move_up(all_the_way = false)
    if is_major?
      if all_the_way
        move_to_first
      elsif chapter_before = previous_of_type
        TocItem.swap_enries(chapter_before, self)
      end
    else  # sub chapter
      if all_the_way
        move_to_first
      elsif previous_toc = previous_of_type
        if previous_toc.is_sub?
          TocItem.swap_enries(previous_toc, self)
        end
      end
    end
  end
  
  def self.swap_enries(toc1, toc2)
    return unless toc1.class==TocItem && toc2.class==TocItem
    return if toc1.is_major? != toc2.is_major?
    
    if toc1.is_sub?
      swap_view_order = toc1.view_order
      toc1.view_order = toc2.view_order
      toc2.view_order = swap_view_order
      toc1.save
      toc2.save
    else
      # make sure toc1 is higher in the list
      if toc1.view_order > toc2.view_order
        toc1, toc2 = toc2, toc1 
      end
      to_subtract = toc1.chapter_length
      TocItem.connection.execute("UPDATE table_of_contents SET view_order=view_order+#{toc2.chapter_length} WHERE id=#{toc1.id} OR parent_id=#{toc1.id}")
      TocItem.connection.execute("UPDATE table_of_contents SET view_order=view_order-#{to_subtract} WHERE id=#{toc2.id} OR parent_id=#{toc2.id}")
    end
  end
  
  def move_to_first
    first_toc = first_of_type
    if first_toc.id != id
      if is_major?
        TocItem.connection.execute("UPDATE table_of_contents SET view_order=view_order+#{chapter_length} WHERE id!=#{id} AND parent_id!=#{id} AND view_order<=#{view_order}")
        TocItem.connection.execute("UPDATE table_of_contents SET view_order=view_order-#{view_order-first_toc.view_order} WHERE id=#{id} OR parent_id=#{id}")
      else
        TocItem.connection.execute("UPDATE table_of_contents SET view_order=view_order+1 WHERE id!=#{id} AND parent_id=#{parent_id} AND view_order<#{view_order}")
        self.view_order = first_toc.view_order
        self.save
      end
    end
  end
  def move_to_last
    last_toc = last_of_type
    if last_toc.id != id
      if is_major?
        TocItem.connection.execute("UPDATE table_of_contents SET view_order=view_order-#{chapter_length} WHERE id!=#{id} AND parent_id!=#{id} AND view_order>=#{view_order}")
        TocItem.connection.execute("UPDATE table_of_contents SET view_order=view_order+#{last_toc.view_order-view_order} WHERE id=#{id} OR parent_id=#{id}")
      else
        TocItem.connection.execute("UPDATE table_of_contents SET view_order=view_order-1 WHERE id!=#{id} AND parent_id=#{parent_id} AND view_order>#{view_order}")
        self.view_order = last_toc.view_order
        self.save
      end
    end
  end
  
  def previous_of_type
    result = TocItem.find_by_sql("SELECT * FROM table_of_contents WHERE view_order<#{view_order} AND parent_id=#{parent_id} ORDER BY view_order DESC")
    return nil if result.blank?
    result[0]
  end
  
  def next_of_type
    result = TocItem.find_by_sql("SELECT * FROM table_of_contents WHERE view_order>#{view_order} AND parent_id=#{parent_id} ORDER BY view_order ASC")
    return nil if result.blank?
    result[0]
  end
  
  def last_of_type
    TocItem.find_all_by_parent_id(parent_id, :order => 'view_order desc')[0]
  end
  
  def first_of_type
    TocItem.find_all_by_parent_id(parent_id, :order => 'view_order asc')[0]
  end
  
  def chapter_length
    return nil if parent_id != 0
    if next_chapter = next_of_type
      return next_chapter.view_order - view_order
    end
    return TocItem.count_by_sql("SELECT COUNT(*) FROM table_of_contents WHERE id=#{id} OR parent_id=#{id}")
  end
  
  def is_major?
    return parent_id == 0
  end
  
  def is_sub?
    return parent_id != 0
  end
  
  def self.last_major_chapter
    TocItem.find_all_by_parent_id(0, :order => 'view_order desc')[0]
  end
  
  def is_reserved?
    return @@reserved_toc_labels.include? label
  end
  
end
