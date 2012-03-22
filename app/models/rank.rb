class Rank < ActiveRecord::Base
  uses_translations
  has_many :hierarchy_entries
  has_many :group_members, :class_name => 'Rank', :primary_key => 'rank_group_id', :foreign_key => 'rank_group_id', :conditions => 'rank_group_id!=0'
  
  def self.kingdom
    cached_find_translated(:label, 'kingdom')
  end
  
  def self.phylum
    cached_find_translated(:label, 'phylum')
  end
  
  def self.class_rank
    cached_find_translated(:label, 'class')
  end
  
  def self.order
    cached_find_translated(:label, 'order')
  end
  
  def self.family
    cached_find_translated(:label, 'family')
  end
  
  def self.genus
    cached_find_translated(:label, 'genus')
  end
  
  def self.species
    cached_find_translated(:label, 'species')
  end
  
  def self.subspecies
    cached_find_translated(:label, 'subspecies')
  end
  
  def self.variety
    cached_find_translated(:label, 'variety')
  end
  
  def self.infraspecies
    cached_find_translated(:label, 'infraspecies')
  end
  
  
  def self.english_rank_labels_to_translate
    [ 'class', 'division', 'f', 'fam', 'family', 'form', 'forma', 'gen', 'genus', 'infraorder',
      'infraspecies', 'kingdom', 'nothogenus', 'nothospecies', 'nothosubspecies', 'nothovariety',
      'order', 'phylum', 'sect', 'section', 'series', 'sp', 'species', 'sub-family', 'subclass',
      'subdivision', 'subfamily', 'subgen', 'subgenus', 'subkingdom', 'suborder', 'subphylum',
      'subsection', 'subseries', 'subsp', 'subspecies', 'subtribe', 'superfamily', 'superphylum',
      'tribe', 'unranked', 'var', 'varietas', 'variety']
  end
  
  def self.italicized_labels
    ['?var',          'binomial',      'biovar',
     'Espéce',        'especie',       '',
     'f.',            'f.sp.',         'form',
     'forma',         'infra-form',    'infra-species',
     'infra-variety', 'infraspecies',  'infravariety',
     'micro-species', 'microspecies',  'nohtosubsp',
     'nopthosubsp',   'notho species', 'nothof',
     'nothosubsp',    'nothosupsp',    'nothovar',
     'nssp',          'nsubsp',        'quadrinomial',
     'sbsp',          'sebsp',         'SP',
     'sp.',           'sp.-group',     'species',
     'species forma', 'species group', 'species subgroup',
     'specio',        'ssp',           'ssp.',
     'sub-form',      'sub-forma',     'sub-species',
     'sub-variety',   'subform',       'subfsp',
     'subsp',         'subsp.',        'subspecies',
     'subspecific',   'subspsp',       'subv',
     'subvar',        'subvar.',       'subvar. [?]',
     'subvarietas',   'subvariety',    'subvarsp',
     'supsp',         'susbp',         'susbsp',
     'susp',          'trinomial',     'var',
     'var.',          'variety',       'varsp']
  end

  def self.italicized_ids
    @@italicized_rank_ids ||= cached('italicized') do 
      Rank.find_by_sql("SELECT r.* FROM ranks r JOIN translated_ranks rt ON (r.id=rt.rank_id) WHERE rt.label IN ('#{italicized_labels.join('\',\'')}') AND rt.language_id=#{Language.english.id}").map(&:id)
    end
  end
  
  def self.tcs_codes
    #TODO - we could add a code column to the table, but these codes are specific to the Taxon Concept Schema
    cached('codes') do
      { 'kingdom'     => 'reg',
        'phylum'      => 'phyl_div',
        'class'       => 'cl',
        'subclass'    => 'subcl',
        'order'       => 'ord',
        'suborder'    => 'subord',
        'superfamily' => 'superfam',
        'family'      => 'fam',
        'subfamily'   => 'subfam',
        'genus'       => 'gen',
        'species'     => 'sp',
        'sp'          => 'sp' }
    end
  end
  
  def tcs_code
    if c = Rank.tcs_codes.include?(label.downcase)
      return Rank.tcs_codes.fetch(label.downcase)
    end
    return nil
  end

end
