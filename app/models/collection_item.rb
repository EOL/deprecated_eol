# NOTE - you can get a list of all the possible collection item types with this
# command: git grep "has_many :collection_items, :as" app ...Also note, that to
# be "collectable", you must implement #summary_name and #collected_name.
class CollectionItem < ActiveRecord::Base

  include Refable

  belongs_to :collection, touch: true
  belongs_to :collected_item, polymorphic: true
  belongs_to :added_by_user, class_name: User.to_s,
    foreign_key: :added_by_user_id
  has_and_belongs_to_many :refs

  # NOTE: type is not an indexed field, so don't rely on this for speed:
  scope :collections, conditions: { collected_item_type: 'Collection' }
  scope :communities, conditions: { collected_item_type: 'Community' }
  scope :data_objects, conditions: { collected_item_type: 'DataObject' }
  scope :taxa, conditions: { collected_item_type: 'TaxonConcept' }
  scope :users, conditions: { collected_item_type: 'User' }
  scope :annotated, conditions: 'annotation IS NOT NULL AND annotation != ""'

  attr_accessible :annotation, :collected_item_id, :collected_item_type,
    :sort_field, :collected_item, :name, :collection, :added_by_user,
    :added_by_user_id, :collection_id, :refs

  # Note that it doesn't validate the presence of collection.  A "removed"
  # collection item still exists, so we have a record of what it used to point
  # to (see CollectionsController#destroy). (Hey, the alternative is to have a
  # bunch of unused fields in collection_activity_logs, so it's actually better
  # to have these "zombie" rows here!)
  validates_presence_of :collected_item_id, :collected_item_type
  validates_uniqueness_of :collected_item_id,
    scope: [:collection_id, :collected_item_type],
    message: I18n.t(:item_not_added_already_in_collection),
    if: Proc.new { |ci| ci.collection_id }

  # Note we DO NOT update relevance on the collection on save or delete, since
  # we sometimes add/delete 1000 items at a time, and that would be a disaster,
  # since the collection only need be recalculated once.
  after_save     :reindex_in_solr
  after_update   :update_collection_relevance_if_annotation_switched
  before_destroy :remove_from_solr

  # Keeps an accurate count of items:
  counter_culture :collection

  # Information about how collection items interface with solr and views and the
  # like...
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

  # TODO: I don't believe this is the right way to do things. :\ I suggest we
  # take a different tack.
  def self.preload_collected_items(all_items, options = {})
    groups = all_items.group_by(&:collected_item_type)
    groups.each do |type, items|
      Kernel.const_get(type).
        where(id: items.map(&:collected_item_id)).each do |thing|
        items.each do |item|
          all_items.find { |it| it.id == item.id }.collected_item = thing
        end
      end
    end
    if (options[:richness_score])
      TaxonConceptMetric.
        where(taxon_concept_id: all_items.
          select { |i| i.taxon_concept? }.
          map(&:collected_item_id)).
        each do |metric|
        all_items.each do |item|
          item["richness_score"] = metric.richness_score if
            item.collected_item_id == metric.taxon_concept_id
        end
      end
    end
    all_items # return for chains
  end

  # TODO - would be nice to have a list of superceded taxa from the harvest!
  def self.remove_superceded_taxa
    # No appropriate indexes, here, so we have to use ID:
    last = CollectionItem.maximum(:id)
    batch = 10_000
    current = 1
    while current < last
      items = []
      taxa.
      select("collection_items.*, supercedure_id new_tc_id").
      includes(collected_item: :taxon_concept_metric).
        joins("JOIN taxon_concepts ON taxon_concepts.id = "\
        "collection_items.collected_item_id").
      where(["supercedure_id != 0 AND collection_items.id > ? AND "\
        "collection_items.id < ?", current, current + batch]).
      find_each do |item|
        begin
          item.update_attribute(:collected_item_id, item[:new_tc_id])
          item["richness_score"] =
            item.collected_item.taxon_concept_metric.try(:richness_score)
          items << item
        rescue ActiveRecord::RecordNotUnique
          # The superceded taxon was already in the collection; safe to ignore:
          item.destroy
        end
        SolrCore::CollectionItems.reindex_items(items)
      end
      current += batch
    end
  end

  def self.spammy?(item, user)
    # It's never okay to have spam in the sort field. Ever.
    return true if item[:sort_field] =~ EOL.spam_re
    item[:annotation] =~ EOL.spam_re and user.newish?
  end

  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.can_edit_collection?(collection)
  end

  def taxon_concept?
    collected_item_type == "TaxonConcept"
  end

  def data_object?
    collected_item_type == "DataObject"
  end

  def collection?
    collected_item_type == "Collection"
  end

  def community?
    collected_item_type == "Community"
  end

  def user?
    collected_item_type == "User"
  end

  # Using has_one :through didn't work:
  def community
    return nil unless collection
    return nil unless collection.community
    return collection.community
  end

  def reindex_in_solr
    SolrCore::CollectionItems.reindex_items(self)
  end
  def remove_from_solr
    SolrCore::CollectionItems.delete_by_ids(id)
  end

  def update_collection_relevance
    collection.set_relevance if collection
  end

  # Because doing so is expensive, we check to make sure there's a need (which
  # would only be if annotation was added or removed)
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
    if data_object?
      associations = DataObjectsHierarchyEntry.
        where(data_object_id: self.collected_item_id)
      associations.each do |asso|
        return false if asso.visibility_id == Visibility.visible.id
      end
      return true
    end
    return  false
  end

  def to_hash
    # These might be preloaded:
    richness_score = self["richness_score"]
    data_object_rating = self["data_object_rating"]
    # If not, we need them:
    if taxon_concept?
      richness_score ||=
        collected_item.taxon_concept_metric.try(:richness_score)
    end
    if data_object?
      data_object_rating ||= collected_item.data_rating
    end
    solr_title = SolrCore.string(collected_item.collected_name)
    solr_title = collected_item_type if solr_title.empty?
    solr_title = "unknown" if solr_title.empty?
    {
      object_type: collected_item_type,
      object_id: collected_item_id,
      collection_id: collection_id,
      collection_item_id: id,
      annotation: SolrCore.string(annotation),
      added_by_user_id: added_by_user_id,
      # TODO: test whether these defaults are actually needed:
      date_created: SolrCore.date(created_at),
      date_modified: SolrCore.date(updated_at),
      title: solr_title,
      richness_score: richness_score || 0,
      data_rating: data_object_rating,
      sort_field: SolrCore.string(sort_field)
    }
  end
end
