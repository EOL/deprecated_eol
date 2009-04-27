# If you aren't sure what a comment is, perhaps you should re-think your career using Rails.  :)
# 
# Comments are polymorphically related to either a TaxonConcept or a DataObject.
#
# Comments can be hidden (by curators).
#
# Note that we presently have no way to edit comments, and won't add this feature until it becomes important.
class Comment < ActiveRecord::Base

  belongs_to :user
  belongs_to :parent, :polymorphic => true

  # I *do not* have any idea why Time.now wasn't working (I assume it was a time-zone thing), but this works:
  named_scope :visible, lambda { { :conditions => ['visible_at <= ?', 0.seconds.from_now] } }

  before_create :set_visible_at, :set_from_curator
  
  after_create :curator_activity_flag
  after_update :curator_activity_flag
  
  validates_presence_of :body

  attr_accessor :vetted_by

  # Comments can be hidden.  This method checks to see if a non-curator can see it:
  def visible?
    return false if visible_at.nil?
    return visible_at <= Time.now
  end

  # the description or name of the parent item (i.e. the name of the species or description of the object)
  def parent_name
    return_name=self.parent_type
    case self.parent_type
     when 'TaxonConcept' then 
        tc=TaxonConcept.find_by_id(self.parent_id)
        return_name=tc.name unless tc.blank?
     when 'DataObject' then
        d=DataObject.find_by_id(self.parent_id)
        return_name=d.description unless d.blank?
    end
    return return_name
  end

  # the image url being commented on, if it's an image
  def parent_image_url
    return_url=''
    case self.parent_type
     when 'DataObject' then
        d=DataObject.find_by_id(self.parent_id)
        return_url=d.smart_thumb if d.image?
    end
    return return_url    
  end

  # the url of the parent object (taxon concept or data object)
  def parent_url
    return_url=''
    case self.parent_type
     when 'TaxonConcept' then 
        return_url="/pages/#{self.parent_id}"
     when 'DataObject' then
        return_url="/data_objects/#{self.parent_id}"
    end
    return return_url    
  end
  
  # a friendly version of the parent name (e.g. "Image", "Taxon Concept", etc.)
  def parent_type_name
    return_name=''
    case self.parent_type
     when 'TaxonConcept' then 
        return_name='Taxon concept'
     when 'DataObject' then
        d=DataObject.find_by_id(self.parent_id)
        return_name=d.data_type.label unless d.blank?
    end
    return return_name
  end
  
  # Test if the parent object (DataObject or TaxonConcept) can be curated by a user:
  def is_curatable_by? user
    user.can_curate? parent
  end

  # TODO - this method should not have a bang.  (See Matz' rant)
  def show! user = nil
    self.vetted_by = user if user
    self.update_attribute :visible_at, Time.now unless visible_at
  end

  # TODO - this method should not have a bang.  (See Matz' rant)
  def hide! user = nil
    self.vetted_by = user if user
    self.update_attribute :visible_at, nil
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
    if parent.is_curatable_by?(user)
      if self.parent_type == "DataObject"
        taxon_concept_id = parent.taxon_concepts[0].id
      elsif self.parent_type == "TaxonConcept"
        taxon_concept_id = parent.id
      end
        LastCuratedDate.create(:user_id => user.id, 
        :taxon_concept_id => taxon_concept_id, 
        :last_curated => Time.now)
    end    
  end

protected

  # Run when a comment is created, to ensure it is visible by default:
  def set_visible_at
    self.visible_at ||= Time.now
  end

  def set_from_curator
    self.from_curator = parent.is_curatable_by?(user) if self.from_curator.nil?
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

