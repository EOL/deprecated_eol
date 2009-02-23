# REMINDER: default model factories, eg. :user, should *only* generate required fields
#
# If you want a model loaded up with all kinds of goodies, make a different generator, 
# eg. :admin_user
#
# We will make helpers for easily generating User.gen_admin (or something like this)

require 'factory_girl'
require 'faker'
require File.dirname(__FILE__) + '/eol_factory_girl'

#### Faker extensions

module Faker
  class Eol
    class << self

      def iucn 
        @rand_iucn ||= 
          ["Extinct (EX)",
           "Data Deficient (DD)",
           "Endangered (EN)",
           "Vulnerable (VU)",
           "Critically Endangered (CR)",
           "Near Threatened (NT)",
           "Least Concern (LC)",
           "Conservation Dependent (LR/cd)",
           "Extinct in the Wild (EW)"]
        @rand_iucn.rand
      end

      def flash
        @rand_flash ||=

          [200811131313601, 200811131321659, 200811131394659, 200811131367814, 200811131351121, 200811131388288, 200811131382797,
           200811131390600, 200811131333916, 200811131393000, 200811131347554, 200811131354820, 200811131391764, 200811131316882,
           200811131328300, 200811131392039, 200811131350808, 200811131333809, 200811131349975, 200811131317614, 200811131356003,
           200811131372942, 200811131393363, 200811131382901, 200811131355461, 200811131374742, 200811131356635, 200811131314704,
           200811131368751, 200811131374919, 200811131316328, 200811131309151, 200811131331207, 200811131310763]
       
        @rand_flash.rand
      end

      # These are object_url values, not object_cache_url:
      def youtube
        @rand_youtube ||=
          ["http://www.youtube.com/v/tawTDADXvuM", "http://www.youtube.com/v/Sk1FhlPeQH8", "http://www.youtube.com/v/ymTMrg7G4Ac"]
        @rand_youtube.rand
      end

      def map
        @rand_maps ||=

          [200810061219436, 200810061209958, 200810061282237, 200810061249555, 200810061295422, 200810061292832, 200810061231652,
           200810061214882, 200810061250755, 200810061227362, 200810061280963, 200810061298041, 200810061213284, 200810061290224,
           200810061293016, 200810061218537, 200810061224789, 200810061224342, 200810061264532, 200810061216335, 200810061294639,
           200810061211122, 200810061263547, 200810061298462, 200810061200179, 200810061273468, 200810061292281, 200810061259245,
           200810061202485, 200810061204444, 200810061272703, 200810061216439, 200810061201431, 200810061269510, 200810061242300,
           200810061288475, 200810061262912, 200810061256410, 200810061227505, 200810061256081, 200810061253117, 200810061293278,
           200810061277103, 200810061249867, 200810061290276, 200810061282392, 200810061230700, 200810061203881, 200810061268421,
           200810061235291, 200810061204473, 200810061220593, 200810061247769, 200810061244546, 200810061223997, 200810061266983,
           200810061209409, 200810061288809, 200810061290506, 200810061223649, 200810061240716, 200810061234907, 200810061204262,
           200810061295992, 200810061271122, 200810061218963, 200810061248056, 200810061275954, 200810061214325, 200810061244427,
           200810061230338, 200810061219522, 200810061271459, 200810061228261, 200810061265370]  

        @rand_maps.rand
      end

      def image
        @rand_images ||=

          [200810061400963, 200812102286938, 200901131511113, 200810061535996, 200810061235832, 200810070724291, 200810070393325,
           200810061499033 , 200810061956645, 200901081611403, 200902021821277, 200901081525790, 200810070370443, 200810081234383,
           200901091228271, 200810061332994 , 200810070196948, 200810070198474, 200810070110656, 200810070121645, 200810070114461,
           200810070194482, 200810070166698, 200810070149808, 200810070149109, 200810070154921, 200810070194790, 200810070159641,
           200810070134999, 200810070120198, 200810070145257, 200810070184502, 200810070142968, 200810070166596, 200810070180055,
           200810070142875, 200810070115930, 200810070100604, 200810070118622, 200810070175265, 200810070100713, 200810070111003,
           200810070137681, 200810070164545, 200810070157916, 200810070122730, 200810070199754, 200810070167455, 200810070100654,
           200810070118954, 200810070118167, 200810070157819, 200810070199720, 200810070104387, 200810070146375, 200810070152793,
           200810070157267, 200810070119570, 200810070113912, 200810070113135, 200810070142243, 200810070180189, 200810070180684,
           200810070165886, 200810070137554, 200810070133742, 200810070125665, 200810070194814, 200810070197245, 200810070194444,
           200810070118073, 200810070166521, 200810070161808, 200810070157324, 200810070197865, 200810070124003, 200810070142408,
           200810070132172, 200810070160538, 200810070161438, 200810070162825, 200810070143572, 200810070114867, 200810070150091,
           200810070120475, 200810070154554, 200810070111162, 200810070138367, 200810070186358, 200810070182662, 200810070193189,
           200810070192803, 200810070148053, 200810070124403, 200810070188722, 200810070182637, 200810070148142, 200810070109427,
           200810070175607, 200810070112316, 200810070146646, 200810070130989, 200810070140298, 200810070119087, 200810070137167,
           200810070160300, 200810070120121, 200810070104136, 200810070131232, 200810070141074, 200810070180214, 200810070177861,
           200810070183649, 200810070117352, 200810070188875, 200810070156209, 200810070169248, 200810070106471, 200810070174163,
           200810070167109, 200810070125257, 200810070151863, 200810070195716, 200810070137363, 200810070167595, 200810070130304,
           200810070111254, 200810070191748, 200810070158274, 200810070183345, 200810070122451, 200810070144956, 200810070112592,
           200810070128558, 200810070186149, 200810070127621, 200810070147911, 200810070143782, 200810070182880, 200810070174026,
           200810070155541, 200810070182689, 200810070173016, 200810070189683, 200810070149351]

        @rand_images.rand
      end

      def name_part
        part = Faker::Lorem.words(1)[0]
        part += Faker::Lorem.words(1)[0] if part.length < 4
        part += %w{i a ii us is iae erox eron eri alia eli esi alia elia ens ica ator atus erus ensis alis alius osyne eles es ata}.rand
      end

      def scientific_name
        "#{Faker::Eol.name_part.titleize} #{Faker::Eol.name_part}"
      end

      def common_name
        ['common', "#{Faker::Name.first_name}'s", 'blue', 'red', 'pink', 'green', 'purple',
         'painted', 'spiny', 'agitated', 'horny', 'blessed', 'sacred', 'sacrimonious', 'naughty',
         'litte', 'tiny', 'giant', 'great', 'lesser', 'least', 'river', 'plains', 'city', 'sky', 'stream',
         'thirsty', 'ravenous', 'bloody', 'cursed', 'cromulent'].rand + ' ' + Faker::Eol.name_part
      end

      def attribution
        "#{Faker::Name.first_name[0..0]}. #{Faker::Name.last_name}"
      end

    end
  end
end

#### Sequences

Factory.sequence(:string ){|n| "unique#{ n }string" } # 'string' isn't elegant, but it's perfect for right now!
Factory.sequence(:email  ){|n| "bob#{n}@smith.com" }
# Faker names are frequently unique, but let's just make absolutely sure:
Factory.sequence(:name   ){|n| "#{Faker::Name.first_name}#{n} #{Faker::Name.last_name}" }
Factory.sequence(:species){|n| "#{Faker::Lorem.words[0]}#{n} #{Faker::Lorem.words[0]}" }
Factory.sequence(:title  ){|n| "#{n} " + Faker::Lorem.words(rand(3)+1).map(&:titleize).join(' ') }
Factory.sequence(:int    ){|n| n }

#### Factories

Factory.define :agent do |agent|
  agent.created_at      { 5.days.ago }
  agent.homepage        ''
  agent.full_name       { Factory.next(:name) }
  agent.username        {|a| a.full_name.gsub(/\W+/, '').downcase[0..15] }
  agent.email           { Factory.next(:email) }
  agent.hashed_password { Digest::MD5.hexdigest('test password') }
  agent.association     :agent_status
end

Factory.define :agent_contact do |ac|
  ac.association :agent
  ac.association :agent_contact_role
  ac.given_name  { Factory.next(:string) }
  ac.family_name { Factory.next(:string) }
  ac.full_name   {|a| "#{a.first_name} #{a.last_name}" }
  ac.email       {|a| "#{a.first_name}.#{a.last_name}@example.com".downcase }
  ac.homepage    'http://whatever.org'
  ac.address     '1234 Doesntmatter St'
  ac.title       'Call me SIR'
  ac.telephone   '555-222-1111'
end

Factory.define :agent_contact_role do |x|
  x.label { Factory.next(:string) }
end

Factory.define :agent_data_type do |x|
  x.label { Factory.next(:string) }
end

Factory.define :agent_role do |x|
  x.label { Factory.next(:string) }
end

Factory.define :agent_status do |as|
  as.label { Factory.next(:string) }
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

Factory.define :audience do |a|
  a.label { Factory.next(:string) }
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

Factory.define :comment do |x|
  x.association :parent, :factory => :data_object
  x.parent_type 'data_object'
  x.body { Faker::Lorem.paragraph }
  x.association :user
end

Factory.define :contact do |c|
  c.name { Factory.next(:string) }
  c.email { Factory.next(:email) }
  c.association :contact_subject
  c.comments %w( foo bar )
end

Factory.define :contact_subject do |cs|
  cs.title { Factory.next(:string) }
  cs.recipients { Factory.next(:string) }
  cs.active     true
  cs.created_at { 48.hours.ago }
  cs.updated_at { 48.hours.ago }
end

Factory.define :content_page do |cp|
  cp.association :content_section
  cp.language_abbr 'en'
  cp.title         'Test Content Page'
  cp.page_name     {|cp| cp.title }
  cp.left_content  {|cp| "<h3>This is Left Content in a #{cp.title}</h3>" }
  cp.main_content  {|cp| "<h1>Main Content for #{cp.title} ROCKS!</h1>" }
  cp.sort_order    1
  cp.url           '' # This would imply that the content was external.
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
  cs.language_key 'en'
end

Factory.define :curator, :class => User do |u|
  u.default_taxonomic_browser 'text'
  u.expertise                 'middle'
  u.remote_ip                 '128.167.250.123' # TODO - fake this?
  u.content_level             2
  u.email                     { Factory.next(:email) }
  u.given_name                { Faker::Name.first_name }
  u.family_name               { Faker::Name.last_name }
  u.flash_enabled             true
  u.association               :language
  u.mailing_list              true
  u.vetted                    true
  u.username                  {|user| "#{user.given_name[0..0]}_#{user.family_name[0..9]}#{Factory.next(:int)}".gsub(/\s/, '_').downcase }
  u.active                    true
  u.entered_password          'test password'
  u.hashed_password           {|user| Digest::MD5.hexdigest(user.entered_password) }
  u.curator_hierarchy_entry   { Factory(:hierarchy_entry) }
  u.curator_approved          true
  u.curator_verdict_by        { Factory(:user) }
  u.curator_verdict_at        { 48.hours.ago }
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

Factory.define :data_object_tag do |x|
  x.key   { Factory.next(:string) }
  x.value { Factory.next(:string) }
end

Factory.define :data_object_tags do |x|
  x.association :data_object
  x.association :data_object_tag
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
  dot.association :taxon
  dot.association :data_object
  dot.identifier  '' # No idea what this is supposed to be, but it cannot be nil
end

Factory.define :data_type do |dt|
  dt.schema_value ''
  dt.label        { Factory.next(:string) }
end

Factory.define :harvest_event do |he|
  he.association :resource
  he.began_at     { 5.hours.ago }
  he.completed_at { 4.hours.ago }
  he.published_at { 3.hours.ago }
end

Factory.define :harvest_events_taxon do |het|
  het.association :harvest_event
  het.association :taxon
  het.guid        ''
  het.association :status
end

Factory.define :hierarchy do |hierarchy|
  hierarchy.label                   "A nested structure of divisions related to their probable evolutionary descent"
  hierarchy.url                     ''
  hierarchy.hierarchy_group_version 0
  hierarchy.hierarchy_group_id      1
  hierarchy.description             ''
  hierarchy.association             :agent
end

Factory.define :hierarchies_content do |hc|
  hc.association     :hierarchy_entry
  hc.text            0
  hc.image           0
  hc.child_image     0
  hc.flash           0
  hc.youtube         0
  hc.internal_image  0
  hc.gbif_image      0
  hc.content_level   1
  hc.image_object_id 0 # the preferred image for that hierarchy_entry, but probably not used (still, accurate in production)
end

Factory.define :hierarchy_entry do |he|
  he.remote_id   '' # This is an ID on the foreign web site, NOT in our DB.
  he.depth       2
  he.ancestry    ''
  he.lft         1
  he.rank_id     184
  he.parent_id   0
  he.association :name
  he.association :taxon_concept
  he.rgt         2
  he.identifier  ''
  he.association :hierarchy
end

Factory.define :info_item do |ii|
  ii.schema_value 'http://rs.tdwg.org/ontology/voc/ThisWontWork.JustForTesting'
  ii.label        'TestInfoItem'
  ii.toc_id       0
end

Factory.define :ip_address do |ip|
  ip.number { Factory.next(:int) }
  ip.success false
  ip.provider 'i have no idea what this is'
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
  l.source_form  ''
  l.name         'Klingon'
  l.label        {|lang| lang.name[0..1].downcase }
  l.iso_639_1    {|lang| lang.name[0..1].downcase }
  l.iso_639_2    {|lang| lang.name[0..2].downcase }
  l.iso_639_3    {|lang| lang.name[0..3].downcase }
  l.activated_on { 5.hours.ago }
  l.sort_order   { Factory.next(:int) }
end

Factory.define :license do |l|
  l.title                    'Test License Type'
  l.description              'Rights?  What Rights?'
  l.source_url               ''
  l.version                  0
  l.logo_url                 ''
  l.show_to_content_partners true
end

Factory.define :log_daily do |x|
  x.day Date.today
  x.total 0
  x.user_agent 'Cool/Browser'
  x.association :data_type
end

Factory.define :mapping do |m|
  m.association :collection
  m.association :name
  m.foreign_key 7357 # Arbitrary, off-site number
end

Factory.define :mime_type do |x|
  x.label { Factory.next(:string) }
end

Factory.define :name do |name|
  name.canonical_form      {|cform| cform.association(:canonical_form, :string => 'Somethia specificus')}
  name.string              { Factory.next(:species) }
  name.canonical_verified  0 # I don't know that Rails ever uses this...
  name.italicized_verified 0 # I don't know that Rails ever uses this...
  # The strip  at the end handles strings that are only two words; it is useless with three or more.
  name.italicized          {|n| n.string.split[0] == n.string ? "<i>#{n.string}</i>" : ('<i>' + n.string.split[0..1].join(' ') + '</i> ' +  n.string.split[2..-1].join(' ')).strip }
  name.namebank_id         0
end

Factory.define :news_item do |ni|
  ni.body         { 'Test News Item Body' + Faker::Lorem.paragraph }
  ni.title        { Faker::Lorem.words[rand(4) + 1].titleize }
  ni.display_date { 2.days.ago }
  ni.activated_on { 2.days.ago }
  ni.association  :user
  ni.active       1
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

Factory.define :random_taxon do |rt|
  rt.association    :language
  rt.association    :data_object
  rt.name_id        { Factory(:name).id } # TODO - ick.  ...But there is a "name" attribute as well, so, tricky.
  rt.image_url      200810081262788
  rt.name           { "<i>#{ Factory.next(:species) }<i> Factory TestFramework" }
  rt.content_level  3
  rt.created_at     { 14.days.ago }
  rt.association    :taxon_concept
  rt.common_name_en {|taxon| Factory.next(:species) + ' (test common name)'}
  rt.common_name_fr {|taxon| Factory.next(:species) + ' (pretend this is French)'}
  rt.thumb_url      200810061400963 # Not sure this is right.
end

# I *don't* think these all actually relate to the rank_id's found elsewhere here. If so, we should change them to associations.
Factory.define :rank do |r|
  r.label 'TestRank'
  r.rank_group_id 0
end

Factory.define :ref_identifier_type do |rit|
  rit.label { Factory.next(:string) }
end

# TODO - Patrick might be adding a hierarchy reference to this table.
Factory.define :resource do |r|
  r.auto_publish    false
  r.title           'Testing Resource'
  r.subject         'Test Resource Subject'
  r.association     :license
  r.association     :resource_status
  r.accesspoint_url 'http://www.google.com' # Won't work without a real, live URL.
end

Factory.define :resource_agent_role do |rar|
  rar.label { Factory.next(:string) }
end

Factory.define :resource_status do |rs|
  rs.label { Factory.next(:string) }
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

Factory.define :service_type do |s|
  s.label { Factory.next(:string) }
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

Factory.define :taxon_concept do |tc|
  tc.association    :vetted
  tc.published      1
  tc.supercedure_id 0
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

Factory.define :taxon_concept_name do |tcn|
  tcn.preferred              true
  tcn.vern                   false
  tcn.source_hierarchy_entry {|he| he.association(:hierarchy_entry) } # Does this work?
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
  ti.parent_id   0
  ti.label       { Factory.next(:title) }
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

Factory.define :user do |u|
  u.default_taxonomic_browser 'text'
  u.expertise                 'middle'
  u.remote_ip                 '128.167.250.123' # TODO - fake this?
  u.content_level             2
  u.email                     { Factory.next(:email) }
  u.given_name                { Faker::Name.first_name }
  u.family_name               { Faker::Name.last_name }
  u.flash_enabled             true
  u.association               :language
  u.mailing_list              true
  u.vetted                    false
  u.username                  {|user| "#{user.given_name[0..0]}_#{user.family_name[0..9]}#{Factory.next(:int)}".gsub(/\s/, '_').downcase }
  u.active                    true
  u.entered_password          'test password'
  u.hashed_password           {|user| Digest::MD5.hexdigest(user.entered_password) }
  u.curator_hierarchy_entry   nil
  u.curator_approved          false
  u.curator_verdict_by_id     0
  u.curator_verdict_at        nil
end

Factory.define :vetted do |x|
  x.label { Factory.next(:string) }
end

Factory.define :visibility do |x|
  x.label { Factory.next(:string) }
end
