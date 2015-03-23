# This is a class used by Tramea.
# This is a denormalized class. It needs to be rebuilt when:
# * The user changes any part of her name
# * The agent changes its full_name
# * The Resource changes its title
class NameSource < ActiveRecord::Base
  belongs_to :common_name
  belongs_to :source, polymorphic: true # (User, Agent, Resource, Hierarchy)
  belongs_to :content_partner # ONLY if the source is a Resource...
  # TODO: add rel's on User, Agent, Resource, content_partner, Hierarchy
end
