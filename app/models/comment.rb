# If you aren't sure what a comment is, perhaps you should re-think your career using Rails.  :)
# 
# Comments are polymorphically related to either a TaxonConcept or a DataObject.
#
# Comments can be hidden (by curators).
#
# Note that we presently have no way to edit comments, and won't add this feature until it becomes important.
class Comment < ActiveRecord::Base
  
  include UserActions

  belongs_to :user
  belongs_to :parent, :polymorphic => true
  
  # I *do not* have any idea why Time.now wasn't working (I assume it was a time-zone thing), but this works:
  named_scope :visible, lambda { { :conditions => ['visible_at <= ?', 0.seconds.from_now] } }

  before_create :set_visible_at, :set_from_curator
  
  after_create  :curator_activity_flag, :new_actions_histories_create_comment
    
  validates_presence_of :body, :user

  attr_accessor :vetted_by

  def self.feed_comments(taxon_concept_id = nil, max_results = 100)
    min_date = 30.days.ago.strftime('%Y-%m-%d')
    result = []
    if taxon_concept_id.nil?
      result = Set.new(Comment.find_by_sql("select * from #{Comment.full_table_name} WHERE created_at > '#{min_date}'")).to_a
    else
      query_string = %Q{
        ( SELECT c.*
          FROM #{HierarchyEntry.full_table_name} he_parent
            JOIN #{HierarchyEntry.full_table_name} he_children
              ON (he_children.lft BETWEEN he_parent.lft AND he_parent.rgt
                  AND he_parent.hierarchy_id=he_children.hierarchy_id)
            JOIN #{Taxon.full_table_name} t ON (he_children.id=t.hierarchy_entry_id)
            JOIN #{DataObjectsTaxon.full_table_name} dot ON (t.id=dot.taxon_id)
            JOIN #{DataObject.full_table_name} do ON (dot.data_object_id=do.id)
            JOIN #{DataObject.full_table_name} do1 ON (do.guid=do1.guid)
            JOIN #{Comment.full_table_name} c ON(c.parent_id=do.id)
          WHERE he_parent.taxon_concept_id=#{taxon_concept_id}
          AND do1.published=1
          AND c.parent_type='DataObject'
          AND c.created_at > '#{min_date}'
        ) UNION (
          SELECT c.*
          FROM #{HierarchyEntry.full_table_name} he_parent
            JOIN #{HierarchyEntry.full_table_name} he_children
              ON (he_children.lft BETWEEN he_parent.lft AND he_parent.rgt
                  AND he_parent.hierarchy_id=he_children.hierarchy_id)
            JOIN #{Comment.full_table_name} c
              ON(c.parent_id=he_children.taxon_concept_id AND c.parent_type='TaxonConcept')
          WHERE he_parent.taxon_concept_id=#{taxon_concept_id}
          AND c.created_at > '#{min_date}'
        )
      }
      
      result = Set.new(Comment.find_by_sql(query_string)).to_a
    end
    return result.sort_by(&:created_at).reverse[0..max_results]
    
  end

  # Comments can be hidden.  This method checks to see if a non-curator can see it:
  def visible?
    return false if visible_at.nil?
    return visible_at <= Time.now
  end

  # the description or name of the parent item (i.e. the name of the species or description of the object)
  def parent_name
    return_name = case self.parent_type
     when 'TaxonConcept' then TaxonConcept.find_by_id(self.parent_id).name
     when 'DataObject'   then DataObject.find_by_id(self.parent_id).description
     else ''
    end
    return_name = self.parent_type if return_name.blank?
    return return_name
  end

  def taxa_comment?
    return parent_type == 'TaxonConcept'
  end

  def image_comment?
    return(parent_type == 'DataObject' and parent.data_type.label == 'Image')
  end

  def text_comment?
    return(parent_type == 'DataObject' and parent.data_type.label == 'Text')
  end

  # the image url being commented on, if it's an image
  def parent_image_url
    return_url = case self.parent_type
     when 'DataObject' then
        d=DataObject.find_by_id(self.parent_id)
        d.image? ? d.smart_thumb : ''
     else ''
    end
    return return_url    
  end

  # the url of the parent object (taxon concept or data object)
  def parent_url
    return_url = case self.parent_type
     when 'TaxonConcept' then "/pages/#{self.parent_id}"
     when 'DataObject'   then "/data_objects/#{self.parent_id}"
     else ''
    end
    return return_url    
  end
  
  # A friendly version of the parent name (e.g. "Image", "Taxon Concept", etc.)
  #
  # DO *NOT* COMPARE THIS STRING. It is subject to change.  Use the image_comment?, taxa_comment?, and text_comment?
  # methods instead.
  def parent_type_name
    return_name = case self.parent_type
     when 'TaxonConcept' then 
        'page'
     when 'DataObject' then
        d=DataObject.find_by_id(self.parent_id)
        d.nil? ? '' : d.data_type.label.downcase
     else ''
    end
    return return_name
  end
  
  # Test if the parent object (DataObject or TaxonConcept) can be curated by a user:
  def is_curatable_by? by
    parent.is_curatable_by?(by)
  end

  # TODO - this method should not have a bang.  (See Matz' rant)
  def show! by
    self.vetted_by = by if by
    self.update_attribute :visible_at, Time.now unless visible_at

    new_actions_histories(by, self, 'comment', 'show')
  end

  # TODO - this method should not have a bang.  (See Matz' rant)
  def hide! by
    self.vetted_by = by if by
    self.update_attribute :visible_at, nil
    
    new_actions_histories(by, self, 'comment', 'hide')    
  end

  # aliases to satisfy curation
  alias vetted? visible?
  alias vet!    show!
  alias unvet!  hide!

  # Pagination uses this method to check for a default pagination size:
  def self.per_page
    10
  end
  
  def curator_activity_flag
    if is_curatable_by?(user)
        LastCuratedDate.create(:user_id => user.id, 
        :taxon_concept_id => taxon_concept_id, 
        :last_curated => Time.now)
    end    
  end
  
  def taxon_concept_id
    return_t_c = case self.parent_type
     when 'TaxonConcept' then parent.id
     when 'DataObject'   then parent.taxon_concepts[0].id
     else nil
    end
    raise "Don't know how to handle a parent type of #{self.parent_type} (or t_c was nil)" if return_t_c.nil?
    return return_t_c
  end


 def self.get_comments(comment_ids,page)
    if(comment_ids.length > 0) then
    query="Select comments.* From comments
    WHERE comments.id IN  (#{ comment_ids.join(', ') }) "
    self.paginate_by_sql [query, comment_ids], :page => page, :per_page => 20
    end
  end 
 
    
protected

  def new_actions_histories_create_comment
    new_actions_histories(self.user, self, 'comment', 'create')
  end
  
  # Run when a comment is created, to ensure it is visible by default:
  def set_visible_at
    self.visible_at ||= Time.now
  end

  def set_from_curator
    self.from_curator = is_curatable_by?(user) if self.from_curator.nil?
    return self.from_curator.to_s
  end

end

# == Schema Info
# Schema version: 20081002192244
#
# Table name: comments
#
#  id          :integer(4)      not null, primary key
#  parent_id   :integer(4)      not null
#  user_id     :integer(4)
#  body        :text            not null
#  parent_type :string(255)     not null
#  created_at  :datetime
#  updated_at  :datetime
#  visible_at  :datetime
# == Schema Info
# Schema version: 20081020144900
#
# Table name: comments
#
#  id          :integer(4)      not null, primary key
#  parent_id   :integer(4)      not null
#  user_id     :integer(4)
#  body        :text            not null
#  parent_type :string(255)     not null
#  created_at  :datetime
#  updated_at  :datetime
#  visible_at  :datetime

