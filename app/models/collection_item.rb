# NOTE - you can get a list of all the possible collection item types with this command:
# git grep "has_many :collection_items, :as" app
# ...Also note, that to be "collectable", you must implement #summary_name and #collected_name.
class CollectionItem < ActiveRecord::Base

  include Refable

  belongs_to :collection, touch: true
  belongs_to :collected_item, polymorphic: true
  belongs_to :added_by_user, class_name: User.to_s, foreign_key: :added_by_user_id
  has_and_belongs_to_many :refs

  scope :collections, conditions: { collected_item_type: 'Collection' }
  scope :communities, conditions: { collected_item_type: 'Community' }
  scope :data_objects, conditions: { collected_item_type: 'DataObject' }
  scope :taxa, conditions: { collected_item_type: 'TaxonConcept' }
  scope :users, conditions: { collected_item_type: 'User' }
  scope :annotated, conditions: 'annotation IS NOT NULL AND annotation != ""'

  attr_accessible :annotation, :collected_item_id, :collected_item_type,
    :sort_field, :collected_item, :name, :collection, :added_by_user,
    :added_by_user_id

  # Note that it doesn't validate the presence of collection.  A "removed" collection item still exists, so we have a
  # record of what it used to point to (see CollectionsController#destroy). (Hey, the alternative is to have a bunch
  # of unused fields in collection_activity_logs, so it's actually better to have these "zombie" rows here!)
  validates_presence_of :collected_item_id, :collected_item_type
  validates_uniqueness_of :collected_item_id, scope: [:collection_id, :collected_item_type],
    message: I18n.t(:item_not_added_already_in_collection), if: Proc.new { |ci| ci.collection_id }

  # Note we DO NOT update relevance on the collection on save or delete, since we sometimes add/delete 1000 items at
  # a time, and that would be a disaster, since the collection only need be recalculated once.
  after_save     :reindex_collection_item_in_solr
  after_update   :update_collection_relevance_if_annotation_switched
  before_destroy :remove_collection_item_from_solr

  # Keeps an accurate count of items:
  counter_culture :collection

  # Information about how collection items interface with solr and views and the like...
  def self.types
    @types ||= { taxa:        { facet: 'TaxonConcept', i18n_key: "taxa" },
                 text:        { facet: 'Text',         i18n_key: "articles" },
                 images:      { facet: 'Image',        i18n_key: "images" },
                 sounds:      { facet: 'Sound',        i18n_key: "sounds" },
                 videos:      { facet: 'Video',        i18n_key: "videos" },
                 communities: { facet: 'Community',    i18n_key: "communities" },
                 people:      { facet: 'User',         i18n_key: "people" },
                 collections: { facet: 'Collection',   i18n_key: "collections" },
                 links:       { facet: 'Link',         i18n_key: "links" } }
  end

  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.can_edit_collection?(collection)
  end

  # Using has_one :through didn't work:
  def community
    return nil unless collection
    return nil unless collection.community
    return collection.community
  end

  def reindex_collection_item_in_solr
    EOL::Solr::CollectionItemsCoreRebuilder.reindex_collection_items([self])
  end

  def remove_collection_item_from_solr
    EOL::Solr::CollectionItemsCoreRebuilder.remove_collection_items([self])
  end

  def update_collection_relevance
    collection.set_relevance if collection
  end

  # Because doing so is expensive, we check to make sure there's a need (which would only be if annotation was added
  # or removed)
  def update_collection_relevance_if_annotation_switched
    if changed?
      if changes.has_key?('annotation')
        (before, after) = changes['annotation']
        before.gsub(/\s+$/, '') if before
        after.gsub(/\s+$/, '') if after
        if (before.blank? && ! after.blank?) || (after.blank? && ! before.blank?)
          update_collection_relevance
        end
      end
    end
  end

  def as_json(options = {})
    super(options.merge(except: [:added_by_user_id, :collection_id, :name])).
      merge(name: collected_item.collected_name)
  end

  def is_hidden?
    if self.collected_item_type == "DataObject"
      associations = DataObjectsHierarchyEntry.where(data_object_id: self.collected_item_id)
      associations.each do |asso|
        return false if asso.visibility_id == Visibility.visible.id
      end
      return true
    end
    return  false
  end
end
