# What this represents is a way for Ruby to talk to PHP.  If PHP and Ruby share class names (exactly--that's why this
# is not EOL::CodeBridge; nesting classes isn't the same), they can talk to one another using normal JSON...
# The library is needed for the translation.
class CodeBridge
  @queue = 'php' # Anything in the php queue will be handled by php, DUH.

  # This method is called when PHP talks to Ruby!
  def self.perform(args)
    EOL.log_call
    EOL.log("Notifications: #{Resque.size("notifications")})", prefix: ".")
    EOL.log("Data: #{Resque.size("data")})", prefix: ".")
    EOL.log("Harvesting: #{Resque.size("harvesting")})", prefix: ".")
    if args['cmd'] == 'check_status_and_notify'
      EOL.log("Check and Notify", prefix: ".")
      with_error_handling(args) do
        ClassificationCuration.find(args['classification_curation_id']).check_status_and_notify
      end
    elsif args['cmd'] == 'publish_batch'
      EOL.log("Publish Batch", prefix: ".")
      with_error_handling(args) do
        resources = Resource.where(id: Array(args['resource_ids']))
        batch = HarvestBatch.new(resources)
        batch.post_harvesting
        Resque.enqueue(CodeBridge, { 'cmd' => 'top_images' })
      end
    elsif args['cmd'] == 'denormalize_tables'
      EOL.log("Denormalize", prefix: ".")
      batch = HarvestBatch.new
      with_error_handling(args) { batch.denormalize_tables }
    elsif args['cmd'] == 'clear_cache'
      EOL.log("Clear Cache", prefix: ".")
      tc = TaxonConcept.find(args['taxon_concept_id'])
      if tc
        with_error_handling(args) { TaxonConceptCacheClearing.clear(tc) }
      end
    else
      EOL.log("ERROR: NO command responds to #{args['cmd']}", prefix: "*")
    end
  end

  def self.with_error_handling(args, &block)
    begin
      yield
    rescue => e
      EOL.log("ERROR: #{e.message}", prefix: "*")
      EOL.log("KEYS:", prefix: ".")
      args.keys.each do |key|
        EOL.log("#{key}: #{args[key]}", prefix: ".")
      end
    end
  end

  # These methods are here for actually enqueing the jobs. Thus, you call CodeBridge.split_classification(data),
  # and the data will be moved to PHP and handled there. These class methods are NOT called by Resque!
  def self.move_entry(options = {})
    Resque.enqueue(CodeBridge, {'cmd'                          => 'move',
                                'taxon_concept_id_from'        => options[:from_taxon_concept_id],
                                'hierarchy_entry_id'           => options[:hierarchy_entry_id],
                                'taxon_concept_id_to'          => options[:to_taxon_concept_id],
                                'bad_match_hierarchy_entry_id' => options[:exemplar_id],
                                'confirmed'                    => 'force', # UI enforces restrictions.
                                'classification_curation_id'   => options[:classification_curation_id]})
  end

  def self.split_entry(options = {})
    Resque.enqueue(CodeBridge, {'cmd'                          => 'split',
                                'hierarchy_entry_id'           => options[:hierarchy_entry_id],
                                'bad_match_hierarchy_entry_id' => options[:exemplar_id],
                                'confirmed'                    => 'confirmed', # note, no need for 'force' on split
                                'classification_curation_id'   => options[:classification_curation_id]})
  end

  def self.merge_taxa(id1, id2, options = {})
    Resque.enqueue(CodeBridge, {'cmd'                         => 'merge',
                                'id1'                         => id1,
                                'id2'                         => id2,
                                'classification_curation_id'  => options[:classification_curation_id],
                                'confirmed'                   => 'confirmed'}) # No need for "force" on merge.
  end

  def self.reindex_taxon_concept(taxon_concept_id)
    args = {'cmd' => 'reindex_taxon_concept', 'taxon_concept_id' => taxon_concept_id}
    Resque.enqueue(CodeBridge, args)
  end

end
