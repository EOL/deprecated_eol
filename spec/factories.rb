# REMINDER: default model factories, eg. :user, should *only* generate required field s
#
# If you want a model loaded up with all kinds of goodies, make a different generator,
# eg. :admin_user

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

          [200811131313601, 200811131321659, 200811131394659, 200811131367814, 200811131351121, 200811131388288,
            200811131382797, 200811131390600, 200811131333916, 200811131393000, 200811131347554, 200811131354820,
            200811131391764, 200811131316882, 200811131328300, 200811131392039, 200811131350808, 200811131333809,
            200811131349975, 200811131317614, 200811131356003, 200811131372942, 200811131393363, 200811131382901,
            200811131355461, 200811131374742, 200811131356635, 200811131314704, 200811131368751, 200811131374919,
            200811131316328, 200811131309151, 200811131331207, 200811131310763]

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
           200810061499033, 200810061956645, 200901081611403, 200902021821277, 200901081525790, 200810070370443, 200810081234383,
           200901091228271, 200810061332994, 200810070196948, 200810070198474, 200810070110656, 200810070121645, 200810070114461,
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
        ['common', "#{Factory.next(:first_name)}'s", 'blue', 'red', 'pink', 'green', 'purple',
         'painted', 'spiny', 'agitated', 'horny', 'blessed', 'sacred', 'sacrimonious', 'naughty',
         'litte', 'tiny', 'giant', 'great', 'lesser', 'least', 'river', 'plains', 'city', 'sky', 'stream',
         'thirsty', 'ravenous', 'bloody', 'cursed', 'cromulent'].rand + ' ' + Faker::Eol.name_part
      end

      def attribution
        "#{Factory.next(:first_name)[0..0]}. #{Factory.next(:last_name)}"
      end

    end
  end
end

#### Sequences

# Not unique, of course:
Factory.sequence(:iucn) do |n|
  @seq_iucn = ["Extinct (EX)", "Data Deficient (DD)", "Endangered (EN)", "Vulnerable (VU)", "Critically Endangered (CR)", "Near Threatened (NT)", "Least Concern (LC)", "Conservation Dependent (LR/cd)", "Extinct in the Wild (EW)"]
  @seq_iucn[n % @seq_iucn.length]
end

# Not unique:
Factory.sequence(:flash) do |n|
  @seq_flash =
    [200811131313601, 200811131321659, 200811131394659, 200811131367814, 200811131351121, 200811131388288, 200811131382797,
     200811131390600, 200811131333916, 200811131393000, 200811131347554, 200811131354820, 200811131391764, 200811131316882,
     200811131328300, 200811131392039, 200811131350808, 200811131333809, 200811131349975, 200811131317614, 200811131356003,
     200811131372942, 200811131393363, 200811131382901, 200811131355461, 200811131374742, 200811131356635, 200811131314704,
     200811131368751, 200811131374919, 200811131316328, 200811131309151, 200811131331207, 200811131310763]
  @seq_flash[n % @seq_flash.length]
end

# Not unique:
Factory.sequence(:youtube) do |n|
  @seq_youtube = ["http://www.youtube.com/v/tawTDADXvuM",
                  "http://www.youtube.com/v/Sk1FhlPeQH8",
                  "http://www.youtube.com/v/ymTMrg7G4Ac"]
  @seq_youtube[n % @seq_youtube.length]
end

# Not unique:
Factory.sequence(:sound) do |n|
  @seq_sound =
    [201105040549843, 201105040554365, 201105040529974, 201105040538097, 201105040535175, 201105040549841,
     201105040560889, 201105040555104, 201105040573195, 201105040594149]
  @seq_sound[n % @seq_sound.length]
end

# Not unique:
Factory.sequence(:map) do |n|
  @seq_map =
    [200810061219436, 200810061209958, 200810061282237, 200810061249555, 200810061295422, 200810061292832,
      200810061231652, 200810061214882, 200810061250755, 200810061227362, 200810061280963, 200810061298041,
      200810061213284, 200810061290224, 200810061293016, 200810061218537, 200810061224789, 200810061224342,
      200810061264532, 200810061216335, 200810061294639, 200810061211122, 200810061263547, 200810061298462,
      200810061200179, 200810061273468, 200810061292281, 200810061259245, 200810061202485, 200810061204444,
      200810061272703, 200810061216439, 200810061201431, 200810061269510, 200810061242300, 200810061288475,
      200810061262912, 200810061256410, 200810061227505, 200810061256081, 200810061253117, 200810061293278,
      200810061277103, 200810061249867, 200810061290276, 200810061282392, 200810061230700, 200810061203881,
      200810061268421, 200810061235291, 200810061204473, 200810061220593, 200810061247769, 200810061244546,
      200810061223997, 200810061266983, 200810061209409, 200810061288809, 200810061290506, 200810061223649,
      200810061240716, 200810061234907, 200810061204262, 200810061295992, 200810061271122, 200810061218963,
      200810061248056, 200810061275954, 200810061214325, 200810061244427, 200810061230338, 200810061219522,
      200810061271459, 200810061228261, 200810061265370]
  @seq_map[n % @seq_map.length]
end

# Not unique:
Factory.sequence(:image) do |n|
  @seq_images ||=
    [200810061400963, 200812102286938, 200901131511113, 200810061535996, 200810061235832, 200810070724291,
     200810070393325, 200810061499033, 200810061956645, 200901081611403, 200902021821277, 200901081525790,
     200810070370443, 200810081234383, 200901091228271, 200810061332994, 200810070196948, 200810070198474,
     200810070110656, 200810070121645, 200810070114461, 200810070194482, 200810070166698, 200810070149808,
     200810070149109, 200810070154921, 200810070194790, 200810070159641, 200810070134999, 200810070120198,
     200810070145257, 200810070184502, 200810070142968, 200810070166596, 200810070180055, 200810070142875,
     200810070115930, 200810070100604, 200810070118622, 200810070175265, 200810070100713, 200810070111003,
     200810070137681, 200810070164545, 200810070157916, 200810070122730, 200810070199754, 200810070167455,
     200810070100654, 200810070118954, 200810070118167, 200810070157819, 200810070199720, 200810070104387,
     200810070146375, 200810070152793, 200810070157267, 200810070119570, 200810070113912, 200810070113135,
     200810070142243, 200810070180189, 200810070180684, 200810070165886, 200810070137554, 200810070133742,
     200810070125665, 200810070194814, 200810070197245, 200810070194444, 200810070118073, 200810070166521,
     200810070161808, 200810070157324, 200810070197865, 200810070124003, 200810070142408, 200810070132172,
     200810070160538, 200810070161438, 200810070162825, 200810070143572, 200810070114867, 200810070150091,
     200810070120475, 200810070154554, 200810070111162, 200810070138367, 200810070186358, 200810070182662,
     200810070193189, 200810070192803, 200810070148053, 200810070124403, 200810070188722, 200810070182637,
     200810070148142, 200810070109427, 200810070175607, 200810070112316, 200810070146646, 200810070130989,
     200810070140298, 200810070119087, 200810070137167, 200810070160300, 200810070120121, 200810070104136,
     200810070131232, 200810070141074, 200810070180214, 200810070177861, 200810070183649, 200810070117352,
     200810070188875, 200810070156209, 200810070169248, 200810070106471, 200810070174163, 200810070167109,
     200810070125257, 200810070151863, 200810070195716, 200810070137363, 200810070167595, 200810070130304,
     200810070111254, 200810070191748, 200810070158274, 200810070183345, 200810070122451, 200810070144956,
     200810070112592, 200810070128558, 200810070186149, 200810070127621, 200810070147911, 200810070143782,
     200810070182880, 200810070174026, 200810070155541, 200810070182689, 200810070173016, 200810070189683,
     200810070149351]
  @seq_images[n % @seq_images.length]
end

Factory.sequence(:year) do |n|
  1990 + n
end

Factory.sequence(:month) do |n|
  (n % 12) + 1
end

# Unique:
Factory.sequence(:guid) do |n|
  @guids = ['3a117abf96e7fe8793ef87b14d166d5f', 'a509ebdb2fc8083f3a33ea17985bad42']
  pick = @guids[n % @guids.length]
  (n / @guids.length).times { pick.succ! }
  pick
end

# Unique:
Factory.sequence(:scientific_name) do |n|
  @seq_sci_name = ["Quibusdameli estculpaatus", "Estasperioreseli etquidemis", "Nesciunterox autrerumalis",
    "Voluptasalius optioerus", "Remrerumeron auteterus", "Veritatises idofficiisiae", "Accusamusalis pariatura",
    "Voluptateseri doloremosyne", "Autrecusandaees repudiandaeica", "Nihileri voluptasus", "Dignissimosii inutes",
    "Fugais utharumatus", "Minuseli ullamens", "Dignissimosatus nobisosyne", "Expeditaalia evenietelia", "Earumeles
    beataeata", "Culpaensis sapienteesi", "Utomnisesi sequialis", "Autaliquideri minimais", "Beataeelia etnemoiae",
    "Autema officiaalius", "Autemalius utsimiliqueesi", "Etconsequaturelia autenimalia", "Quoautesi natuseri",
    "Voluptatumeri esseensis", "Ameti maioresis", "Ipsamalius distinctioerox", "Maximees veritatisatus", "Molestiaeus
    rationealia", "Fugitens dolorealius", "Quisquamator sequieles", "Essees eaqueata", "Animiens atdoloribuseron",
    "Adaliasii iurea", "Nonnumquamerus numquamerus", "Autvoluptatesus temporaalis", "Excepturialia omnisa",
    "Estveroalia nihilata", "Quiincidunta culpaelia", "Providentalia estquaeratens", "Placeatalia uteosensis",
    "Ipsaensis architectoalius", "Deserunterox facererox", "Suntalia estsitalius", "Aliasosyne quiadipisciatus",
    "Illoica exexplicaboalia", "Laboriosamerus quisis", "Optiois molestiasalia", "Ipsuma animius", "Quiserox
    eligendii", "Eteaiae nullais"]
  pick = @seq_sci_name[n % @seq_sci_name.length]
  (n / @seq_sci_name.length).times { pick.succ! }
  pick
end

# Unique:
Factory.sequence(:common_name) do |n|
  @seq_common_name = ["pink quaist", "ravenous clover", "red suntus", "darning needle", "tiger", "frizzlebek",
    "purple dust crab", "cloud swallow", "spiny possom", "common desert mouse", "fisher", "chartruse turtle", "horny
    toad", "scarlet vermillion", "Mozart's nemesis", "quick brown fox", "painted horse", "thirsty aphid", "bloody
    eel", "fruit bat", "giant ostrich", "common rat", "cursed doormouse", "great shrimp", "stream newt", "blessed
    sparrow", "ravenous eagle", "common titmouse", "least ferret", "raccoon", "papa bear", "brown hornet", "urban
    crocidile", "classical enthusiast", "grungebutter", "bripplefoam frond", "elf's cup", "agitated harmonium", "stone
    dragon", "Werner's mite", "green anole", "killer bee", "thistle", "paramecium", "scorpion king", "tarantula",
    "cardinal", "moon fungus", "upbeat chickadee", "amoeba"]
  pick = @seq_common_name[n % @seq_common_name.length]
  (n / @seq_common_name.length).times { pick.succ! }
  pick
end

# Unique:
Factory.sequence(:last_name) do |n|
  @seq_last_name = ["Cronin", "Reinger", "Jacobs", "Crona", "Parisian", "Bergstrom", "Rhys", "Murphy", "Connelly",
    "Runolfsson", "Ernser", "Nolan", "Mosciski", "Larkin", "Willms", "Deckow", "Stracke", "Deckow", "Na", "Torphy",
    "Mills", "Pollich", "Beatty", "Hettinger", "Okuneva", "Olson", "West", "Schowalter", "Hill", "Schneider",
    "McCullough", "Schamberger", "Bode", "Stehr", "Kuhic", "Wisozk", "Hansen", "Spencer", "Eichmann", "Corwin",
    "Rolfson", "Keller", "Toy", "Ankunding", "Beatty", "Botsford", "Mann", "Ankunding", "Leuschke", "Senger",
    "Luettgen", "Lubowitz", "Welch", "Harvey", "Schultz", "Keebler", "Hudson", "Leffler", "Gleason", "Schmidt",
    "Skiles", "Gleason", "Cummerata", "Stamm", "Beier", "Dickens", "Kulas", "Franecki", "Kuhic", "Padberg", "Haley",
    "Gorczany", "Hoeger"]
  pick = @seq_last_name[n % @seq_last_name.length]
  (n / @seq_last_name.length).times { pick.succ! }
  pick
end

# Unique:
Factory.sequence(:first_name) do |n|
  @seq_first_name = ["Sean", "Janie", "Helmer", "Fiona", "Spencer", "Camren", "Ahmad", "Roxane", "Mariana",
    "Joshuah", "Antonia", "Eugene", "Kaitlin", "Otho", "Camila", "Colt", "Mathew", "Electa", "Damaris", "Aidan",
    "Dora", "Emmanuelle", "Sam", "Betty", "Reuben", "Ashley", "Vicente", "Heber", "Maybell", "Okey", "Leonardo",
    "Gerhard", "Cicero", "Maritza", "Alvah", "Wyatt", "Ming", "Shane", "Benton", "George", "Chanel", "Rosalia",
    "Christie", "Madelynn", "Jeramie", "Lavada", "Kailey", "Duane", "Herbert", "Rolfe", "Kali", "Jacky", "Marilie",
    "Jon", "Rachel", "Scot", "Rhea", "Greta", "Dameon", "Rasheed", "Bertrand"]
  pick = @seq_first_name[n % @seq_first_name.length]
  (n / @seq_first_name.length).times { pick.succ! }
  pick
end

# Not Unique (obviously, given the repetition in the array):
Factory.sequence(:attribution) do |n|
  @seq_attr = ["L.", "Linn.", "Linnaeus", "G. D'Amore", "R. Bergstrom", "L.", "Linn", "R. Cartwright", "L.", "Linn.", "Linnaeus", "N. Upton", "L. Carroll", "M. Port", "S. Posford", "Posford & Ram", "L.", "Linnaeus", "", "P. Leary", "Padderson", "Linnaeus", "L.", "M. Mayer"]
  @seq_attr[n % @seq_attr.length]
end

Factory.sequence(:string ){|n| "unique#{ n }string" }
Factory.sequence(:email  ){|n| "bob#{n}@smith.com" }
# Faker names are frequently unique, but let's just make absolutely sure:
Factory.sequence(:species) do |n|
  s = Factory.next(:scientific_name)
  while (Name.find_by_string(s)) do
    s = Factory.next(:scientific_name)
  end
  s
end
Factory.sequence(:title  ){|n| "#{n} " + Faker::Lorem.words(rand(3)+1).map(&:titleize).join(' ') }
Factory.sequence(:int    ){|n| n }

#### Factories

Factory.define :activity do |a|
end

Factory.define :agent do |agent|
  agent.created_at      { 5.days.ago }
  agent.homepage        ''
  agent.full_name       { Factory.next(:first_name) << ' ' << Factory.next(:last_name) }
end
Factory.define :content_partner_contact do |cpc|
  cpc.association :content_partner
  cpc.association :contact_role
  cpc.given_name  { Factory.next(:string) }
  cpc.family_name { Factory.next(:string) }
  cpc.full_name   {|a| "#{a.given_name} #{a.family_name}" }
  cpc.email       {|a| "#{a.given_name}.#{a.family_name}@example.com".downcase }
  cpc.homepage    'http://whatever.org'
  cpc.address     '1234 Doesntmatter St'
  cpc.title       'Call me SIR'
  cpc.telephone   '555-222-1111'
end

Factory.define :contact_role do |x|
end

Factory.define :content_partner_data_type do |x|
end

Factory.define :agent_role do |x|
end

Factory.define :content_partner_status do |cps|
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

Factory.define :audience do |a|
end

Factory.define :canonical_form do |cform|
  cform.string { Factory.next(:species) }
end

Factory.define :collection do |l|
  l.name                  { Factory.next(:string) }
  l.published             false
  l.special_collection_id nil
  l.association           :user
end

Factory.define :collection_activity_log do |cal|
  cal.association :user
  cal.association :collection
  cal.activity    { Activity.create }
  cal.created_at  { 5.days.ago }
end

Factory.define :collection_type do |ct|
  ct.parent_id  0
  ct.lft        0
  ct.rgt        0
end

Factory.define :collection_types_hierarchy do |cth|
  cth.association :collection_type
  cth.association :hierarchy
end

# NOTE - the Comment model has some validations on it (create/update/etc) that will fail if you don't have a loaded
# database, so don't expect this factory to work in all situations.
Factory.define :comment do |x|
  x.association  :parent, :factory => :data_object
  x.parent_type  'data_object'
  x.body         { Faker::Lorem.paragraph }
  x.association  :user
  x.from_curator false
end

Factory.define :community do |c|
  c.name        { Faker::Lorem.words.join(' ').titleize }
  c.description { Faker::Lorem.paragraph }
  c.show_special_privileges false
end

Factory.define :community_activity_log do |cal|
  cal.association :user
  cal.association :community
  cal.activity    { Activity.create }
  cal.created_at  { 5.days.ago }
end

Factory.define :contact do |c|
  c.name            { Factory.next(:string) }
  c.email           { Factory.next(:email) }
  c.contact_subject { ContactSubject.gen_if_not_exists(:title => 'Anything') }
  c.comments        %w( foo bar )
end

Factory.define :contact_subject do |cs|
  cs.recipients { Factory.next(:string) }
  cs.active     true
  cs.created_at { 48.hours.ago }
  cs.updated_at { 48.hours.ago }
end

Factory.define :content_page do |cp|
  cp.page_name   'Test Content Page'
  cp.sort_order    1
  cp.last_update_user_id 1 # This *should* be the admin, and we don't *really* care otherwise.
end

Factory.define :translated_content_page do |tcp|
  tcp.association       :content_page
  tcp.language          { Language.english }
  tcp.title             'Test Content Page'
  tcp.left_content      {|c| "<h3>This is Left Content in a #{c.title}</h3>" }
  tcp.main_content      {|c| "<h1>Main Content for #{c.title} ROCKS!</h1>" }
  tcp.meta_keywords     {|c| "keywords for #{c.title}"}
  tcp.meta_description  {|c| "description for #{c.title}"}
end


Factory.define :content_partner do |cp|
  cp.auto_publish                        false
  cp.association                         :user
  cp.description                         'Our Testing Content Partner'
  cp.description_of_data                 'Civil Protection!'
  cp.created_at                          { 5.days.ago }
  cp.partner_seen_step                   { 5.days.ago }
  cp.partner_complete_step               { 5.days.ago }
  cp.contacts_seen_step                  { 5.days.ago }
  cp.contacts_complete_step              { 5.days.ago }
  cp.licensing_seen_step                 { 5.days.ago }
  cp.licensing_complete_step             { 5.days.ago }
  cp.attribution_seen_step               { 5.days.ago }
  cp.attribution_complete_step           { 5.days.ago }
  cp.roles_seen_step                     { 5.days.ago }
  cp.roles_complete_step                 { 5.days.ago }
  cp.transfer_overview_seen_step         { 5.days.ago }
  cp.transfer_overview_complete_step     { 5.days.ago }
  cp.transfer_upload_seen_step           { 5.days.ago }
  cp.transfer_upload_complete_step       { 5.days.ago }
  cp.specialist_overview_seen_step       { 5.days.ago }
  cp.specialist_overview_complete_step   { 5.days.ago }
  cp.specialist_formatting_seen_step     { 5.days.ago }
  cp.specialist_formatting_complete_step { 5.days.ago }
  cp.ipr_accept                          true
  cp.attribution_accept                  true
  cp.roles_accept                        true
  cp.transfer_schema_accept              true
  cp.show_on_partner_page                true
  cp.vetted                              false
  cp.content_partner_status              { ContentPartnerStatus.find_by_translated(:label, 'Active') ||
                                           ContentPartnerStatus.gen_if_not_exists(:label => 'Active') }
end

Factory.define :content_upload do |cu|
  cu.association :user
  cu.link_name { Factory.next(:string).gsub(/\W/, '_') }
  cu.description 'something cool.'
  cu.attachment_file_name { |c| c.link_name }
  cu.attachment_extension '.jpg'
end

Factory.define :curator_activity do |ca|
  ca.code { Factory.next(:string) }
end

Factory.define :curator_activity_log do |ah|
  ah.association :user
  ah.association :activity
  ah.association :changeable_object_type
  ah.created_at  { 5.days.ago }
  ah.updated_at  { 5.days.ago }
end

Factory.define :data_object do |dato|
  dato.guid                   { Factory.next(:guid) }
  dato.identifier             ''
  dato.data_type              { DataType.gen_if_not_exists(:label => 'Image') }
  dato.mime_type              { MimeType.gen_if_not_exists(:label => 'image/jpeg') }
  dato.object_title           ''
  dato.language               { Language.english }
  dato.license                { License.gen_if_not_exists(:title => 'cc-by 3.0',
                                        :description => 'Some rights reserved',
                                        :source_url => 'http://creativecommons.org/licenses/by/3.0/',
                                        :logo_url => '/images/licenses/cc_by_small.png') }
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
  dato.data_rating            2.5
  dato.vetted                 { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'trusted') }
  dato.visibility             { Visibility.visible || Visibility.gen_if_not_exists(:label => 'visible') }
  dato.published              true
end

Factory.define :data_object_tag do |x|
  x.key   { Factory.next(:string) }
  x.value { Factory.next(:string) }
end

Factory.define :data_object_tags do |x|
  x.association :data_object
  x.association :data_object_tag
  x.data_object_guid { |r| r.data_object.guid }
end

Factory.define :data_objects_harvest_event do |dohe|
  dohe.association :harvest_event
  dohe.association :data_object
  dohe.guid        { s = ''; 32.times { s += ((0..9).to_a.map{|n| n.to_s} + %w{a b c d e f}).rand }; s } # ICK!
  dohe.status      { Status.inserted || Status.gen_if_not_exists(:label => 'inserted') }
end

Factory.define :data_objects_table_of_content do |dato|
  dato.association :data_object
  dato.association :toc_item
end

Factory.define :data_objects_info_item do |doii|
  doii.association :data_object
  doii.association :info_item
end

Factory.define :data_objects_ref do |dor|
  dor.association :data_object
  dor.association :ref
end

Factory.define :data_objects_hierarchy_entry do |dohe|
  dohe.association :hierarchy_entry
  dohe.association :data_object
  dohe.vetted      { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
  dohe.visibility  { Visibility.visible || Visibility.gen_if_not_exists(:label => 'Visible') }
end

Factory.define :data_objects_taxon_concept do |fdo|
  fdo.association :taxon_concept
  fdo.association :data_object
end

Factory.define :data_type do |dt|
  dt.schema_value ''
end

Factory.define :feed_data_object do |fdo|
  fdo.association :taxon_concept
  fdo.association :data_object
  fdo.association :data_type
  fdo.created_at      { 2.hours.ago }
end

Factory.define :feed_item do |fi|
  fi.association  :feed, :factory => :user
  fi.body 'some important notification here'
end

Factory.define :feed_item_type do |fit|
  fit.name { Factory.next(:string) }
end

Factory.define :glossary_term do |gt|
  gt.term       { Faker::Lorem.words[rand(4) + 1].titleize }
  gt.definition { Faker::Lorem.paragraph }
  gt.created_at { 2.hours.ago }
  gt.updated_at nil
end

Factory.define :harvest_event do |he|
  he.association :resource
  he.began_at     { 5.hours.ago }
  he.completed_at { 4.hours.ago }
  he.published_at { 3.hours.ago }
end

Factory.define :harvest_events_hierarchy_entry do |hehe|
  hehe.association :harvest_event
  hehe.association :hierarchy_entry
  hehe.guid        ''
  hehe.association :status
end

Factory.define :harvest_process_log do |hpl|
  hpl.process_name { Faker::Lorem.words[rand(4) + 1].titleize }
  hpl.began_at     { 2.hours.ago }
  hpl.completed_at { 1.hours.ago }
end


Factory.define :hierarchy do |hierarchy|
  hierarchy.label                   "A nested structure of divisions related to their probable evolutionary descent"
  hierarchy.url                     ''
  hierarchy.hierarchy_group_version 0
  hierarchy.hierarchy_group_id      0
  hierarchy.description             ''
  hierarchy.indexed_on              { 5.hours.ago }
  hierarchy.association             :agent
  hierarchy.browsable               0
  hierarchy.complete                1
end

Factory.define :hierarchies_content do |hc|
  hc.association     :hierarchy_entry
  hc.text                     0
  hc.text_unpublished         0
  hc.image                    0
  hc.image_unpublished        0
  hc.child_image              0
  hc.child_image_unpublished  0
  hc.flash                    0
  hc.youtube                  0
  hc.map                      0
  hc.content_level            1
  hc.image_object_id          0 # the preferred image for that hierarchy_entry, but probably not used (still, accurate in production)
end

Factory.define :hierarchy_entry do |he|
  he.guid           { Factory.next(:guid) }
  he.identifier     ''
  he.source_url     ''
  he.association    :name
  he.association    :rank
  he.parent_id      0
  he.association    :hierarchy
  he.rank_id        184
  he.ancestry       ''
  he.lft            1
  he.rgt            2
  he.depth          2
  he.association    :taxon_concept
  he.vetted         { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
  he.published      1
  he.visibility  { Visibility.visible || Visibility.gen_if_not_exists(:label => 'Visible') }
  he.created_at     Time.now
  he.updated_at     Time.now
end

Factory.define :hierarchy_entry_stat do |hes|
  hes.association         :hierarchy_entry
  hes.text_trusted        { rand(1000) }
  hes.text_untrusted      { rand(1000) }
  hes.image_trusted       { rand(1000) }
  hes.image_untrusted     { rand(1000) }
  hes.bhl                 { rand(1000) }
  hes.all_text_trusted    { rand(1000) }
  hes.all_text_untrusted  { rand(1000) }
  hes.have_text           { rand(1000) }
  hes.all_image_trusted   { rand(1000) }
  hes.all_image_untrusted { rand(1000) }
  hes.have_images         { rand(1000) }
  hes.all_bhl             { rand(1000) }
  hes.total_children      { rand(1000) }
end


Factory.define :info_item do |ii|
  ii.schema_value 'http://rs.tdwg.org/ontology/voc/ThisWontWork.JustForTesting'
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
  l.iso_639_1    ''
  l.iso_639_2    ''
  l.iso_639_3    ''
  l.activated_on { 24.hours.ago }
  l.sort_order   { Factory.next(:int) % 128 }
end

Factory.define :license do |l|
  l.title                    'cc-by 3.0'
  l.source_url               'http://creativecommons.org/licenses/by/3.0/'
  l.version                  0
  l.logo_url                 '/images/licenses/cc_by_small.png'
  l.show_to_content_partners true
end

Factory.define :member do |m|
  m.association :user
  m.association :community
end

Factory.define :mime_type do |mt|
end

Factory.define :name do |name|
  name.association         :canonical_form
  name.string              { Factory.next(:species) }
  name.clean_name          { |n| Name.prepare_clean_name(n.string) }
  name.canonical_verified  0 # I don't know that Rails ever uses this...
  name.italicized_verified 0 # I don't know that Rails ever uses this...
  # The italicized can NEVER be blank.  Even for common names.  ...Not that you can trust it for common names, but
  # some names are both vernacular *and* scientific, so we're enforcing the presence of the value.
  # The strip at the end handles strings that are only two words; it is useless with three or more.
  name.italicized          {|n| n.string.split[0] == n.string ? "<i>#{n.string}</i>" : ('<i>' + n.string.split[0..1].join(' ') + '</i> ' +  n.string.split[2..-1].join(' ')).strip }
  name.namebank_id         0
end

Factory.define :news_item do |ni|
  ni.display_date { 2.days.ago }
  ni.activated_on { 2.days.ago }
  ni.association  :user
  ni.active       1
end

Factory.define :changeable_object_type do |ot|
  ot.ch_object_type { Factory.next(:string) }
end

Factory.define :page_name do |pn|
  pn.association :name
  pn.association :item_page
end

Factory.define :privilege do |p|
  p.level 10
  p.special false
end

Factory.define :publication_title do |pt|
  pt.short_title 'hello'
  pt.author      'bob'
  pt.call_number ''
  pt.end_year    ''
  pt.start_year  ''
  pt.language    ''
  pt.marc_leader ''
  pt.abbreviation ''
  pt.marc_bib_id ''
  pt.title       'Test Publication Title'
  pt.details     'Nifty Titles Are Our Business'
  pt.url         'http://publication.titles.te.st'
end

Factory.define :random_hierarchy_image do |rhi|
  rhi.association   :data_object
  rhi.name          { "<i>#{ Factory.next(:species) }</i> Factory TestFramework" }
  rhi.association   :taxon_concept
  rhi.association   :hierarchy_entry
  rhi.association   :hierarchy
end

# I *don't* think these all actually relate to the rank_id's found elsewhere here. If so, we should change them to associations.
Factory.define :rank do |r|
  r.rank_group_id 0
end

Factory.define :ref do |r|
  r.full_reference  { Factory.next(:string) }
  r.user_submitted  0
  r.visibility      { Visibility.visible || Visibility.gen_if_not_exists(:label => 'visible') }
  r.published       1
end

Factory.define :hierarchy_entries_ref do |her|
  her.association :hierarchy_entry
  her.association :ref
end

Factory.define :ref_identifier do |ri|
  ri.identifier  { Factory.next(:string) }
  ri.association :ref_identifier_type
  ri.association :ref
end

Factory.define :ref_identifier_type do |rit|
  rit.label { Factory.next(:string) }
end

Factory.define :resource do |r|
  r.auto_publish    false
  r.title           'Testing Resource'
  r.subject         'Test Resource Subject'
  r.license         { License.find_by_title('cc-by 3.0') ||
                      License.gen_if_not_exists(:title => 'cc-by 3.0',
                                        :description => 'Some rights reserved',
                                        :source_url => 'http://creativecommons.org/licenses/by/3.0/',
                                        :logo_url => '/images/licenses/cc_by_small.png') }
  r.resource_status { ResourceStatus.find_by_translated(:label, 'Published') || ResourceStatus.gen_if_not_exists(:label => 'Published') }
  r.accesspoint_url 'http://services.eol.org/eol_php_code/tests/fixtures/files/test_resource.xml' # Won't work without a real, live URL for an XML file
  r.association :hierarchy
  r.association :content_partner
end

Factory.define :resource_status do |rs|
end

Factory.define :role do |r|
  r.title { Factory.next(:string) }
end

Factory.define :roles_user do |ru|
  ru.association  :user
  ru.association  :role
end

Factory.define :search_suggestion do |ss|
  ss.term            'searchterm'
  ss.language_label  'en'
  ss.taxon_id        1
  ss.sort_order      1
  ss.active          1
  ss.created_at      { 48.hours.ago }
end

Factory.define :service_type do |s|
end

Factory.define :site_configuration_option do |sco|
  sco.parameter       { Factory.next(:string) }
  sco.value           { true }
end

Factory.define :special_collection do |sc|
  sc.name             { Factory.next(:string) }
end

Factory.define :status do |s|
end

Factory.define :synonym_relation do |sr|
end

Factory.define :synonym do |s|
  s.association      :name
  s.synonym_relation { SynonymRelation.find_by_translated(:label, 'Synonym') ||
                         SynonymRelation.gen_if_not_exists(:label => 'Synonym') }
  s.language         { Language.english }
  s.association      :hierarchy_entry
  s.hierarchy_id     { |syn| syn.hierarchy_entry ? syn.hierarchy_entry.hierarchy.id : Hierarchy.default.id }
  s.preferred        1
  s.published        1
  s.vetted           { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
end

Factory.define :taxon_concept do |tc|
  tc.vetted         { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
  tc.published      1
  tc.vetted_id      0
  tc.supercedure_id 0
  tc.split_from     0
end

# We may want the default to actually have some content.  Not sure.
Factory.define :taxon_concept_content do |tcc|
  tcc.association :taxon_concept
  tcc.text                     0
  tcc.text_unpublished         0
  tcc.image                    0
  tcc.image_unpublished        0
  tcc.child_image              0
  tcc.child_image_unpublished  0
  tcc.flash                    0
  tcc.youtube                  0
  tcc.map                      0
  tcc.content_level            1
  tcc.image_object_id          0 # the preferred image for that hierarchy_entry, but probably not used (still, accurate in production)
end

Factory.define :taxon_concept_name do |tcn|
  tcn.preferred              true
  tcn.vern                   false
  tcn.source_hierarchy_entry_id {|he| Factory(:hierarchy_entry).id } # Does this work?
  tcn.language               { Language.english }
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
  ti.view_order  { Factory.next(:int) + 1 } # The plus-one keeps this away from Overview, which should always be 1.
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

Factory.define :top_concept_image do |ti|
  ti.association :taxon_concept
  ti.association :data_object
  ti.view_order  1
end

Factory.define :top_unpublished_concept_image do |tui|
  tui.association :taxon_concept
  tui.association :data_object
  tui.view_order  1
end

Factory.define :translated_activity do |a|
  a.association :activity
  a.language    { Language.english }
  a.name        { Factory.next(:string) }
end

Factory.define :translated_contact_role do |r|
  r.association     :contact_role
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_content_partner_data_type do |r|
  r.association     :content_partner_data_type
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_agent_role do |r|
  r.association     :agent_role
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_content_partner_status do |r|
  r.association     :content_partner_status
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_audience do |r|
  r.association     :audience
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_collection_type do |r|
  r.association     :collection_type
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_contact_subject do |r|
  r.association     :contact_subject
  r.language        { Language.english }
  r.title           { Factory.next(:string) }
end

Factory.define :translated_data_type do |r|
  r.association     :data_type
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_info_item do |r|
  r.association     :info_item
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_language do |r|
  r.label           { Factory.next(:string) }
  r.original_language_id { |l| Language.gen(:iso_639_1 => l.label[0..1].downcase).id }
  r.language        { Language.english }
end

Factory.define :translated_license do |r|
  r.association     :license
  r.language        { Language.english }
  r.description     { Factory.next(:string) }
end

Factory.define :translated_mime_type do |r|
  r.association     :mime_type
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_news_item do |r|
  r.association     :news_item
  r.language        { Language.english }
  r.body            { 'Test News Item Body' + Faker::Lorem.paragraph }
  r.title           { Faker::Lorem.words[rand(4) + 1].titleize }
end

Factory.define :translated_privilege do |r|
  r.association     :privilege
  r.language        { Language.english }
  r.name            { Factory.next(:string).gsub(/[^A-Za-z0-9]/, ' ') }
end

Factory.define :translated_rank do |r|
  r.association     :rank
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_resource_status do |r|
  r.association     :resource_status
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_service_type do |r|
  r.association     :service_type
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_status do |r|
  r.association     :status
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_synonym_relation do |r|
  r.association     :synonym_relation
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_toc_item do |r|
  r.table_of_contents_id { |t| TocItem.gen().id }
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_untrust_reason do |r|
  r.association     :untrust_reason
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_vetted do |r|
  r.association     :vetted
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :translated_visibility do |r|
  r.association     :visibility
  r.language        { Language.english }
  r.label           { Factory.next(:string) }
end

Factory.define :untrust_reason do |ur|
  ur.updated_at Time.now
  ur.created_at Time.now
  ur.class_name { Factory.next(:string) }
end

Factory.define :user do |u|
  u.default_taxonomic_browser 'text'
  u.expertise                 'middle'
  u.remote_ip                 { "123.45.67.1#{rand(10)}" }
  u.content_level             2
  u.email                     { Factory.next(:email) }
  u.default_hierarchy         { Hierarchy.first || Hierarchy.gen }
  u.given_name                { Factory.next(:first_name) }
  u.family_name               { Factory.next(:last_name) }
  u.agent_id                  {|user| Factory(:agent, :full_name => "#{user.given_name} #{user.family_name}").id }
  u.flash_enabled             true
  u.language                  { Language.english }
  u.mailing_list              true
  u.vetted                    false
  u.username                  do |user|
    attempt = "#{user.given_name[0..0]}_#{user.family_name[0..9]}".gsub(/\s/, '_').downcase
    while(User.find_by_username(attempt)) do
      attempt.succ!
    end
    attempt
  end
  u.active                    true
  u.password                  'test password'
  u.entered_password          'test password'
  u.curator_approved          false
  u.curator_verdict_by_id     nil
  u.curator_verdict_at        nil
  u.curator_scope             ''
  u.password_reset_token      nil
  u.password_reset_token_expires_at  nil
end

Factory.define :user_activity_log do |al|
  al.association :taxon_concept
  al.association :activity
  al.association :user
  al.value { Factory.next(:string) }
  al.created_at { 12.hours.ago }
end

Factory.define :users_data_object do |u|
  u.association :data_object
  u.association :user
end

Factory.define :vetted do |x|
  x.view_order 1
end

Factory.define :visibility do |x|
end

Factory.define :google_analytics_summary do |g|
  g.year { Factory.next(:year) }
  g.month { Factory.next(:month) }
  g.visits rand(1000)
  g.visitors rand(100)
  g.pageviews rand(10000)
  g.unique_pageviews rand(1000)
  g.ave_pages_per_visit rand(100)/10.0
  g.ave_time_on_site "00:%02d:%02d" % [rand(60), rand(60)]
  g.ave_time_on_page "00:%02d:%02d" % [rand(60), rand(60)]
  g.per_new_visits rand(100)/10.0
  g.bounce_rate rand(100)/10.0
  g.per_exit rand(100)/10.0
  g.taxa_pages rand(1000)
  g.taxa_pages_viewed rand(100)
  g.time_on_pages rand(1000)
end

Factory.define :google_analytics_partner_summary do |g|
  g.year { Factory.next :year }
  g.month { Factory.next :month }
  g.association :user
  g.taxa_pages rand(1000)
  g.taxa_pages_viewed rand(100)
  g.page_views rand(10000)
  g.unique_page_views rand(1000)
  g.time_on_page rand(1000)
end

Factory.define :google_analytics_page_stat do |g|
  g.association :taxon_concept
  g.year { Factory.next :year }
  g.month { Factory.next :month }
  g.page_views rand(1000)
  g.unique_page_views rand(100)
  g.time_on_page "00:%02d:%02d" % [rand(60), rand(60)]
end

Factory.define :google_analytics_partner_taxon do |g|
  g.association :taxon_concept
  g.association :user
  g.year { Factory.next :year }
  g.month { Factory.next :month }
end
