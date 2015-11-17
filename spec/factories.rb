# REMINDER: default model factories, eg. :user, should *only* generate required
# fields
#
# If you want a model loaded up with all kinds of goodies, make a different
# generator, e.g.: admin (which is a user)
#
#
#
#
#
#                      PLEASE KEEP FACTORIES ALPHABETICAL.
#
#
#


require 'factory_girl_rails'
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
        @rand_iucn.sample
      end

      def flash
        @rand_flash ||=

          [200811131313601, 200811131321659, 200811131394659, 200811131367814, 200811131351121, 200811131388288,
            200811131382797, 200811131390600, 200811131333916, 200811131393000, 200811131347554, 200811131354820,
            200811131391764, 200811131316882, 200811131328300, 200811131392039, 200811131350808, 200811131333809,
            200811131349975, 200811131317614, 200811131356003, 200811131372942, 200811131393363, 200811131382901,
            200811131355461, 200811131374742, 200811131356635, 200811131314704, 200811131368751, 200811131374919,
            200811131316328, 200811131309151, 200811131331207, 200811131310763]

        @rand_flash.sample
      end

      # These are object_url values, not object_cache_url:
      def youtube
        @rand_youtube ||=
          ["http://www.youtube.com/v/tawTDADXvuM", "http://www.youtube.com/v/Sk1FhlPeQH8", "http://www.youtube.com/v/ymTMrg7G4Ac"]
        @rand_youtube.sample
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

        @rand_maps.sample
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

        @rand_images.sample
      end

      def name_part
        part = Faker::Lorem.words(1)[0]
        part += Faker::Lorem.words(1)[0] if part.length < 4
        part += %w{i a ii us is iae erox eron eri alia eli esi alia elia ens ica ator atus erus ensis alis alius osyne eles es ata}.sample
      end

      def scientific_name
        "#{Faker::Eol.name_part.titleize} #{Faker::Eol.name_part}"
      end

      def common_name
        ['common', "#{FactoryGirl.generate(:first_name)}'s", 'blue', 'red', 'pink', 'green', 'purple',
         'painted', 'spiny', 'agitated', 'horny', 'blessed', 'sacred', 'sacrimonious', 'naughty',
         'litte', 'tiny', 'giant', 'great', 'lesser', 'least', 'river', 'plains', 'city', 'sky', 'stream',
         'thirsty', 'ravenous', 'bloody', 'cursed', 'cromulent'].sample + ' ' + Faker::Eol.name_part
      end

      def attribution
        "#{FactoryGirl.generate(:first_name)[0..0]}. #{FactoryGirl.generate(:last_name)}"
      end

    end
  end
end

FactoryGirl.define do

  #### Sequences
  # Not unique, of course:
  sequence :iucn do |n|
    @seq_iucn = ["Extinct (EX)", "Data Deficient (DD)", "Endangered (EN)", "Vulnerable (VU)", "Critically Endangered (CR)", "Near Threatened (NT)", "Least Concern (LC)", "Conservation Dependent (LR/cd)", "Extinct in the Wild (EW)"]
    @seq_iucn[n % @seq_iucn.length]
  end

  # Not unique:
  sequence :flash do |n|
    @seq_flash =
      [200811131313601, 200811131321659, 200811131394659, 200811131367814, 200811131351121, 200811131388288, 200811131382797,
       200811131390600, 200811131333916, 200811131393000, 200811131347554, 200811131354820, 200811131391764, 200811131316882,
       200811131328300, 200811131392039, 200811131350808, 200811131333809, 200811131349975, 200811131317614, 200811131356003,
       200811131372942, 200811131393363, 200811131382901, 200811131355461, 200811131374742, 200811131356635, 200811131314704,
       200811131368751, 200811131374919, 200811131316328, 200811131309151, 200811131331207, 200811131310763]
    @seq_flash[n % @seq_flash.length]
  end

  # Not unique:
  sequence :youtube do |n|
    @seq_youtube = ["http://www.youtube.com/v/tawTDADXvuM",
                    "http://www.youtube.com/v/Sk1FhlPeQH8",
                    "http://www.youtube.com/v/ymTMrg7G4Ac"]
    @seq_youtube[n % @seq_youtube.length]
  end

  # Not unique:
  sequence :sound do |n|
    @seq_sound =
      [201105040549843, 201105040554365, 201105040529974, 201105040538097, 201105040535175, 201105040549841,
       201105040560889, 201105040555104, 201105040573195, 201105040594149]
    @seq_sound[n % @seq_sound.length]
  end

  # Not unique:
  sequence :map do |n|
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
  sequence :image do |n|
    @seq_images ||= [
      201301212369015, 201210030069362, 201204220191542, 201202040069888, 201111020692069, 201207302359794, 201301170225666,
      201111170140453, 201111021131069, 201202110214753, 201201080155483, 201111021106221, 201205220000616, 201111021252396,
      201112090080634, 201301212386289, 201201030187595, 201111021244952, 201204250072439, 201111012278143, 201111020864905,
      201111021075853, 201111011563090, 201204040068862, 201208120076649, 201111011778717, 201203220059150, 201212102306393,
      201111021567463, 201111020587617, 201205210185638, 201111011190361, 201111011511951, 201202160129393, 201206220152592,
      201202050005388, 201111020235084, 201111020128253, 201201090150392, 201202020090191, 201301232329668, 201204100001708,
      201211142310100, 201112270108371, 201112270143930, 201111012383579, 201207260783649, 201111012169032, 201111011158648,
      201111020612441, 201211270043984, 201111021299859, 201205150031711, 201112230179863, 201111012244809, 201111011330372,
      201212282365864, 201111030123051, 201111020413030, 201111021029613, 201209022352216, 201208172341618, 201203260191478,
      201202030069990, 201206080009504, 201301130021740, 201111011982630, 201112300148555, 201111030214769, 201111020456955,
      201111011344479, 201111011679845, 201205300022426, 201111300968085, 201205100347094, 201209112315713, 201203120007511,
      201207070051807, 201204050041265, 201210012385079, 201211040848246, 201203290044598, 201205150083147, 201111012089904,
      201211280051661, 201111020821391, 201111012194996, 201202260041221, 201211260100253, 201112100017714, 201207170007419,
      201211040827144, 201201250295337, 201112300194339, 201204200147552, 201209082397624, 201111020312732, 201206210040082,
      201111012185408, 201201250367476, 201202010281247, 201301040017859, 201111011984102, 201202230021720, 201301230017775,
      201111021286828, 201201250380510, 201111011191042, 201203290041772, 201209252381279, 201205310077602, 201202010290745,
      201201041249064, 201111012233905, 201111011892631, 201208062341539, 201207020117313, 201203290090064, 201209172384084,
      201206100250227, 201111012019618, 201204150016376, 201202260034012, 201111021549802, 201212282365133, 201111012266993,
      201112220171145, 201203270178402, 201111020456873, 201111011632931, 201203270131349, 201111020680528, 201111020677567,
      201111020255217, 201205050025674, 201201290348969, 201111240192495, 201111020299829, 201302041061045, 201206250194550,
      201201070101022, 201111020073931, 201111020541857, 201301070350990, 201205060097570, 201111020722713, 201112090037380,
      201111021659647, 201111210127467, 201111011130833, 201205310020621, 201201050110344, 201205310044120, 201111012231575,
      201111020982521, 201111020200490, 201202090224858, 201111230157916, 201212102333234, 201212202395444, 201111012306179,
      201201100156094, 201111030101188, 201208092319164, 201111020017740, 201111021236278, 201111011648478, 201111011083917,
      201111012242005, 201203120178100, 201205160019351, 201212272324044, 201210220036769, 201206100146139, 201111021588467 ]
    @seq_images[n % @seq_images.length]
  end

  sequence :user_logo do |n|
    FactoryGirl.generate(:image)
  end

  sequence :year do |n|
    1990 + n
  end

  sequence :month do |n|
    (n % 12) + 1
  end

  # Unique:
  sequence :guid do |n|
    SecureRandom.uuid.gsub(/-/, '')
  end

  # NOTE - if you want to "clean up" this block, please do NOT introduce newlines into the names. It mucks up regexes in tests.
  # Unique:
  sequence :scientific_name do |n|
    @seq_sci_name = ["Quibusdameli estculpaatus", "Estasperioreseli etquidemis", "Nesciunterox autrerumalis",
      "Voluptasalius optioerus", "Remrerumeron auteterus", "Veritatises idofficiisiae", "Accusamusalis pariatura",
      "Voluptateseri doloremosyne", "Autrecusandaees repudiandaeica", "Nihileri voluptasus", "Dignissimosii inutes",
      "Fugais utharumatus", "Minuseli ullamens", "Dignissimosatus nobisosyne", "Expeditaalia evenietelia",
      "Earumeles beataeata", "Culpaensis sapienteesi", "Utomnisesi sequialis", "Autaliquideri minimais", "Beataeelia etnemoiae",
      "Autema officiaalius", "Autemalius utsimiliqueesi", "Etconsequaturelia autenimalia", "Quoautesi natuseri",
      "Voluptatumeri esseensis", "Ameti maioresis", "Ipsamalius distinctioerox", "Maximees veritatisatus",
      "Molestiaeus rationealia", "Fugitens dolorealius", "Quisquamator sequieles", "Essees eaqueata", "Animiens atdoloribuseron",
      "Adaliasii iurea", "Nonnumquamerus numquamerus", "Autvoluptatesus temporaalis", "Excepturialia omnisa",
      "Estveroalia nihilata", "Quiincidunta culpaelia", "Providentalia estquaeratens", "Placeatalia uteosensis",
      "Ipsaensis architectoalius", "Deserunterox facererox", "Suntalia estsitalius", "Aliasosyne quiadipisciatus",
      "Illoica exexplicaboalia", "Laboriosamerus quisis", "Optiois molestiasalia", "Ipsuma animius", "Quiserox eligendii",
      "Eteaiae nullais"]
    pick = @seq_sci_name[n % @seq_sci_name.length]
    (n / @seq_sci_name.length).times { pick.succ! }
    pick
  end

  # NOTE - if you want to "clean up" this block, please do NOT introduce newlines into the names. It mucks up regexes in tests.
  # Unique:
  sequence :common_name do |n|
    @seq_common_name = ["pink quaist", "ravenous clover", "red suntus", "darning needle", "tiger", "frizzlebek",
      "purple dust crab", "cloud swallow", "spiny possom", "common desert mouse", "fisher", "chartruse turtle",
      "horny toad", "scarlet vermillion", "Mozart's nemesis", "quick brown fox", "painted horse", "thirsty aphid",
      "bloody eel", "fruit bat", "giant ostrich", "common rat", "cursed doormouse", "great shrimp", "stream newt",
      "blessed sparrow", "ravenous eagle", "common titmouse", "least ferret", "raccoon", "papa bear", "brown hornet",
      "urban crocidile", "classical enthusiast", "grungebutter", "bripplefoam frond", "elf's cup", "agitated harmonium",
      "stone dragon", "Werner's mite", "green anole", "killer bee", "thistle", "paramecium", "scorpion king", "tarantula",
      "cardinal", "moon fungus", "upbeat chickadee", "amoeba"]
    pick = @seq_common_name[n % @seq_common_name.length]
    (n / @seq_common_name.length).times { pick.succ! }
    pick
  end

  # Unique:
  sequence :last_name do |n|
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
  sequence :first_name do |n|
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
  sequence :attribution do |n|
    @seq_attr = ["L.", "Linn.", "Linnaeus", "G. D'Amore", "R. Bergstrom", "L.", "Linn", "R. Cartwright", "L.", "Linn.",
      "Linnaeus", "N. Upton", "L. Carroll", "M. Port", "S. Posford", "Posford & Ram", "L.", "Linnaeus", "", "P. Leary",
      "Padderson", "Linnaeus", "L.", "M. Mayer"]
    @seq_attr[n % @seq_attr.length]
  end

  # Faker names are frequently unique, but let's just make absolutely sure:
  sequence :species do |n|
    s = FactoryGirl.generate(:scientific_name)
    while (Name.find_by_string(s)) do
      s = FactoryGirl.generate(:scientific_name)
    end
    s
  end

  sequence(:string) {|n| "unique#{ n }string" }
  sequence(:email)  {|n| "bob#{n}@smith.com" }
  sequence(:title)  {|n| "#{n} " + Faker::Lorem.words(rand(3)+1).map(&:titleize).join(' ') }
  sequence(:int)    {|n| n }
  sequence(:uri)    {|n| "http://eol.org/user_data/#{n}" }

  #### Factories

  factory :activity do
  end

  factory :admin, class: User do
    admin                     true
    remote_ip                 { "123.45.67.1#{rand(10)}" }
    email                     { generate(:email) }
    given_name                { generate(:first_name) }
    family_name               { generate(:last_name) }
    agent_id                  { FactoryGirl.create(:agent, :full_name => "#{given_name} #{family_name}").id }
    language                  { Language.english }
    username                  do
      attempt = "#{given_name[0..0]}_#{family_name[0..9]}".gsub(/\s/, '_').downcase
      while(User.find_by_username(attempt)) do
        attempt.succ!
      end
      attempt
    end
    agreed_with_terms         true
    active                    true
    password                  'test password'
    entered_password          { password }
    curator_approved          false
    curator_verdict_by_id     nil
    curator_verdict_at        nil
    curator_scope             ''
    recover_account_token      nil
    recover_account_token_expires_at  nil
    curator_level_id          nil
    logo_cache_url            { generate(:user_logo) }
  end

  factory :agent do
    created_at      { 5.days.ago }
    homepage        ''
    full_name       { generate(:first_name) << ' ' << FactoryGirl.generate(:last_name) }
  end

  factory :agent_role do
  end

  factory :agents_data_object do
    association :data_object
    association :agent
    association :agent_role
    view_order  0
  end

  factory :agents_hierarchy_entry do
    association :agent
    association :agent_role
    association :hierarchy_entry
    view_order  2
  end

  factory :agents_synonym do
    association :agent
    association :agent_role
    association :synonym
    view_order  2
  end

  factory :audience do
  end

  factory :canonical_form do
    string { generate(:species) }
  end

  factory :collection do
    name                  { (Faker::Lorem.words << generate(:string)).join(' ').titleize }
    published             true
    special_collection_id nil
    association           :sort_style
    updated_at { 5.days.ago }
  end

  factory :collection_job do
    all_items false
    collection
    command 'copy'
    association :target_collection, :factory => :collection
    user
  end

  factory :collection_activity_log do
    association :user
    association :collection
    activity    { Activity.create }
    created_at  { 5.days.ago }
  end

  factory :collection_item do
    association :collection
    association :collected_item, :factory => :data_object
    created_at  { 5.minutes.ago }
  end

  factory :collection_type do
    parent_id  0
    lft        0
    rgt        0
  end

  factory :collection_types_hierarchy do
    association :collection_type
    association :hierarchy
  end

  # NOTE - the Comment model has some validations on it (create/update/etc) that will fail if you don't have a loaded
  # database, so don't expect this factory to work in all situations.
  factory :comment do
    association  :parent, :factory => :data_object
    parent_type  'DataObject'
    body         { Faker::Lorem.paragraph }
    association  :user
    from_curator false
  end

  factory :community do
    name        { (Faker::Lorem.words << generate(:string)).join(' ').titleize }
    description { Faker::Lorem.paragraph }
    published   true
    after(:create) { |c| c.collections << FactoryGirl.create(:collection) }
  end

  factory :community_activity_log do
    association :user
    association :community
    activity    { Activity.create }
    created_at  { 5.days.ago }
  end

  factory :contact do
    name            { generate(:string) }
    email           { generate(:email) }
    contact_subject { ContactSubject.gen_if_not_exists(:title => 'Anything') }
    comments        %w( foo bar )
  end

  factory :contact_role do
  end

  factory :contact_subject do
    recipients { generate(:string) }
    active     true
    created_at { 48.hours.ago }
    updated_at { 48.hours.ago }
  end

  factory :content_page do
    page_name            'Test Content Page'
    sort_order           1
    last_update_user_id  1 # This *should* be the admin, and we don't *really* care otherwise.
    active               1
  end

  factory :content_partner do
    full_name              { generate(:string) }
    association            :user
    description            'Our Testing Content Partner'
    description_of_data    'Civil Protection!'
    created_at             { 5.days.ago }
    is_public              true
  end

  factory :content_partner__as_unassisted,
    class: ContentPartner::AsUnassisted do
    full_name              { generate(:string) }
    association            :user
    description            'Our Unassisted Testing Content Partner'
    description_of_data    'I made this myself'
    created_at             { 4.days.ago }
    is_public              true
  end

  factory :content_partner_agreement do
    is_current          true
    body                'The agreement body.'
  end

  factory :content_partner_contact do
    association :content_partner
    association :contact_role
    given_name  { generate(:string) }
    family_name { generate(:string) }
    full_name   { "#{given_name} #{family_name}" }
    email       { "#{given_name}.#{family_name}@example.com".downcase }
    homepage    'http://whatever.org'
    address     '1234 Doesntmatter St'
    title       'Call me SIR'
    telephone   '555-222-1111'
  end

  factory :content_partner_data_type do
  end

  factory :content_partner_status do
  end

  factory :content_upload do
    association :user
    link_name { generate(:string).gsub(/\W/, '_') }
    description 'something cool.'
    attachment_file_name { link_name }
    attachment_extension '.jpg'
  end

  factory :curator, class: User do
    admin                     false
    remote_ip                 { "123.45.67.1#{rand(10)}" }
    email                     { generate(:email) }
    given_name                { generate(:first_name) }
    family_name               { generate(:last_name) }
    agent_id                  { FactoryGirl.create(:agent, :full_name => "#{given_name} #{family_name}").id }
    language                  { Language.english }
    username                  do
      attempt = "#{given_name[0..0]}_#{family_name[0..9]}".gsub(/\s/, '_').downcase
      while(User.find_by_username(attempt)) do
        attempt.succ!
      end
      attempt
    end
    agreed_with_terms         true
    active                    true
    password                  'test password'
    entered_password          { password }
    curator_approved          true
    curator_verdict_by_id     1
    curator_verdict_at        { Time.now }
    credentials               'Good stuff'
    curator_scope             'Something important'
    recover_account_token      nil
    recover_account_token_expires_at  nil
    curator_level_id          { CuratorLevel.full.id }
    logo_cache_url            { generate(:user_logo) }
  end

  factory :curator_activity do
    code { generate(:string) }
  end

  factory :curator_activity_log do
    association :user
    association :activity
    association :changeable_object_type
    created_at  { 5.days.ago }
    updated_at  { 5.days.ago }
  end

  factory :curated_taxon_concept_preferred_entry do
    association :hierarchy_entry
    association :taxon_concept
    association :user
  end

  factory :curated_data_objects_hierarchy_entry do
    association :hierarchy_entry
    association :data_object
    association :user
    data_object_guid { generate(:guid) }
    vetted      { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
    visibility  { Visibility.visible }
  end

  factory :curator_level do
    label { generate(:string) }
  end

  factory :data_object do
    guid                   { generate(:guid) }
    identifier             ''
    data_type              { DataType.gen_if_not_exists(:label => 'Image') }
    mime_type              { MimeType.gen_if_not_exists(:label => 'image/jpeg') }
    object_title           ''
    language               { Language.english }
    license                { License.cc }
    rights_statement       'Test rights statement'
    rights_holder          'Test rights holder'
    bibliographic_citation ''
    source_url             ''
    description            'Test Data Object'
    object_url             ''
    object_cache_url       ''
    thumbnail_url          ''
    thumbnail_cache_url    ''
    location               ''
    latitude               0
    longitude              0
    altitude               0
    object_created_at      { 5.days.ago }
    object_modified_at     { 2.days.ago }
    created_at             { 5.days.ago }
    updated_at             { 3.days.ago }
    data_rating            2.5
    published              true
  end

  factory :data_object_translation do
    association :data_object
    language { Language.english }
    association :original_data_object, factory: :data_object
  end

  factory :data_objects_harvest_event do
    association :harvest_event
    association :data_object
    guid        { data_object.guid }
    status      { Status.inserted || Status.gen_if_not_exists(:label => 'inserted') }
  end

  factory :data_objects_table_of_content do
    association :data_object
    association :toc_item
  end

  factory :data_objects_info_item do
    association :data_object
    association :info_item
  end

  factory :data_objects_ref do
    association :data_object
    association :ref
  end

  factory :data_objects_hierarchy_entry do
    association :hierarchy_entry
    association :data_object
    vetted      { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
    visibility  { Visibility.visible }
  end

  factory :data_objects_taxon_concept do
    association :taxon_concept
    association :data_object
  end

  factory :data_point_uri do
    association :taxon_concept
    association :resource
    association :user_added_data
    vetted      { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
    visibility  { Visibility.visible }
    uri         { FactoryGirl.generate(:uri) }
  end

  factory :data_search_file do
    association   :known_uri
    association   :user
    uri           { "http://example.com/#{generate(:string)}" }
    row_count     10
    created_at    Time.now
    updated_at    Time.now
    completed_at  Time.now
    file_number   1
  end

  factory :collection_download_file do
    user_id 1
    collection_id 1
    file_number 1
    row_count 1
    error "Error"
  end

  factory :data_type do
    schema_value ''
  end

  factory :eol_config do
    parameter       { generate(:string) }
    value           { true }
  end

  factory :eol_statistic do
    members_count                                     { rand(100000) }
    communities_count                                 { rand(100000) }
    collections_count                                 { rand(100000) }
    pages_count                                       { rand(100000) }
    pages_with_content                                { rand(100000) }
    pages_with_text                                   { rand(100000) }
    pages_with_image                                  { rand(100000) }
    pages_with_map                                    { rand(100000) }
    pages_with_video                                  { rand(100000) }
    pages_with_sound                                  { rand(100000) }
    pages_without_text                                { rand(100000) }
    pages_without_image                               { rand(100000) }
    pages_with_image_no_text                          { rand(100000) }
    pages_with_text_no_image                          { rand(100000) }
    base_pages                                        { rand(100000) }
    pages_with_at_least_a_trusted_object              { rand(100000) }
    pages_with_at_least_a_curatorial_action           { rand(100000) }
    pages_with_BHL_links                              { rand(100000) }
    pages_with_BHL_links_no_text                      { rand(100000) }
    pages_with_BHL_links_only                         { rand(100000) }
    content_partners                                  { rand(100000) }
    content_partners_with_published_resources         { rand(100000) }
    content_partners_with_published_trusted_resources { rand(100000) }
    published_resources                               { rand(100000) }
    published_trusted_resources                       { rand(100000) }
    published_unreviewed_resources                    { rand(100000) }
    newly_published_resources_in_the_last_30_days     { rand(100000) }
    data_objects                                      { rand(100000) }
    data_objects_texts                                { rand(100000) }
    data_objects_images                               { rand(100000) }
    data_objects_videos                               { rand(100000) }
    data_objects_sounds                               { rand(100000) }
    data_objects_maps                                 { rand(100000) }
    data_objects_trusted                              { rand(100000) }
    data_objects_unreviewed                           { rand(100000) }
    data_objects_untrusted                            { rand(100000) }
    data_objects_trusted_or_unreviewed_but_hidden     { rand(100000) }
    udo_published                                     { rand(100000) }
    udo_published_by_curators                         { rand(100000) }
    udo_published_by_non_curators                     { rand(100000) }
    rich_pages                                        { rand(100000) }
    hotlist_pages                                     { rand(100000) }
    rich_hotlist_pages                                { rand(100000) }
    redhotlist_pages                                  { rand(100000) }
    rich_redhotlist_pages                             { rand(100000) }
    pages_with_score_10_to_39                         { rand(100000) }
    pages_with_score_less_than_10                     { rand(100000) }
    curators                                          { rand(100000) }
    curators_assistant                                { rand(100000) }
    curators_full                                     { rand(100000) }
    curators_master                                   { rand(100000) }
    active_curators                                   { rand(100000) }
    pages_curated_by_active_curators                  { rand(100000) }
    objects_curated_in_the_last_30_days               { rand(100000) }
    curator_actions_in_the_last_30_days               { rand(100000) }
    lifedesk_taxa                                     { rand(100000) }
    lifedesk_data_objects                             { rand(100000) }
    marine_pages                                      { rand(100000) }
    marine_pages_in_col                               { rand(100000) }
    marine_pages_with_objects                         { rand(100000) }
    marine_pages_with_objects_vetted                  { rand(100000) }
    created_at                                        { 5.days.ago }
    total_triples                                     { rand(100000) }
    total_occurrences                                 { rand(100000) }
    total_measurements                                { rand(100000) }
    total_associations                                { rand(100000) }
    total_measurement_types                           { rand(100000) }
    total_association_types                           { rand(100000) }
    total_taxa_with_data                              { rand(100000) }
    total_user_added_data                             { rand(100000) }
  end

  factory :forum do
    association :forum_category
    name { Faker::Lorem.words(rand(10) + 1).join(' ') }
    description { Faker::Lorem.paragraph }
    association :user
  end

  factory :forum_category do
    title { Faker::Lorem.words(rand(10) + 1).join(' ') }
    description { Faker::Lorem.paragraph }
    association :user
  end

  factory :forum_topic do
    association :forum
    title { Faker::Lorem.words(rand(10) + 1).join(' ') }
    association :user
  end

  factory :forum_post do
    association :forum_topic
    subject { Faker::Lorem.words(rand(10) + 1).join(' ') }
    text { Faker::Lorem.paragraphs(rand(6) + 1).map{ |s| "<p>#{s}</p>" }.join }
    association :user
  end

  factory :glossary_term do
    term       { Faker::Lorem.words[rand(4) + 1].titleize }
    definition { Faker::Lorem.paragraph }
    created_at { 2.hours.ago }
    updated_at nil
  end

  factory :harvest_event do
    association :resource
    began_at     { 5.hours.ago }
    completed_at { 4.hours.ago }
    published_at { 3.hours.ago }
    publish      false
  end

  factory :harvest_events_hierarchy_entry do
    association :harvest_event
    association :hierarchy_entry
    guid        ''
    association :status
  end

  factory :harvest_process_log do
    process_name { Faker::Lorem.words[rand(4) + 1].titleize }
    began_at     { 2.hours.ago }
    completed_at { 1.hours.ago }
  end


  factory :hierarchy do
    label                   "A nested structure of divisions related to their probable evolutionary descent"
    url                     ''
    hierarchy_group_version 0
    hierarchy_group_id      0
    description             ''
    indexed_on              { 5.hours.ago }
    association             :agent
    browsable               0
    complete                1
  end

  factory :hierarchy_entry do
    guid        { generate(:guid) }
    identifier  ''
    source_url  ''
    association :name
    association :rank
    parent_id   0
    association :hierarchy
    rank_id     184
    ancestry    ''
    lft         1
    rgt         2
    depth       2
    association :taxon_concept
    vetted      { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
    published   true
    visibility  { Visibility.visible }
    created_at  Time.now
    updated_at  Time.now
  end

  factory :image_crop do
    association               :data_object
    association               :user
    original_object_cache_url ''
    new_object_cache_url      ''
  end

  factory :info_item do
    schema_value 'http://rs.tdwg.org/ontology/voc/ThisWontWork.JustForTesting'
    toc_id       0
  end

  factory :ip_address do
    number { generate(:int) }
    success false
    provider 'i have no idea what this is'
  end

  factory :item_page do
    association :title_item
    page_type ''
    year        '1999'
    volume      '2'
    issue       '42'
    prefix      'Page'
    number      '6'
    url         'http://www.biodiversitylibrary.org/page/ThisWontWork.JustTesting'
  end

  factory :known_uri do
    vetted      { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
    visibility  { Visibility.visible }
    uri         { "http://eol.org/known_uri/" + generate(:guid) }
  end

  factory :known_uri_allowed_unit, class: KnownUriRelationship do
    association :from_known_uri, :factory => :known_uri_measurement
    association :to_known_uri, :factory => :known_uri_unit
    relationship_uri { KnownUriRelationship::ALLOWED_UNIT_URI }
  end

  factory :known_uri_allowed_value, class: KnownUriRelationship do
    association :from_known_uri, :factory => :known_uri_measurement
    association :to_known_uri, :factory => :known_uri_value
    relationship_uri { KnownUriRelationship::ALLOWED_VALUE_URI }
  end

  # The "magic" used here to get the name associated with the KnownUri is
  # explained here:
  # http://rubydoc.info/gems/factory_girl/file/GETTING_STARTED.md#Transient_Attributes
  factory :known_uri_measurement, class: KnownUri do
    ignore do
      name { generate(:string) }
      definition "Measurements have a default definition"
    end
    after(:create) do |kuri, evaluator|
      create(:translated_known_uri,
             definition: evaluator.definition,
             known_uri: kuri,
             name: evaluator.name)
    end
    vetted { Vetted.trusted }
    visibility { Visibility.visible }
    uri_type { UriType.measurement }
    uri { "http://example.com/#{generate(:string)}" }
  end

  factory :known_uri_unit, class: KnownUri do
    vetted { Vetted.trusted }
    visibility { Visibility.visible }
    uri_type { UriType.value }
    uri { "http://example.com/#{generate(:string)}" }
  end

  factory :known_uri_relationship do
    association :from_known_uri, :factory => :known_uri
    association :to_known_uri, :factory => :known_uri
    relationship_uri  { "http://eol.org/relationship_uri/" + generate(:guid) }
  end

  factory :language do
    source_form  ''
    iso_639_1    ''
    iso_639_2    ''
    iso_639_3    ''
    activated_on { 24.hours.ago }
    sort_order   { generate(:int) % 128 }
  end

  factory :language_group do
    association :representative_language, :factory => :language
  end

  factory :license do
    title                    'cc-by 3.0'
    source_url               'http://creativecommons.org/licenses/by/3.0/'
    version                  0
    logo_url                 'cc_by_small.png'
    show_to_content_partners true
  end

  factory :link_type do
  end

  factory :master_curator, class: User do
    admin                     false
    remote_ip                 { "123.45.67.1#{rand(10)}" }
    email                     { generate(:email) }
    given_name                { generate(:first_name) }
    family_name               { generate(:last_name) }
    agent_id                  { FactoryGirl.create(:agent, :full_name => "#{given_name} #{family_name}").id }
    language                  { Language.english }
    username                  do
      attempt = "#{given_name[0..0]}_#{family_name[0..9]}".gsub(/\s/, '_').downcase
      while(User.find_by_username(attempt)) do
        attempt.succ!
      end
      attempt
    end
    agreed_with_terms         true
    active                    true
    password                  'test password'
    entered_password          { password }
    curator_approved          true
    curator_verdict_by_id     1
    curator_verdict_at        { Time.now }
    credentials               'Good stuff'
    curator_scope             'Something important'
    recover_account_token      nil
    recover_account_token_expires_at  nil
    curator_level_id          { CuratorLevel.master.id }
    logo_cache_url            { generate(:user_logo) }
  end

  factory :member do
    association :user
    association :community
  end

  factory :mime_type do
  end

  factory :name do
    association         :canonical_form
    string              { generate(:species) }
    clean_name          { Name.prepare_clean_name(string) }
    canonical_verified  0 # I don't know that Rails ever uses this...
    italicized_verified 0 # I don't know that Rails ever uses this...
    # The italicized can NEVER be blank.  Even for common names.  ...Not that you can trust it for common names, but
    # some names are both vernacular *and* scientific, so we're enforcing the presence of the value.
    # The strip at the end handles strings that are only two words; it is useless with three or more.
    italicized          { string.split[0] == string ? "<i>#{string}</i>" : ('<i>' + string.split[0..1].join(' ') + '</i> ' +  string.split[2..-1].join(' ')).strip }
    namebank_id         0
  end

  factory :news_item do
    display_date { 2.days.ago }
    activated_on { 2.days.ago }
    association  :user
    active       1
  end

  factory :changeable_object_type do
    ch_object_type { generate(:string) }
  end

  factory :page_name do
    association :name
    association :item_page
  end

  factory :permission do
    users_count 0
  end

  factory :publication_title do
    short_title 'Publication'
    author      'bob'
    call_number ''
    end_year    ''
    start_year  ''
    language    ''
    marc_leader ''
    abbreviation ''
    marc_bib_id ''
    title       'Test Publication Title'
    details     'Nifty Titles Are Our Business'
    url         'http://publication.titles.te.st'
  end

  factory :random_hierarchy_image do
    association   :data_object
    name          { "<i>#{ generate(:species) }</i> Factory TestFramework" }
    association   :taxon_concept
    association   :hierarchy_entry
    association   :hierarchy
  end

  # I *don't* think these all actually relate to the rank_id's found elsewhere here. If so, we should change them to associations.
  factory :rank do
    rank_group_id 0
  end

  factory :ref do
    full_reference  { generate(:string) }
    user_submitted  0
    visibility      { Visibility.visible }
    published       1
  end

  factory :hierarchy_entries_ref do
    association :hierarchy_entry
    association :ref
  end

  factory :ref_identifier do
    identifier  { generate(:string) }
    association :ref_identifier_type
    association :ref
  end

  factory :ref_identifier_type do
    label { generate(:string) }
  end

  factory :resource do
    auto_publish    false
    title           'Testing Resource'
    subject         'Test Resource Subject'
    license         { License.cc }
    resource_status { ResourceStatus.processed }
    accesspoint_url 'http://eol.org/opensearchdescription.xml' # Won't work without a real, live URL for an XML file
    refresh_period_hours 0
    resource_created_at 48.hours.ago
    association :hierarchy
    association :content_partner
  end

  factory :resource_status do
  end

  factory :search_suggestion do
    term            'searchterm'
    language_label  'en'
    taxon_id        1
    sort_order      1
    active          1
    created_at      { 48.hours.ago }
  end

  factory :service_type do
  end

  factory :sort_style do
  end

  factory :special_collection do
    name { generate(:string) }
  end

  factory :status do
  end

  factory :synonym_relation do
  end

  factory :synonym do
    association      :name
    synonym_relation { SynonymRelation.find_by_translated(:label, 'Synonym') ||
                           SynonymRelation.gen_if_not_exists(:label => 'Synonym') }
    language         { Language.english }
    association      :hierarchy_entry
    hierarchy_id     { hierarchy_entry ? hierarchy_entry.hierarchy.id : Hierarchy.default.id }
    preferred        1
    published        1
    vetted           { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
  end

  factory :taxon_concept do
    vetted         { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
    published      1
    vetted_id      0
    supercedure_id 0
    split_from     0
  end

  factory :taxon_data do

  end

  factory :taxon_concept_exemplar_image do
    association :taxon_concept
    association :data_object
  end

  factory :taxon_concept_exemplar_article do
    association :taxon_concept
    association :data_object
  end

  factory :taxon_concept_name do
    preferred              true
    vern                   false
    source_hierarchy_entry_id { FactoryGirl.create(:hierarchy_entry).id } # Does this work?
    language               { Language.english }
    association            :name
    association            :taxon_concept
  end

  factory :title_item do
    association  :publication_title
    bar_code     '73577357735742'
    marc_item_id 'i11604463' # I don't know what this is, but hey.
    call_number  'QK1 .H38'
    volume_info  '1864 v. 3'
    url          'http://www.biodiversitylibrary.org/item/ThisWontWork.OnlyTesting'
  end

  factory :toc_item do
    parent_id   0
    view_order  { generate(:int) + 1 } # The plus-one keeps this away from Overview, which should always be 1.
  end

  factory :top_image do
    association :hierarchy_entry
    association :data_object
    view_order  1                 # Perhaps this should be in a sequence, but I don't want to figure out how to persist the same HE
  end

  factory :top_unpublished_image do
    association :hierarchy_entry
    association :data_object
    view_order  1 # Again, this should be sequential, but...
  end

  factory :top_concept_image do
    association :taxon_concept
    association :data_object
    view_order  1
  end

  factory :top_unpublished_concept_image do
    association :taxon_concept
    association :data_object
    view_order  1
  end

  factory :translated_content_page do
    association         :content_page
    language            { Language.english }
    title               'Test Content Page'
    left_content        { "<h3>This is Left Content in a #{title}</h3>" }
    main_content        { "<h1>Main Content for #{title} ROCKS!</h1>" }
    meta_keywords       { "keywords for #{title}"}
    meta_description    { "description for #{title}"}
    active_translation  1
  end

  factory :topic_area do
    email   'user@domain.com'
  end

  factory :translated_topic_area do
    association       :topic_area
    language          { Language.english }
    label             'Topic Label'
  end

  factory :translated_activity do
    association :activity
    language    { Language.english }
    name        { generate(:string) }
  end

  factory :translated_contact_role do
    association     :contact_role
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_content_partner_data_type do
    association     :content_partner_data_type
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_agent_role do
    association     :agent_role
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_content_partner_status do
    association     :content_partner_status
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_audience do
    association     :audience
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_collection_type do
    association     :collection_type
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_contact_subject do
    association     :contact_subject
    language        { Language.english }
    title           { generate(:string) }
  end

  factory :translated_data_type do
    association     :data_type
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_info_item do
    association     :info_item
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_known_uri do
    association     :known_uri
    language        { Language.english }
    name            { generate(:string) }
  end

  factory :translated_link_type do
    association     :link_type
    language        { Language.english }
    label           { FactoryGirl.generate(:string) }
  end

  factory :translated_mime_type do
    association     :mime_type
    language        { Language.english }
    label           { FactoryGirl.generate(:string) }
  end

  factory :translated_language do
    label           { generate(:string) }
    original_language_id { Language.gen(:iso_639_1 => label[0..1].downcase).id }
    language        { Language.english }
  end

  factory :translated_license do
    association     :license
    language        { Language.english }
    description     { generate(:string) }
  end

  factory :translated_permission do
    association :permission
    language    { Language.english }
    name        { generate(:string) }
  end

  factory :translated_news_item do
    association     :news_item
    language        { Language.english }
    body            { 'Test News Item Body' + Faker::Lorem.paragraph }
    title           { Faker::Lorem.words[rand(4) + 1].titleize }
  end

  factory :translated_rank do
    association     :rank
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_resource_status do
    association     :resource_status
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_service_type do
    association     :service_type
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_sort_style do
    association :sort_style
    language    { Language.english }
    name        { generate(:string) }
  end

  factory :translated_status do
    association     :status
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_synonym_relation do
    association     :synonym_relation
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_toc_item do
    table_of_contents_id { TocItem.gen().id }
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_untrust_reason do
    association     :untrust_reason
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_user_identity do
    association     :user_identity
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_vetted do
    association     :vetted
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :translated_visibility do
    association     :visibility
    language        { Language.english }
    label           { generate(:string) }
  end

  factory :untrust_reason do
    updated_at Time.now
    created_at Time.now
    class_name { generate(:string) }
  end

  factory :user do
    admin                     false
    remote_ip                 { "123.45.67.1#{rand(10)}" }
    email                     { generate(:email) }
    given_name                { generate(:first_name) }
    family_name               { generate(:last_name) }
    agent_id                  { FactoryGirl.create(:agent, :full_name => "#{given_name} #{family_name}").id }
    language                  { Language.english }
    username                  do
      attempt = "#{given_name[0..0]}_#{family_name[0..9]}".gsub(/\s/, '_').downcase
      while(User.find_by_username(attempt)) do
        attempt.succ!
      end
      attempt
    end
    agreed_with_terms         true
    active                    true
    password                  'test password'
    entered_password          { password }
    curator_approved          false
    curator_verdict_by_id     nil
    curator_verdict_at        nil
    curator_scope             ''
    recover_account_token      nil
    recover_account_token_expires_at  nil
    curator_level_id          nil
    logo_cache_url            { generate(:user_logo) }
  end

  factory :user_activity_log do
    association :taxon_concept
    association :activity
    association :user
    value { generate(:string) }
    created_at { 12.hours.ago }
  end
  
  factory :worklist_ignored_data_object do
    association :user
    association :data_object
  end

  factory :user_added_data do
    association :subject, :factory => :taxon_concept
    predicate "http://somethinguseful.com/fake_ontology"
    object    { generate(:string) }
    association :user
    vetted      { Vetted.trusted || Vetted.gen_if_not_exists(:label => 'Trusted') }
    visibility  { Visibility.visible }
  end

  factory :user_added_data_metadata do
    association  :user_added_data
    predicate "http://somethinguseful.com/fake_ontology"
    object    { generate(:string) }
  end

  factory :users_data_object do
    association :data_object
    association :user
  end

  factory :user_info do
    areas_of_interest 'derp derp'
  end

  factory :user_identity do
    sort_order 1
  end

  factory :vetted do
    view_order 1
  end

  factory :visibility do
  end

  factory :google_analytics_summary do
    year { generate(:year) }
    month { generate(:month) }
    visits { rand(1000) }
    visitors { rand(100) }
    pageviews { rand(10000) }
    unique_pageviews { rand(1000) }
    ave_pages_per_visit { rand(100)/10.0 }
    ave_time_on_site { "00:%02d:%02d" % [rand(60), rand(60)] }
    ave_time_on_page { "00:%02d:%02d" % [rand(60), rand(60)] }
    per_new_visits { rand(100)/10.0 }
    bounce_rate { rand(100)/10.0 }
    per_exit { rand(100)/10.0 }
    taxa_pages { rand(1000) }
    taxa_pages_viewed { rand(100) }
    time_on_pages { rand(1000) }
  end

  factory :google_analytics_partner_summary do
    year { generate(:year) }
    month { generate(:month) }
    association :user
    taxa_pages { rand(1000) }
    taxa_pages_viewed { rand(100) }
    page_views { rand(10000) }
    unique_page_views { rand(1000) }
    time_on_page { rand(1000) }
  end

  factory :google_analytics_page_stat do
    association :taxon_concept
    year { generate(:year) }
    month { generate(:month) }
    page_views { rand(1000) }
    unique_page_views { rand(100) }
    time_on_page { "00:%02d:%02d" % [rand(60), rand(60)] }
  end

  factory :google_analytics_partner_taxon do
    association :taxon_concept
    association :user
    year { generate(:year) }
    month { generate(:month) }
  end

  factory :institutional_sponsor do
    name "Sponsor_name"
    logo_url "Sponosr_logo_url"
    url "Sponsor_url"
    active false
  end

end
