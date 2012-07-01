# What this represents is a way for Ruby to talk to PHP.  If PHP and Ruby share class names (exactly--that's why this
# is not EOL::PhpCodeBridge; nesting classes isn't the same), they can talk to one another using normal JSON...
# The library is needed for the translation.
class PhpCodeBridge
  @queue = 'php' # Anything in the php queue will be handled by php, DUH.

  # Normally, there would be a #self.perform method here, but it would NEVER get called, as the class that does the
  # work is in the PHP codebase

  # These methods are here for actually enqueing the jobs. Thus, you call PhpCodeBridge.split_classification(data),
  # and the data will be moved to PHP and handled there. These class methods are NOT called by Resque!
  def self.split_classification(options = {})
    Resque.enqueue(Reskewer, {'cmd'                          => 'split',
                              'taxon_concept_id_from'        => options[:from_taxon_concept_id],
                              'hierarchy_entry_id'           => options[:hierarchy_entry_id],
                              'taxon_concept_id_to'          => options[:to_taxon_concept_id],
                              'bad_match_hierarchy_entry_id' => options[:exemplar_hierarchy_entry_id],
                              'confirmed'                    => 1,
                              'reindex'                      => 1 })
  end

end
