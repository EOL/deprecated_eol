# NOTE i haven't bothered alphabetizing these or anything ... i'll clean them up later!

require 'factory_girl'
require 'faker'
require File.dirname(__FILE__) + '/eol_factory_girl'

# Note - at the end of this file is Factory.prerequisites, which creates all of the "default" vaules the app counts on.

#### Sequences

Factory.sequence( :string ){|n| "unique#{ n }string" } # 'string' isn't elegant, but it's perfect for right now!
Factory.sequence( :email  ){|n| "bob#{n}@smith.com" }

#### Factories

Factory.define :agent_contact do |ac|
  ac.association :agent
  ac.association :agent_contact_role
  ac.given_name  { Factory.next(:string) }
  ac.family_name { Factory.next(:string) }
  ac.full_name   {|a| "#{a.first_name} #{a.last_name}" }
  ac.email       {|a| "#{a.first_name}.#{a.last_name}@example.com".downcase }
end

Factory.define :agent_status do |as|
  as.label { Factory.next(:string) }
end

Factory.define :agent do |agent|
  agent.created_at       { 5.days.ago }
  agent.homepage         ''
  agent.full_name        { Factory.next(:string) }
  agent.username         {|a| a.full_name.gsub(/\W+/, '').downcase }
  agent.email            { Factory.next(:email) }
  agent.hashed_password  { Digest::MD5.hexdigest('test password') }
  agent.association :agent_status
end

Factory.define :agents_data_object do |ado|
  ado.association :data_object
  ado.association :agent
  ado.association :agent_role
  ado.view_order  0
end

Factory.define :agents_hierarchy_entry do |ahe|
  ahe.association :agent
  ahe.association :agent_role
  ahe.association :hierarchy_entry
  ahe.view_order  2
end

Factory.define :agents_resource do |ar|
  ar.association :agent
  ar.association :resource
  ar.association :resource_agent_role
end

Factory.define :canonical_form do |cform|
  cform.string 'Cononica idenitifii'
end

Factory.define :collection do |col|
  col.association :agent
  col.title       'New Collection'
  col.description 'Testing New Colleciton'
  col.uri         'http://testing.new.collecti.on'
  col.link        'http://clicky.link.com'
  col.logo_url    'grin.jpg'
  col.vetted      1
end

Factory.define :contact_subject do |cs|
  cs.title      'TestContactSubject'
  cs.recipients { Faker::Internet.email }
  cs.active     true
  cs.created_at { 48.hours.ago }
  cs.updated_at { 48.hours.ago }
end

Factory.define :content_page do |cp|
  cp.association :content_section
  cp.page_name    'Test Content Page'
  cp.title        'Test Content Page'
  cp.left_content '<h3>This is Left Content in a Test Content Page</h3>'
  cp.main_content '<h1>Main Content for Test Content Page ROCKS!</h1>'
  cp.sort_order   1
  cp.url          '' # This would imply that the content was external.

end

Factory.define :content_partner do |cp|
  cp.auto_publish              false
  cp.association               :agent
  cp.description               'Our Testing Content Partner'
  cp.description_of_data       'Civil Protection!'
  cp.created_at                { 5.days.ago }
  cp.partner_seen_step         { 5.days.ago }
  cp.partner_complete_step     { 5.days.ago }
  cp.contacts_seen_step        { 5.days.ago }
  cp.contacts_complete_step    { 5.days.ago }
  cp.attribution_seen_step     { 5.days.ago }
  cp.attribution_complete_step { 5.days.ago }
  cp.roles_seen_step           { 5.days.ago }
  cp.roles_complete_step       { 5.days.ago }
  cp.ipr_accept                true
  cp.attribution_accept        true
  cp.roles_accept              true
  cp.show_on_partner_page      true
  cp.vetted                    false
end

Factory.define :content_section do |cs|
  cs.name { Factory.next(:string) }
end

Factory.define :curator_activity do |ca|
  ca.code { Factory.next(:string) }
end

Factory.define :curator_activity_log_daily do |cald|
  cald.association :user
end

Factory.define :curator_comment_log do |ccl|
  ccl.association :comment
  ccl.association :user
  ccl.association :curator_activity
end

Factory.define :curator_data_object_log do |cdol|
  cdol.association :data_object
  cdol.association :user
  cdol.association :curator_activity
end

Factory.define :data_object do |dato|
  dato.guid                   ''
  dato.association            :data_type
  dato.association            :mime_type
  dato.object_title           ''
  dato.association            :language
  dato.association            :license
  dato.rights_statement       ''
  dato.rights_holder          ''
  dato.bibliographic_citation ''
  dato.source_url             ''
  dato.description            'Test Data Object'
  dato.object_url             ''
  dato.object_cache_url       ''
  dato.thumbnail_url          ''
  dato.thumbnail_cache_url    ''
  dato.location               ''
  dato.latitude               0
  dato.longitude              0
  dato.altitude               0
  dato.object_created_at      { 5.days.ago }
  dato.object_modified_at     { 2.days.ago }
  dato.created_at             { 5.days.ago }
  dato.updated_at             { 3.days.ago }
  dato.data_rating            0.5
  dato.association            :vetted
  dato.association            :visibility
  dato.published              true
end

Factory.define :data_objects_harvest_event do |dohe|
  dohe.association :harvest_event
  dohe.association :data_object
  dohe.guid        { s = ''; 32.times { s += ((0..9).to_a.map{|n| n.to_s} + %w{a b c d e f}).rand }; s } # ICK!
  dohe.association :status
end

Factory.define :data_objects_table_of_content do |dato|
  dato.association :data_object
  dato.association :toc_item
end

Factory.define :data_objects_taxon do |dot|
  dot.identifier  ''
  dot.association :taxon
  dot.association :data_object
end

Factory.define :data_type do |dt|
  dt.schema_value 'http://purl.org/dc/dcmitype/ThisLinkWillFail.JustTesting'
  dt.label        { Factory.next(:string) }
end

Factory.define :harvest_event do |he|
  he.association :resource
  he.began_at     { 5.hours.ago }
  he.completed_at { 4.hours.ago }
  he.published_at { 3.hours.ago }
end

Factory.define :hierarchy do |hierarchy|
  hierarchy.label                   "A nested structure of divisions related to their probable evolutionary descent"
  hierarchy.url                     ''
  hierarchy.hierarchy_group_version 0
  hierarchy.hierarchy_group_id 1
  hierarchy.description             ''
  hierarchy.association             :agent
end

# TODO - This should probable assume you want some content, and build it.  Not sure, though.
Factory.define :hierarchies_content do |hc|
  hc.association    :hierarchy_entry
  hc.text           0
  hc.image          0
  hc.child_image    0
  hc.flash          0
  hc.youtube        0
  hc.internal_image 0
  hc.gbif_image     0
  hc.content_level  1
  hc.association    :image_object
end

Factory.define :hierarchy_entry do |he|
  he.remote_id        '' # This is an ID on the foreign web site, NOT in our DB.
  he.depth            2
  he.ancestry         ''
  he.lft              1
  he.rank_id          184
  he.parent_id        0
  he.association      :name
  he.association      :taxon_concept
  he.rgt              2
  he.identifier       ''
  he.association      :hierarchy
end

Factory.define :info_item do |ii|
  ii.schema_value 'http://rs.tdwg.org/ontology/voc/ThisWontWork.JustForTesting'
  ii.label        'TestInfoItem'
  ii.toc_id       1
end

Factory.define :item_page do |ip|
  ip.association :title_item
  ip.page_type ''
  ip.year        '1999'
  ip.volume      '2'
  ip.issue       '42'
  ip.prefix      'Page'
  ip.number      '6'
  ip.url         'http://www.biodiversitylibrary.org/page/ThisWontWork.JustTesting'
end

Factory.define :language do |l|
  l.iso_639_1    ''
  l.iso_639_2    ''
  l.iso_639_3    ''
  l.source_form  ''
  l.name         'Klingon'
  l.label        'kl'
end

Factory.define :license do |l|
  l.title       'Test License Type'
  l.description 'Rights?  What Rights?'
  l.source_url  ''
  l.version     0
  l.logo_url    ''
end

Factory.define :mapping do |m|
  m.association :collection
  m.association :name
  m.foreign_key 7357 # Arbitrary, off-site number
end

Factory.define :name do |name|
  name.italicized          '<i>Somethia specificus</i> Posford & R. Ram'
  name.canonical_form      {|cform| cform.association(:canonical_form, :string => 'Somethia specificus')}
  name.string              'Somethia specificus Posford & R. Ram'
  name.canonical_verified  0
  name.italicized_verified 0
  name.namebank_id         0
end

Factory.define :normalized_link do |nl|
  nl.association :normalized_name
  nl.association :name
  nl.seq         0
  nl.normalized_qualifier_id 1 # Identify which role the string is playing in the name (name, author, year)... but now is all name (1)
end

# This table exists, but there is no model for it and we aren't using it at the moment.
# Factory.define :normalized_qualifier do |nq|
# end

Factory.define :normalized_name do |nn|
  nn.name_part 'TestNormalizedName'
end

Factory.define :page_name do |pn|
  pn.association :name
  pn.association :item_page
end

Factory.define :publication_title do |pt|
  pt.short_title 'hello'
  pt.author  'bob'
  pt.call_number ''
  pt.end_year ''
  pt.start_year ''
  pt.language ''
  pt.marc_leader ''
  pt.abbreviation ''
  pt.marc_bib_id ''
  pt.title   'Test Publication Title'
  pt.details 'Nifty Titles Are Our Business'
  pt.url     'http://publication.titles.te.st'
end

# TODO - this should actually create a valid TC and use its information
Factory.define :random_taxon do |rt|
  rt.association   :language
  rt.association   :data_object
  rt.name_id       { Factory(:name).id } # TODO - ick.  ...But there is a "name" attribute as well, so, tricky.
  rt.image_url     200810081262788
  rt.name          '<i>Rodomicus fortesti<i> Factory TestFramework'
  rt.content_level 3
  rt.created_at    { 14.days.ago }
  rt.association   :taxon_concept
end

# I *don't* think these all actually relate to the rank_id's found elsewhere here. If so, we should change them to associations.
Factory.define :rank do |r|
  r.label 'TestRank'
end

Factory.define :resource_agent_role do |rar|
  rar.label { Factory.next(:string) }
end

Factory.define :resource do |r|
  r.auto_publish false
  r.title        'Testing Resource'
  r.subject      'Test Resource Subject'
  r.association  :license     
end

Factory.define :resources_taxon do |rt|
  rt.association       :taxon
  rt.association       :resource
  rt.identifier        ''
  rt.source_url        ''
  rt.taxon_created_at  { 5.hours.ago }
  rt.taxon_modified_at { 1.hours.ago }
end

Factory.define :role do |r|
  r.title 'TestRole'
end

Factory.define :roles_user do |ru|
  ru.association  :user
  ru.association  :role
end

Factory.define :search_suggestion do |ss|
  ss.term            'searchterm'
  ss.scientific_name 'TestSearchTerm ScientificName'
  ss.common_name     'TestSearchTerm CommonName'
  ss.language_label  'en'
  ss.image_url       '/images/eol_logo_header.png'
  ss.association     :taxon
  ss.sort_order      1
  ss.active          1
  ss.created_at      { 48.hours.ago }
end

Factory.define :status do |s|
  s.label { Factory.next(:string) }
end

Factory.define :synonym_relation do |sr|
  sr.label 'TestSynonymRelation'
end

# TODO - would be neat to make this relationship a synonym by default, but there's no nice way to do that yet
Factory.define :synonym do |s|
  s.association :name
  s.association :synonym_relation
  s.association :language
  s.association :hierarchy_entry
  s.preferred   0
  s.association :hierarchy   # This isn't really needed.
end

Factory.define :taxon do |t|
  t.guid          ''
  t.taxon_kingdom ''
  t.taxon_phylum  ''
  t.taxon_class   ''
  t.taxon_order   ''
  t.taxon_family  ''
  t.association   :name
  t.scientific_name ''
  t.association :hierarchy_entry
  t.created_at    { 48.hours.ago }
  t.updated_at    { 42.minutes.ago }
end

# We may want the default to actually have some content.  Not sure.
Factory.define :taxon_concept_content do |tcc|
  tcc.association :taxon_concept
  tcc.text           0
  tcc.image          0
  tcc.child_image    0
  tcc.flash          0
  tcc.youtube        0
  tcc.internal_image 0
  tcc.gbif_image     0
  tcc.content_level  1
  tcc.association    :image_object
end

Factory.define :taxon_concept do |tc|
  tc.published      0
  tc.supercedure_id 0
end

Factory.define :taxon_concept_name do |tcn|
  tcn.preferred              1
  tcn.vern                   0
  tcn.source_hierarchy_entry {|he| he.association(:hierarchy_entry) }
  tcn.association            :language
  tcn.association            :name
  tcn.association            :taxon_concept
end

Factory.define :title_item do |ti|
  ti.association  :publication_title
  ti.bar_code     '73577357735742'
  ti.marc_item_id 'i11604463' # I don't know what this is, but hey.
  ti.call_number  'QK1 .H38'
  ti.volume_info  '1864 v. 3'
  ti.url          'http://www.biodiversitylibrary.org/item/ThisWontWork.OnlyTesting'
end

Factory.define :toc_item do |ti|
  ti.association :parent
  ti.label       'TestTitleItem'
  ti.view_order  1 # This competes with Overview... not sure if this is wise.
end

Factory.define :top_image do |ti|
  ti.association :hierarchy_entry
  ti.association :data_object
  ti.view_order  1                 # Perhaps this should be in a sequence, but I don't want to figure out how to persist the same HE
end

Factory.define :top_unpublished_image do |tui|
  tui.association :hierarchy_entry
  tui.association :data_object
  tui.view_order  1 # Again, this should be sequential, but...
end

# Note - I started by making this guy approved for an associated HE... but the verdict_by clause had me worried about circular
# logic.
Factory.define :user do |u|
  u.default_taxonomic_browser 'text'
  u.expertise                 'middle'
  u.remote_ip                 '128.167.250.123' # TODO - fake this?
  u.content_level             2
  u.email                     { Factory.next(:email) }
  u.given_name                { Factory.next(:string) }
  u.family_name               { Factory.next(:string) }
  u.flash_enabled             true
  u.association               :language
  u.mailing_list              true
  u.vetted                    false
  u.username                  { Factory.next(:string) }
  u.active                    true
  u.entered_password          'test password'
  u.hashed_password           {|u| Digest::MD5.hexdigest(u.entered_password) }
  u.curator_hierarchy_entry   nil
  u.curator_approved          false
  u.curator_verdict_by_id     0
  u.curator_verdict_at        nil
end

# Creates all of the "default" vaules the app counts on.
class Factory
  def self.prerequisites
    ContactSubject.generate # There just needs to be one of these, doesn't matter which.
    ContentPage.generate :page_name => 'Home', :language_abbr => 'en'
  end
end

### will sort these ... so many factories!  split into 1 file per factory?
#
# the following all need work, i just wanna get rid of the 'no such factory' messages
#

Factory.define :visibility do |x|
  x.label { Factory.next(:string) }
end

Factory.define :vetted do |x|
  x.label { Factory.next(:string) }
end

Factory.define :mime_type do |x|
  x.label { Factory.next(:string) }
end

Factory.define :agent_role do |x|
  x.label { Factory.next(:string) }
end

Factory.define :data_object_tags do |x|
  x.association :data_object
  x.association :data_object_tag
end

Factory.define :data_object_tag do |x|
  x.key   { Factory.next(:string) }
  x.value { Factory.next(:string) }
end

Factory.define :comment do |x|
  x.association :parent, :factory => :data_object
  x.parent_type 'data_object'
  x.body { Factory.next(:string) }
  x.association :user
end

Factory.define :log_daily do |x|
  x.day Date.today
  x.total 0
  x.user_agent 'Cool/Browser'
  x.association :data_type
end

Factory.define :contact do |x|
  x.name { Factory.next(:string) }
  x.email { Factory.next(:email) }
  x.association :contact_subject
  x.comments %w( foo bar )
end

Factory.define :contact_subject do |x|
  x.title { Factory.next(:string) }
  x.recipients { Factory.next(:string) }
end
