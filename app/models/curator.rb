# Okay.
#
# So, this WAS an attempt at extracting curator functionality from the User model. It didn't work: Rails isn't really
# structured well for that kind of extraction (I have since learned the preferred method is to mixin behavior after
# loading the class... but our code isn't ready for that in its current state). That said, I couldn't bring myself to
# remove the class methods; they really really really don't belong on the User model and it felt "Wrong" (with a
# capital W) to revert those changes. 
#
# So, at least, those methods are here. They are "global inoformation about curators" ...and thus have nothing to do
# with specific instances.
class Curator

  def self.taxa_synonyms_curated(user_id = nil)
    # list of taxa where user added, removed, curated (trust, untrust, inappropriate, unreview) a common name
    query = "activity_log_type:CuratorActivityLog AND feed_type_affected:Synonym AND user_id:#{user_id}"
    results = EOL::Solr::ActivityLog.search_with_pagination(query, :filter => "names", :per_page => 999999, :page => 1, :skip_loading_instances => true)
    EOL::Solr.add_standard_instance_to_docs!(CuratorActivityLog,
      results.select{ |d| d['activity_log_type'] == 'CuratorActivityLog' }, 'activity_log_id',
      :selects => { :curator_activity_logs => [ :id, :taxon_concept_id ] })
    taxa = results.collect{ |r| r['instance']['taxon_concept_id'] }.uniq
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

end
