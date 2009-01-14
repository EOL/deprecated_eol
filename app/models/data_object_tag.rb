# Represents a key/value-pair style Tag to be used to tag DataObjects with.
#
# Example key/value pairs:
#   * color:red
#   * Habitat:Marsh
#   * Anything:AnythingElse
#
# DataObjectTag isn't necessarily specific to DataObjects.  See DataObjectTags 
# for the association between DataObject and DataObjectTag.
#
class DataObjectTag < ActiveRecord::Base
  
  validates_presence_of :key, :value
  validates_uniqueness_of :value, :scope => :key # value must be unique for given key
  #validates_format_of :key,   :with => /^\w+$/, :message => 'Key can only contain alphanumeric characters'
  validates_format_of :value, :with => /^\w+$/, :message => 'Key can only contain alphanumeric chartacters'
  validates_length_of :key,   :maximum => 30
  before_save :normalizes_case_and_spaces
  
  named_scope :ordered, :order => '`key` ASC, `value` ASC'
  # this is **NOT** an alias of #is_public?
  #
  # this is smarter than is_public? and will check the database to see how many times this 
  # tag is used and, based on that + is_public, it will return whether this tag is public
  #
  # if you wanna make sure that you *only* check the is_public field and don't hit the 
  # database, then you should use .is_public?
  def public?
    self.is_public or self.usage_count >= DataObjectTags::minimum_usage_count_for_public_tags 
  end

  # whether or not the is_public field == true
  def is_public?
    self.is_public == true
  end

  # make sure tags and keys don't have spaces in them!
  def normalizes_case_and_spaces
    self.key.gsub!(/[\s]+/,'_')
    self.key.downcase!
    self.value.gsub!(/[\s]+/,'_')
    self.value.downcase!
  end
  
  def usage_count
    tags = DataObjectTags.tags_with_usage_count.find_by_data_object_tag_id id
    (tags.nil?) ? 0 : tags.usage_count.to_i
  end

  # shotcut finder method for getting all tags by key or getting a key+value pair
  #
  # Usage:
  #   DataObjectTag[:key] => [<DataObjectTag>,<DataObjectTag>]
  #   DataObjectTag[:key, :value] => <DataObjectTag>
  #
  # conventionally, i'm very careful about using the indexer method on objects as it can be unintuitive.
  # because of the Hash-like nature of DataObjectTag, i believe DataObjectTag[:key] is a natural and 
  # intuitive shortcut for getting the DataObjectTag objects associated with :key
  def self.[] key, value = nil
    if value.nil?
      ordered.find_all_by_key key.to_s
    else
      ordered.find_by_key_and_value key.to_s, value.to_s
    end
  end

  # suggests possible keys when provided with a partially typed key
  #
  # Usage:
  #
  #   >> DataObjectTag.suggest_key 'co'
  #   => ['color']
  #   
  #   >> DataObjectTag.suggest_key 'co', DataObjectTag.find_by_something
  #
  # You can provide an array of DataObjectTags as a second argument
  # and the suggestion will run using those Tags instead of querying the DB
  def self.suggest_key partial_key, precached_tags = nil, public_only = true
    unless precached_tags
      tags = find :all, :conditions => ['`key` LIKE ?', "#{partial_key}%"], :order => '`key` ASC'
      tags = DataObjectTags.public_tags_for_tags tags if public_only
    else
      tags = precached_tags.select {|tag| tag.key.starts_with? partial_key  }
      tags = tags.sort_by {|t| t.key } if tags
    end
    tags.map(&:key).uniq if tags
  end

  # Keys that are used by public tags
  def self.public_keys
    public_tags.map(&:key).uniq
  end

  # Key/value pairs (Tags) that are public
  def self.public_tags
    DataObjectTags.public_tags_for_tags DataObjectTag.all
  end

  # suggests possible values when provided with a partially typed value for a particular key
  #
  # Usage:
  #
  #   >> DataObjectTag.suggest_value 'bl', :color
  #   => ['blue']
  #
  #   >> DataObjectTag.suggest_value 'bl', :color, DataObjectTag.find_by_something
  #
  # You can provide an array of DataObjectTags as a third argument
  # and the suggestion will run using those Tags instead of querying the DB
  def self.suggest_value partial_value, key, precached_tags = nil, public_only = true
    if precached_tags
      tags = precached_tags.select {|tag| tag.key == key.to_s and tag.value.starts_with? partial_value }
      tags = tags.sort_by {|t| t.value } if tags
    else
      if public_only
        all_tags = DataObjectTags.public_tags_for_tag_key key # get all of the possible *public* tags for this key
        tags=all_tags.select {|t| t.value.starts_with? partial_value }
      else
        tags = find :all, :conditions => ['`key` = ? AND `value` LIKE ?', key.to_s, "#{partial_value}%"], :order => '`value` ASC'
      end
    end
    tags.map &:value if tags
  end

  # get all of the keys that've ever been created
  def self.keys
    tags = find :all, :select => 'DISTINCT `key`', :order => '`key`'
    tags.map! {|t| t.key } unless tags.empty?
    tags
  end

  def to_s
    "[DataObjectTag key:#{key} value:#{value}]"
  end

  protected

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: data_object_tags
#
#  id                :integer(4)      not null, primary key
#  is_public         :boolean(1)
#  key               :string(255)     not null
#  total_usage_count :integer(4)
#  value             :string(255)     not null
#  created_at        :datetime
#  updated_at        :datetime

