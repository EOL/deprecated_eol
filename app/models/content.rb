# TL;DR: This is a curatable join model between a Node (HierarchyEntry) and some
# kind of content, like an Image, Article, Name, or Trait.
#
# The real power of this class comes from the scopes. Check them out.
#
# These are INTENDED fields, but we don't need them yet. Better to wait:
# cleaner.
# t.boolean :trusted_source, default: false
# t.boolean :misleading, default: false
# t.boolean :low_quality, default: false
# t.boolean :misidentified, default: false
# t.boolean :duplicate, default: false
# t.boolean :inappropriate, default: false
class Content < ActiveRecord::Base
  belongs_to :node, class_name: "HierarchyEntry", inverse_of: :contents
  # See scopes for a list of possible types:
  belongs_to :item, polymorphic: true

  has_many :content_curations, inverse_of: :content
  has_many :pages, through: :node, class_name: "TaxonConcept"

  scope :visible, -> { where(visible: true) }
  scope :vetted, -> { where(vetted: true) }
  scope :included, -> { where(overview_include: true) }
  scope :excluded, -> { where(overview_exclude: true) }
  # These are contents that are only available here because we're looking at an
  # ancestor, to whom this conentent has propogated. For example, an image of a
  # Raccoon will appear on the page of Animalia in "contents.ancestors".
  scope :ancestors, -> { where(ancestor: true) }
  # These are all the types of polymorphic items:
  scope :vernaculars, -> { where(item_type: "Vernacular") }
  scope :synonyms, -> { where(item_type: "Synonym") }
  scope :images, -> { where(item_type: "Image") }
  scope :videos, -> { where(item_type: "Video") }
  scope :sounds, -> { where(item_type: "Sound") }
  scope :articles, -> { where(item_type: "Article") }
  scope :links, -> { where(item_type: "Link") }
  # NOTE: Right now, this is the only one that works: :)
  scope :traits, -> { where(item_type: "Trait") }
  scope :maps, -> { where(item_type: "Map") }
end
