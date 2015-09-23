# encoding: utf-8
class Rank < ActiveRecord::Base
  uses_translations
  has_many :hierarchy_entries
  has_many :group_members, conditions: {rank_group_id: "!= 0"}, class_name: 'Rank',
    primary_key: 'rank_group_id', foreign_key: 'rank_group_id'
  belongs_to :rank_group, class_name: 'Rank', foreign_key: 'rank_group_id'

  def self.kingdom
    cached_find_translated(:label, 'kingdom', include: :group_members)
  end

  def self.phylum
    cached_find_translated(:label, 'phylum', include: :group_members)
  end

  def self.class_rank
    cached_find_translated(:label, 'class', include: :group_members)
  end

  def self.order
    cached_find_translated(:label, 'order', include: :group_members)
  end

  def self.family
    cached_find_translated(:label, 'family', include: :group_members)
  end

  def self.genus
    @@genus ||= cached_find_translated(:label, 'genus', include: :group_members)
  end

  def self.species
    @@species ||= cached_find_translated(:label, 'species', include: :group_members)
  end

  def self.subspecies
    @@subspecies ||= cached_find_translated(:label, 'subspecies', include: :group_members)
  end

  def self.variety
    @@variety ||= cached_find_translated(:label, 'variety', include: :group_members)
  end

  def self.infraspecies
    @@infraspecies ||= cached_find_translated(:label, 'infraspecies', include: :group_members)
  end

  # Stolen from PHP:
  def self.species_ranks
    return @species_ranks if @species_ranks
    ranks = []
    ranks << Rank.species
    ranks << cached_find_translated(:label, 'sp', include: :group_members)
    ranks << cached_find_translated(:label, 'sp.', include: :group_members)
    ranks << Rank.subspecies
    ranks << cached_find_translated(:label, 'subsp', include: :group_members)
    ranks << cached_find_translated(:label, 'subsp.', include: :group_members)
    ranks << Rank.variety
    ranks << cached_find_translated(:label, 'var', include: :group_members)
    ranks << cached_find_translated(:label, 'var.', include: :group_members)
    ranks << Rank.infraspecies
    ranks << cached_find_translated(:label, 'form', include: :group_members)
    ranks << cached_find_translated(:label, 'nothospecies', include: :group_members)
    ranks << cached_find_translated(:label, 'nothosubspecies', include: :group_members)
    ranks << cached_find_translated(:label, 'nothovariety', include: :group_members)
    @species_ranks = ranks
  end

  def self.species_rank_ids
    species_ranks.map(&:id)
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
