Take 2... The last version wasn't... I don't know... meaningful (?) enough.

# I am skipping some of the obvious things, like users, etc, etc...

# TODO: map these guys to existing classes, where possible.

class Source
  belongs_to :content_partner
  has_many :harvests, inverse_of: :source
  has_many :nodes, through: :harvests
end

class Harvest
  belongs_to :source, inverse_of: :harvests
  has_many :nodes, inverse_of: :harvest
  scope :latest, -> { order_by('id DESC').first }
end

class Page
  t.string :ancestry # A pipe-delimited list...
  acts_as_tree
  has_many :nodes, inverse_of: :page
  scope :ancestors_of, -> { |page| where(id: ancestry.split('|') }
  def rebuild_ancestry
    update_attribute(:ancestry, nodes.map(&:ancestors).join('|'))
  end
end

# Yes! I am putting the names (but not synonyms) here. Right here. Where they
# belong: because THAT is how we identify a node.
class Node
  t.string :scientific_name # with authorship, from partner
  t.string :canonical_name # without authorship, via globalnames.
  scope :ancestors_of, -> { |node| where(id: ancestry.split('|') }
  acts_as_tree
  belongs_to :page, inverse_of: :nodes
  belongs_to :source, inverse_of: :nodes
  belongs_to :harvest, inverse_of: :nodes
  has_many :contents, inverse_of: :node
  def rebuild_ancestry
    update_attribute(:ancestry, ancestors.join('|'))
  end
end

class Curation
  belongs_to :user
  belongs_to :curated, polymorphic: true # Can be any of the "join models," below.
end

class Content
  belongs_to :node, inverse_of: :contents
  belongs_to :medium, polymorphic: true, inverse_of: :contents
end

class Synonym
  belongs_to :node
  belongs_to :scientific_name
  has_many :curations
end

create_table :vernaculars do |t|
  t.string :language, limit: 10
end
class Vernacular
  belongs_to :node
  belongs_to :common_name
  has_many :curations
end

class Trait
  belongs_to :node
  belongs_to :triple # Not really; stored in triple-store.
  has_many :meta_traits
  has_many :curations
end
class MetaTrait
  belongs_to :trait
  has_many :curations
end

class PageLink
  belongs_to :node
  belongs_to :link
  has_many :curations
end

class Map
  belongs_to :node
  belongs_to :medium
  has_many :curations
end

class Article
  belongs_to :node
  belongs_to :medium
  has_many :curations
end

class Image
  belongs_to :node
  belongs_to :medium
  has_many :ancestor_nodes, class: "Node", through: :node
  has_many :curations
  acts_as_propagator # updates will propagate to node ancestors.
end

class Sound
  belongs_to :node
  belongs_to :medium
  has_many :ancestor_nodes, class: "Node", through: :node
  has_many :curations
  acts_as_propagator # updates will propagate to node ancestors.
end

class Video
  belongs_to :node
  belongs_to :medium
  has_many :ancestor_nodes, class: "Node", through: :node
  has_many :curations
  acts_as_propagator # updates will propagate to node ancestors.
end
