# DO NOT USE THIS unless you know you want your logging to be eager-saved. In general, you probably want to use
# LazyLoggingModel instead.
class LoggingModel < ActiveRecord::Base
  self.abstract_class = true
  establish_connection("#{Rails.env}_logging")

  def self.clear_taxon_activity_log_fragment_caches(notification_recipient_objects)
    direct_concept_ids = notification_recipient_objects.select{ |r| r.class == TaxonConcept }.collect{ |tc| tc.id }
    ancestor_concept_ids = notification_recipient_objects.select{ |r| r.class == Hash && r[:ancestor_ids] }.collect{ |h| h[:ancestor_ids] }
    all_taxon_concept_ids = (direct_concept_ids + ancestor_concept_ids).flatten.compact.uniq
    all_taxon_concept_ids.each do |tc_id|
      Language.approved_languages.each do |l|
        ActionController::Base.new.expire_fragment("taxon_overview_activity_#{tc_id}_#{l.iso_639_1}")
      end
    end
    direct_concept_ids.each do |tc_id|
      ActionController::Base.new.expire_fragment("taxon_overview_curators_#{tc_id}")
    end
  end
end
