# Associates tags (DataObjectTag) with objects (DataObject)
#
# *NOTE*: this table is unconventionally named!
#
# this class is a many-to-many association join table
# between DataObject and DataObjectTag
#
# this _should_ be named DataObjectDataObjectTag or DataObjectTagDataObject
#
# both of those conventional names are unintuitive, in my opinion, so we use: DataObjectTags
#
# we keep the database conventions, however, so the table name is: +data_object_data_object_tags+
#
class DataObjectTags < ActiveRecord::Base
  set_table_name 'data_object_data_object_tags'

  belongs_to :data_object
  belongs_to :data_object_tag
  belongs_to :user

  validates_presence_of :data_object_id, :data_object_tag_id
  validates_uniqueness_of :data_object_tag_id, :scope => [ :data_object_id, :user_id ]

  alias tag data_object_tag
  alias object data_object

  DEFAULT_MIN_USAGE_FOR_PUBLIC_TAGS = 3
  class << self
    attr_accessor :minimum_usage_count_for_public_tags
    def minimum_usage_count_for_public_tags
      @minimum_usage_count_for_public_tags ||= DEFAULT_MIN_USAGE_FOR_PUBLIC_TAGS
    end
  end

  named_scope :private_tags, :conditions => 'user_id IS NOT NULL', :include => :data_object_tag
  named_scope :private_tags_for, lambda {|user|{ :conditions => ['user_id = ?', user.id], :include => :data_object_tag }}
  named_scope :tags_with_usage_count, :select => "data_object_id, data_object_tag_id, count(user_id) as usage_count", 
                                      :group => 'data_object_tag_id'
  named_scope :search_by_tag,  lambda{|tag|{  :conditions => ['data_object_tag_id = ?', tag.id] }}
  #named_scope :search_by_tags_or, lambda{|tags|{ :conditions => "data_object_tag_id IN (#{tags.map(&:id).join(',')})" }}

  # named_scope :search_by_tags_and, lambda{|tags|{ :conditions => tags.map {|t| "data_object_tag_id = #{t.id}" }.join(' AND ') }}
  # SELECT * FROM t1 WHERE column1 = (SELECT column1 FROM t2);
  def self.search_by_tags_or(tags, user_id = nil) 
    sql = "select dt.*, count(dt.id) do_count 
            from data_object_tags t 
              join data_object_data_object_tags dt 
                on (t.id = dt.data_object_tag_id) 
            where
              dt.data_object_tag_id in (#{tags.map(&:id).join(',')})
            group by dt.data_object_id"
    res = DataObjectTags.find_by_sql(sql);
    res.select {|t| (t.do_count.to_i >= DataObjectTags::minimum_usage_count_for_public_tags || (user_id && t.user_id == user_id.to_i)) }
  end

  def to_s
    "<DataObjectTags object:'#{object}' tag:'#{tag}' />"
  end

  # how many users have tagged a data object with ? (what tags) ?
  #
  # Usage:
  #   DataObjectTags.public_tags_for_data_object @data_object
  #   DataObjectTags.public_tags_for_data_object @data_object.id
  #
  def self.public_tags_for_data_object data_object
    id   = (data_object.is_a?Fixnum) ? data_object : data_object.id
    tags = self.tags_with_usage_count.find_all_by_data_object_id id
    tags.select {|t| t.usage_count.to_i >= DataObjectTags::minimum_usage_count_for_public_tags }.map &:tag
  end

  # Returns all of the tags that have been promoted to 'public' for a particular tag key, eg. "color"
  #
  # Usage:
  #   public_tags_for_tag_key :color (should return all of the *public* tags where the key is Color)
  #
  def self.public_tags_for_tag_key key
    public_tags_for_tags DataObjectTag[key]
  end

  # Takes a list of tags and only returns the public ones
  #
  # Usage:
  #   public_tags_for_tags DataObjectTag[:color]
  #
  def self.public_tags_for_tags tags
    public_tags = self.tags_with_usage_count.find :all, :conditions => ['data_object_tag_id IN (?)', tags.map(&:id) ], :include => :data_object_tag
    public_tags = public_tags.select {|t| t.tag.is_public == true || t.usage_count.to_i >= DataObjectTags::minimum_usage_count_for_public_tags }.map &:tag
    # we have have been passed some tags that has .is_public set but they aren't actually *used* anywhere so they weren't returned by tags_with_usage_count
    public_tags = ( public_tags + tags.select {|t| t.is_public? } ).uniq
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: data_object_data_object_tags
#
#  id                 :integer(4)      not null, primary key
#  data_object_id     :integer(4)      not null
#  data_object_tag_id :integer(4)      not null
#  user_id            :integer(4)

