class TocItem < ActiveRecord::Base

  self.table_name = 'table_of_contents'
  
  uses_translations(foreign_key: 'table_of_contents_id')
  acts_as_tree order: 'view_order'

  has_many :info_items, foreign_key: :toc_id

  has_and_belongs_to_many :data_objects, join_table: 'data_objects_table_of_contents', foreign_key: 'toc_id'
  has_and_belongs_to_many :content_tables, join_table: 'content_table_items', foreign_key: 'toc_id'
  has_and_belongs_to_many :known_uris

  # TODO - Remove this. Instead, just validate uniqueness.
  @@reserved_toc_labels = ['Biodiversity Heritage Library', 'Content Partners', 'Names and Taxonomy', 'Related Names', 'Synonyms', 'Common Names', 'Page Statistics', 'Content Summary', 'Education', 'Barcode', 'Wikipedia', 'Biomedical Terms', 'Literature References', 'Nucleotide Sequences']

  # TODO - turn this into a field in the DB.
  FOR_URIS = [
    'Distribution',
    'Physical Description',
    'Ecology',
    'Life History and Behavior',
    'Evolution and Systematics',
    'Physiology and Cell Biology',
    'Molecular Biology and Genetics',
    'Conservation',
    'Relevance to Humans and Ecosystems',
    'Notes',
    'Names and Taxonomy',
    'Database and Repository Coverage'
  ]

  class << self 

    # TODO - sure, we can code this with english labels, but it should STORE ids.
    def exclude_editable
      ['Barcode', 'Wikipedia', 'Education', 'Nucleotide Sequences', 'Database and Repository Coverage']
    end

    def toc_object_counts
      cached('toc_object_counts') do
        TocItem.count_objects
      end
    end

    # This is downright evil. ...But at least we cache it.  :|
    # Counts the number of (visible) data objects for each toc item.
    def count_objects
      counts = []
      count_hash = TocItem.connection.select_rows("select toc.id, count(*) from table_of_contents toc
        join data_objects_table_of_contents dotoc on (toc.id=dotoc.toc_id)
        join data_objects do on (dotoc.data_object_id=do.id)
        join data_objects_hierarchy_entries dohe on do.id = dohe.data_object_id
        where do.published=1 and dohe.visibility_id=#{$visible_global.id} group by toc.id")
      count_hash.each do |id, count|
        counts[id.to_i] = count.to_i
      end
      return counts
    end

    # because TocItems are cached with info_items already loaded, we need to have the InfoItem class loaded
    # before these #cached_find_translated calls.
    def find_by_en_label(label)
      InfoItem
      cached_find_translated(:label, label, include: [ :info_items, { parent: :info_items } ])
    end

    # TODO - maybe these should be generalized, hey?
    def bhl
      InfoItem
      cached_find_translated(:label, 'Biodiversity Heritage Library', include: [ :info_items, { parent: :info_items } ])
    end
    def content_partners
      InfoItem
      @@content_partners ||= cached_find_translated(:label, 'Content Partners', include: [ :info_items, { parent: :info_items } ])
    end
    def name_and_taxonomy
      InfoItem
      @@name_and_taxonomy ||= cached_find_translated(:label, 'Names and Taxonomy', include: [ :info_items, { parent: :info_items } ])
    end
    def related_names
      InfoItem
      @@related_names ||= cached_find_translated(:label, 'Related Names', include: [ :info_items, { parent: :info_items } ])
    end
    def page_statistics
      InfoItem
      cached_find_translated(:label, 'Page Statistics', include: [ :info_items, { parent: :info_items } ])
    end
    def content_summary
      InfoItem
      cached_find_translated(:label, 'Content Summary', include: [ :info_items, { parent: :info_items } ])
    end
    def overview
      InfoItem
      cached_find_translated(:label, 'Overview', include: [ :info_items, { parent: :info_items } ])
    end
    def education_resources
      InfoItem
      cached_find_translated(:label, 'Education Resources', include: [ :info_items, { parent: :info_items } ])
    end
    def identification_resources
      InfoItem
      @@identification_resources ||= cached_find_translated(:label, 'Identification Resources', include: [ :info_items, { parent: :info_items } ])
    end
    def biomedical_terms
      InfoItem
      cached_find_translated(:label, 'Biomedical Terms', include: [ :info_items, { parent: :info_items } ])
    end
    def literature_references
      InfoItem
      cached_find_translated(:label, 'Literature References', include: [ :info_items, { parent: :info_items } ])
    end
    def nucleotide_sequences
      InfoItem
      cached_find_translated(:label, 'Nucleotide Sequences', include: [ :info_items, { parent: :info_items } ])
    end
    def citizen_science
      InfoItem
      @@citizen_science ||= cached_find_translated(:label, 'Citizen Science', include: [ :info_items, { parent: :info_items } ])
    end
    def citizen_science_links
      InfoItem
      @@citizen_science_links ||= cached_find_translated(:label, 'Citizen Science links', include: [ :info_items, { parent: :info_items } ])
    end
    def wikipedia
      InfoItem
      cached_find_translated(:label, 'Wikipedia', include: [ :info_items, { parent: :info_items } ])
    end
    def brief_summary
      InfoItem
      cached_find_translated(:label, 'Brief Summary', include: [ :info_items, { parent: :info_items } ])
    end
    def comprehensive_description
      InfoItem
      cached_find_translated(:label, 'Comprehensive Description', include: [ :info_items, { parent: :info_items } ])
    end
    def distribution
      InfoItem
      cached_find_translated(:label, 'Distribution', include: [ :info_items, { parent: :info_items } ])
    end

    def synonyms
      InfoItem
      cached('synonyms') do
        r = TocItem.find_all_by_parent_id(self.name_and_taxonomy.id, include: [ :info_items, { parent: :info_items } ]).select{ |t| t.label('en') == 'Synonyms' }
        r.blank? ? nil : r[0]
      end
    end
    def common_names
      InfoItem
      cached('common_names') do
        r = TocItem.find_all_by_parent_id(self.name_and_taxonomy.id, include: [ :info_items, { parent: :info_items } ]).select{ |t| t.label('en') == 'Common Names' }
        r.blank? ? nil : r[0]
      end
    end

    def possible_overview_ids
      [TocItem.brief_summary, TocItem.comprehensive_description, TocItem.distribution].map(&:id)
    end

    # There are multiple education chapters - one is the parent of the others (but we don't care which is which, here)
    def education_chapters
      cached_find_translated(:label, 'Education', 'en', find_all: true)
    end

    def education_for_resources_tab
      # NOTE - education_chapters is an array; education_resources is an item.
      TocItem.education_chapters << TocItem.education_resources
    end

    # TODO - really, this list should be in a config of some kind.
    def exclude_from_details
      @@exclude_from_details ||= cached('exclude_from_details') do
        temp = []
        # Education:
        temp = temp | ["Education", "Education Resources", "High School Lab Series"] # to Resource tab
        # Physical Description:
        temp = temp | ["Identification Resources"] # to Resource tab
        # References and More Information:
        temp = temp | ["Search the Web"] # to be removed
        temp = temp | ["Literature References", "Biodiversity Heritage Library", "Bibliographies", "Bibliography"] # to Literature Tab
        temp = temp | ["Biomedical Terms", "On the Web"] # to Resources tab
        # Names and Taxonomy: ---> Names Tab
        temp = temp | ["Related Names", "Synonyms", "Common Names"]
        # Page Statistics:
        temp = temp | ["Content Summary"] # to Updates tab
        # Resources:
        temp = temp | ["Content Partners"] # to Resource tab
        # Citizen Science - to Resource tab
        temp = temp | ["Citizen Science"]
        temp = temp | ["Citizen Science links"]
        temp.collect{ |label| TocItem.cached_find_translated(:label, label, 'en', find_all: true) }.flatten.compact
      end
    end

    def last_major_chapter
      TocItem.where(parent_id: 0).order('view_order desc').first
    end

    def swap_entries(toc1, toc2)
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

    def selectable_toc
      InfoItem
      cached("selectable_toc/#{I18n.locale}") {
        TocItem.find(:all, include: :info_items).select {|toc|
          toc.allow_user_text?
        }.sort_by { |toc| toc.label.to_s }
      }
    end

    def roots
      TocItem.where(parent_id: 0).order('view_order').includes(:info_items)
    end

    def whole_tree
      TocItem.all(order: 'view_order', include: :info_items)
    end

    # TODO -we should NOT assume English, here.
    # TODO - remove this (and the functionality from the admin console). I
    # just proved (writing specs) that it had been broken, and NO ONE HAS
    # NOTICED. Clearly we don't need it.  ...and it's sloppy.
    def add_major_chapter(new_label)
      return if new_label.blank?
      max_view_order = TocItem.connection.select_values("SELECT max(view_order) FROM table_of_contents")[0].to_i
      next_view_order = max_view_order + 1
      new_toc_item = TocItem.create(parent_id: 0, view_order: next_view_order)
      TranslatedTocItem.create(table_of_contents_id: new_toc_item.id, language_id: Language.english.id, label: new_label)
    end

    def toc_for_data_objects(text_objects)
      DataObject.preload_associations(text_objects, { toc_items: :parent })
      toc = []
      text_objects.each do |obj|
        next unless obj.toc_items
        obj.toc_items.each do |toc_item|
          toc << toc_item
          if p = toc_item.parent
            toc << p
          end
        end
      end
      toc.uniq.sort_by(&:view_order)
    end

    def for_uris(lang)
      lang = lang.iso_code if lang.respond_to?(:iso_code)
      @@for_uris ||= {}
      @@for_uris[lang] ||= FOR_URIS.map do
        |label| TocItem.cached_find_translated(:label, label, lang)
      end.flatten.compact
    end

    # TODO - #distinct instead of #uniq, when we're Rails 4.
    def used_by_known_uris
      TocItem.joins(:known_uris).order(:view_order).uniq
    end

  end
    
  def object_count
    counts = TocItem.toc_object_counts
    return counts[id] || 0
  end

  def label_as_method_name
    label.gsub(/\W/, '_').downcase
  end

  def is_child?
    !(self.parent_id.nil? || self.parent_id == 0)
  end

  def allow_user_text?
    self.info_items.length > 0 && ! TocItem.exclude_editable.include?(self.label('en'))
  end

  def wikipedia?
    self.label('en') == "Wikipedia"
  end

  def children
    TocItem.find_all_by_parent_id(self.id, order: 'view_order', include: :info_items)
  end

  def add_child(new_label)
    return if new_label.blank?
    return unless is_major?
    max_view_order = TocItem.connection.select_values("SELECT max(view_order) FROM table_of_contents WHERE id=#{id} OR parent_id=#{id}")[0].to_i
    next_view_order = max_view_order + 1
    TocItem.connection.execute("UPDATE table_of_contents SET view_order=view_order+1 WHERE view_order >= #{next_view_order}")
    TocItem.create(parent_id: id, view_order: next_view_order)
    new_toc_item_id = TocItem.connection.select_values("SELECT max(id) FROM table_of_contents")[0].to_i
    TranslatedTocItem.create(table_of_contents_id: new_toc_item_id, language_id: Language.english.id, label: new_label)
  end

  # I suppose we just need a move_up method and move_down could fire off a move_up to its next chapter
  # but having two methods will save a few queries. Also need to figure about about moving all the way down
  def move_down(all_the_way = false)
    if is_major?
      if all_the_way
        move_to_last
      elsif chapter_after = next_of_type
        TocItem.swap_entries(self, chapter_after)
      end
    else  # sub chapter
      if all_the_way
        move_to_last
      elsif next_toc = next_of_type
        if next_toc.is_sub?
          TocItem.swap_entries(self, next_toc)
        end
      end
    end
  end

  def move_up(all_the_way = false)
    if is_major?
      if all_the_way
        move_to_first
      elsif chapter_before = previous_of_type
        TocItem.swap_entries(chapter_before, self)
      end
    else  # sub chapter
      if all_the_way
        move_to_first
      elsif previous_toc = previous_of_type
        if previous_toc.is_sub?
          TocItem.swap_entries(previous_toc, self)
        end
      end
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
    TocItem.find_all_by_parent_id(parent_id, order: 'view_order desc')[0]
  end

  def first_of_type
    TocItem.find_all_by_parent_id(parent_id, order: 'view_order asc')[0]
  end

  def citizen_science
    TocItem.cached_find_translated(:label, 'Citizen Science', 'en')
  end

  def citizen_science_links
    TocItem.cached_find_translated(:label, 'Citizen Science links', 'en')
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
  alias :is_parent? :is_major?

  def is_sub?
    return parent_id != 0
  end

  def is_reserved?
    return @@reserved_toc_labels.include? label
  end

end
