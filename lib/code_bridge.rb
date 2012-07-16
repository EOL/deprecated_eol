# What this represents is a way for Ruby to talk to PHP.  If PHP and Ruby share class names (exactly--that's why this
# is not EOL::CodeBridge; nesting classes isn't the same), they can talk to one another using normal JSON...
# The library is needed for the translation.
class CodeBridge
  @queue = 'php' # Anything in the php queue will be handled by php, DUH.

  # Normally, there would be a #self.perform method here, but it would NEVER get called, as the class that does the
  # work is in the PHP codebase

  # These methods are here for actually enqueing the jobs. Thus, you call CodeBridge.split_classification(data),
  # and the data will be moved to PHP and handled there. These class methods are NOT called by Resque!
  def self.move_entry(options = {})
    Resque.enqueue(CodeBridge, {'cmd'                          => 'move',
                                'taxon_concept_id_from'        => options[:from_taxon_concept_id],
                                'hierarchy_entry_id'           => options[:hierarchy_entry_id],
                                'taxon_concept_id_to'          => options[:to_taxon_concept_id],
                                'bad_match_hierarchy_entry_id' => options[:exemplar_id],
                                'confirmed'                    => 'confirmed',
                                'notify'                       => options[:notify],
                                'reindex'                      => options[:reindex] ? 'reindex' : '' })
  end

  def self.split_entry(options = {})
    Resque.enqueue(CodeBridge, {'cmd'                          => 'split',
                                'hierarchy_entry_id'           => options[:hierarchy_entry_id],
                                'bad_match_hierarchy_entry_id' => options[:exemplar_id],
                                'confirmed'                    => 'confirmed',
                                'notify'                       => options[:notify],
                                'reindex'                      => options[:reindex] ? 'reindex' : '' })
  end

  def self.merge_taxa(id1, id2, options = {})
    Resque.enqueue(CodeBridge, {'cmd'       => 'merge',
                                'id1'       => id1,
                                'id2'       => id2,
                                'notify'    => options[:notify],
                                'confirmed' => 'confirmed'})
  end

end
