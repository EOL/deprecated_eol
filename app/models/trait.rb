# This is a class used by Tramea.
#
# This will appear VERY similar to DataPointUri. ...And, structurally, it is.
# However, dpuri only works when a LOT of "thinking" is applied to it, and this
# model is meant to store that logic for faster retrieval.
#
create_table :traits do |t|
  # We need to know the original dpuri id for faster lookup and to get old data,
  # when needed (not in the UI, but during bugfixes):
  t.integer :data_point_uri_id, null: false
  # A taxon_concept is always the subject.
  t.integer :taxon_concept_id, null: false
  t.integer :units_known_uri_id
  # predicate will map to a known_uri, usually.
  t.string :predicate, null: false
  # object will be a taxon concept URI, a known_uri, or a "raw" value. It may
  # well have been converted from an original value; we don't need that in the
  # UI, so it is not stored here.
  t.string :object, null: false
  t.string :life_stage
  t.string :statistical_method
  t.string :sex
