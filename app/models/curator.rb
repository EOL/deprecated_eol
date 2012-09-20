class Curator < $PARENT_CLASS_MUST_USE_MASTER

  self.table_name = "users"

  belongs_to :curator_verdict_by, :class_name => "User", :foreign_key => :curator_verdict_by_id
  belongs_to :curator_level
  belongs_to :requested_curator_level, :class_name => CuratorLevel.to_s, :foreign_key => :requested_curator_level_id

  has_many :curators_evaluated, :class_name => "User", :foreign_key => :curator_verdict_by_id
  has_many :curator_activity_logs
  has_many :curator_activity_logs_on_data_objects, :class_name => CuratorActivityLog.to_s,
           :conditions =>
             Proc.new { "curator_activity_logs.changeable_object_type_id = #{ChangeableObjectType.raw_data_object_id}" }
  has_many :classification_curations

  before_save :instantly_approve_curator_level_if_possible
  after_create :join_curator_community_if_curator

  validates_presence_of :curator_verdict_at, :if => Proc.new { |obj| !obj.curator_verdict_by.blank? }
  validates_presence_of :credentials, :if => :curator_attributes_required?
  validates_presence_of :curator_scope, :if => :curator_attributes_required?

  attr_accessor :curator_request

  scope :curators, :conditions => 'curator_level_id is not null'

  def self.taxa_synonyms_curated(user_id = nil)
    # list of taxa where user added, removed, curated (trust, untrust, inappropriate, unreview) a common name
    query = "activity_log_type:CuratorActivityLog AND feed_type_affected:Synonym AND user_id:#{user_id}"
    results = EOL::Solr::ActivityLog.search_with_pagination(query, {:filter=>"names", :per_page=>999999, :page=>1})
    taxa = results.collect{|r| r['instance']['taxon_concept_id']}.uniq
  end

  # NOTE - this is currently ONLY used in an exported (CSV) report for admins... so... LOW priority.
  # get the total objects curated for a particular curator activity type
  def self.total_objects_curated_by_action_and_user(action_id = nil, user_id = nil, changeable_object_type_ids = nil, return_type = 'count', created_at = false)
    action_id ||= Activity.raw_curator_action_ids
    changeable_object_type_ids ||= ChangeableObjectType.data_object_scope
    if return_type == 'count'
      query = "SELECT cal.user_id, COUNT(DISTINCT cal.object_id) as count "
    elsif return_type == 'hash'
      query = "SELECT cal.* "
    end
    query += "FROM #{CuratorActivityLog.full_table_name} cal JOIN #{Activity.full_table_name} acts ON (cal.activity_id = acts.id) WHERE "
    if user_id.class == Fixnum
      query += "cal.user_id = #{user_id} AND "
    elsif user_id.class == Array
      query += "cal.user_id IN (#{user_id.join(',')}) AND "
    end
    if action_id.class == Fixnum
      query += "acts.id = #{action_id} AND "
    elsif action_id.class == Array
      query += "acts.id IN (#{action_id.join(',')}) AND "
    end
    if created_at
      query += "cal.created_at >= '#{created_at}' AND "
    end
    query += " cal.changeable_object_type_id IN (#{changeable_object_type_ids.join(",")}) "
    if return_type == 'count'
      query += " GROUP BY cal.user_id"
    end
    results = User.connection.execute(query)
    if return_type == 'hash'
      return [] if resuts.to_a.empty?
      return results # TODO - we need to make an array of hashes, here.  Grrr.  (Check that it's needed.)
    end
    return_hash = {}
    user_id_i = results.fields.index('user_id')
    count_i = results.fields.index('count')
    results.each do |r|
      return_hash[r[user_id_i].to_i] = r[count_i].to_i
    end
    if user_id.class == Fixnum
      return return_hash[user_id] || 0
    end
    return_hash
  end

  def self.taxon_concept_ids_curated(user_id = nil)
    query = "SELECT DISTINCT cal.user_id, dotc.taxon_concept_id
      FROM #{CuratorActivityLog.full_table_name} cal
      JOIN #{Activity.full_table_name} acts ON (cal.activity_id = acts.id)
      JOIN #{DataObjectsTaxonConcept.full_table_name} dotc ON (cal.object_id = dotc.data_object_id) WHERE "
    if user_id.class == Fixnum
      query += "cal.user_id = #{user_id} AND "
    elsif user_id.class == Array
      query += "cal.user_id IN (#{user_id.join(',')}) AND "
    end
    query += " cal.changeable_object_type_id IN (#{ChangeableObjectType.data_object_scope.join(",")})
      AND acts.id != #{Activity.rate.id} "
    results = User.connection.execute(query)
    user_id_i = results.fields.index('user_id')
    taxon_concept_id_i = results.fields.index('taxon_concept_id')
    return_hash = {}
    results.each do |r|
      return_hash[r[user_id_i].to_i] ||= []
      return_hash[r[user_id_i].to_i] << r[taxon_concept_id_i].to_i
    end
    if user_id.class == Fixnum
      taxon_concept_ids = []
      if return_hash[user_id]
        taxon_concept_ids += return_hash[user_id]
      end
      taxon_concept_ids += Curator.taxa_synonyms_curated(user_id)
      return taxon_concept_ids.uniq
    end
    return_hash
  end

  # TODO - This is only used in the admin console; should be removed
  def self.comment_curation_actions(user_id = nil)
    query = "SELECT DISTINCT cal.user_id, cal.object_id
      FROM #{CuratorActivityLog.full_table_name} cal
      JOIN #{Activity.full_table_name} acts ON (cal.activity_id = acts.id) WHERE "
    if user_id.class == Fixnum
      query += "cal.user_id = #{user_id} AND "
    elsif user_id.class == Array
      query += "cal.user_id IN (#{user_id.join(',')}) AND "
    end
    query += " cal.changeable_object_type_id = #{ChangeableObjectType.comment.id}
      AND acts.id != #{Activity.create.id}"
    results = User.connection.execute(query)
    user_id_i = results.fields.index('user_id')
    object_id_i = results.fields.index('object_id')
    return_hash = {}
    results.each do |r|
      return_hash[r[user_id_i].to_i] ||= []
      return_hash[r[user_id_i].to_i] << r[object_id_i].to_i
    end
    if user_id.class == Fixnum
      return return_hash[user_id] || []
    end
    return_hash
  end

  def curator_request
    return true unless is_curator? || (curator_scope.blank? && credentials.blank?)
  end

  def total_species_curated
    Curator.taxon_concept_ids_curated(self.id).length
  end

  def vet object
    object.vet(self) if object and object.respond_to? :vet and can_curate? object
  end

  def unvet object
    object.unvet(self) if object and object.respond_to? :unvet and can_curate? object
  end

  def revoke_curator
    # TODO: This is weird, if we are revoking the curator access why not call update_attributes once and
    # add if-else loop to check if it successfully updated the attributes.
    unless curator_level_id == nil
      self.update_attributes(:curator_level_id => nil)
    end
    self.leave_community(CuratorCommunity.get) if self.is_member_of?(CuratorCommunity.get)
    self.update_attributes(:curator_verdict_by => nil,
                           :curator_verdict_at => nil,
                           :requested_curator_level_id => nil,
                           :credentials => nil,
                           :curator_scope => nil,
                           :curator_approved => nil)
  end
  alias revoke_curatorship revoke_curator

  # this is run before_save. It doesn't have a level symbol, it doesn't send notification, and it doesn't set
  # curator_verdict_by or curator_approved, so it's quite different from #grant_curator
  def instantly_approve_curator_level_if_possible
    if self.requested_curator_level_id == CuratorLevel.assistant_curator.id
      unless self.curator_level_id == self.requested_curator_level_id
        was_curator = self.is_curator?
        self.curator_level_id = self.requested_curator_level_id
        join_curator_community_if_curator unless was_curator
        self.curator_verdict_at = Time.now
      end
      self.requested_curator_level_id = nil
    end
  end

  # NOTE - default level implies that user.grant_curator means that they're supposed to be a full curator.  Makes
  # sense to me.  :P
  def grant_curator(level = :full, options = {})
    level = CuratorLevel.send(level)
    unless curator_level_id == level.id
      was_curator = self.is_curator?
      self.curator_level_id = level.id
      if options[:by]
        self.curator_verdict_by = options[:by]
        self.curator_verdict_at = Time.now
        self.curator_approved   = 1
      end
      self.save
      Notifier.curator_approved(self).deliver unless $LOADING_BOOTSTRAP
      join_curator_community_if_curator unless was_curator
    end
    self.update_attributes(:requested_curator_level_id => nil) # Not using validations; don't care if user is valid
    self
  end

  # NOTE: Careful!  This one means "any kind of curator"... which may not be what you want.  For example, an
  # assistant curator can't see vetting controls, so don't use this; use #min_curator_level?(:full) or the like.
  def is_curator?
    self.curator_level_id
  end

  # NOTE: Careful!  The next three methods are for checking the EXACT curator level.  See also #min_curator_level?.
  def master_curator?
    self.curator_level_id == CuratorLevel.master.id
  end

  def full_curator?
    self.curator_level_id == CuratorLevel.full.id
  end

  def assistant_curator?
    self.curator_level_id == CuratorLevel.assistant.id
  end

  def is_pending_curator?
    !requested_curator_level.nil? && !requested_curator_level.id.zero?
  end

  def min_curator_level?(level)
    case level
    when :assistant
      return is_curator?
    when :full
      return master_curator? || full_curator?
    when :master
      return master_curator?
    end
  end

  def last_curator_activity
    last = CuratorActivityLog.find_by_user_id(id, :order => 'created_at DESC', :limit => 1)
    return nil if last.nil?
    return last.created_at
  end

  def check_credentials
    credentials = '' if credentials.nil?
  end

  # validation condition for required curator attributes
  def curator_attributes_required?
    (!self.requested_curator_level_id.nil? && !self.requested_curator_level_id.zero? &&
      self.requested_curator_level_id != CuratorLevel.assistant_curator.id) ||
    (!self.curator_level_id.nil? && !self.curator_level_id.zero? &&
      self.curator_level_id != CuratorLevel.assistant_curator.id)
  end

  def first_last_names_required?
    (!self.requested_curator_level_id.nil? && !self.requested_curator_level_id.zero?) ||
    (!self.curator_level_id.nil? && !self.curator_level_id.zero?)
  end

  def join_curator_community_if_curator
    self.join_community(CuratorCommunity.get) if self.is_curator?
  end

end
