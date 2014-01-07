# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe HierarchyEntry do

  before :all do
    truncate_all_tables
  end

  it 'should know what is a species_or_below?' do
    # HE.rank_id cannot be NULL
    expect(HierarchyEntry.gen(rank_id: '0').species_or_below?).to eq(false)
    expect(HierarchyEntry.gen(rank: Rank.gen_if_not_exists(label: 'genus')).species_or_below?).to eq(false)
    # there are lots of ranks which are considered species or below
    expect(Rank.italicized_labels.length).to be >= 60
    Rank.italicized_labels[0..5].each do |rank_label|
      clear_rank_caches
      expect(HierarchyEntry.gen(rank: Rank.gen_if_not_exists(label: rank_label)).species_or_below?).to eq(true)
    end
  end

end
