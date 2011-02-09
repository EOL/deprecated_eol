class List < ActiveRecord::Base

  belongs_to :user
  belongs_to :community

  has_many :list_items
  # TODO = you can have lists that point to lists, so there SHOULD be a has_many relationship here to all of the list items
  # that contain this list.  ...I don't know if we need that yet, but it would normally be named "list_items", which doesn't
  # work (because we're using that for THIS list's children)... so we will have to re-name it and make it slightly clever.

  validates_presence_of :name

  # This is cheating, slightly.  We want it to be unique within a user's scope, but ALSO within the scope of ALL
  # communities... it so happens that the scope of the later is, in fact, a user_id (of nil)... so this works:
  validates_uniqueness_of :name, :scope => [:user_id]
  validates_uniqueness_of :community_id, :if => Proc.new {|l| ! l.community_id.blank? }

  def add(what)
    case what.class.name
    when "TaxonConcept"
      list_items << ListItem.create(:object_type => "TaxonConcept", :object_id => what.id, :name => what.scientific_name)
    when "User"
      list_items << ListItem.create(:object_type => "User", :object_id => what.id, :name => what.full_name)
    when "DataObject"
      list_items << ListItem.create(:object_type => "DataObject", :object_id => what.id, :name => what.short_title)
    when "Community"
      list_items << ListItem.create(:object_type => "Community", :object_id => what.id, :name => what.name)
    when "List"
      list_items << ListItem.create(:object_type => "List", :object_id => what.id, :name => what.name)
    else
      raise EOL::Exceptions::InvalidListItemType.new("I cannot create a list item from a #{what.class.name}")
    end
  end

  def create_community
    raise EOL::Exceptions::OnlyUsersCanCreateCommunitiesFromLists unless user
    raise EOL::Exceptions::CannotCreateCommunityWithoutTaxaInList unless contains_taxa?
    community = Community.create(:name => "#{name} Community")
    community.initialize_as_created_by(user)
    list_items.each do |li|
      community.focus.add(li.object) if li.object_type == 'TaxonConcept'
    end
    community
  end

private

  # No reason for this to be private, but it is UNTESTED.  If you move this, please test it.
  def contains_taxa?
    return list_items.map {|li| li.object_type }.include? 'TaxonConcept'
  end

  def validate
    errors.add(:user_id, "Must be associated with either a user or a community"[]) if
      self.community_id.nil? && self.user_id.nil?
    errors.add(:user_id, "Cannot be associated with both a user and a community"[]) if
      ((! self.community_id.nil?) && (! self.user_id.nil?))
  end

end
