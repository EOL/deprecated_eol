# This is a FAKE library.  Don't ever use it to do work (it does nothing).
#
# What this represents is a way to talk to PHP.  If PHP and Ruby share class names with Resque, they can talk to one
# another using normal JSON... but the library is needed for the translation.
class Reskewer
  @queue = 'php' # Anything in the php queue will be handled by php, DUH.

  # Normally, there would be a #self.perform method here, but this will NEVER get called, as it's meant for PHP.

  # This method here for actually enqueing the job. Seems self-referential, but... hey.
  def self.split_concepts()
    Resque.enqueue(Reskewer, {'cmd'                          => 'split',
                              'taxon_concept_id_from'        => '',
                              'hierarchy_entry_id'           => '',
                              'taxon_concept_id_to'          => '',
                              'bad_match_hierarchy_entry_id' => '',
                              'confirmed'                    => '',
                              'reindex'                      => '' })
  end

end
