class PageJson < ActiveRecord::Base
  @MAX_AGE = 2.weeks

  attr_accessible :ld, :page_id

  belongs_to :page, class_name: "TaxonConcept", foreign_key: "page_id", inverse_of: :page_json

  def self.for(page_id, options = {})
    if PageJson.exists?(page_id: page_id)
      pj = PageJson.find_by_page_id(page_id)
      if pj.updated_at < @MAX_AGE.ago
        pj.build_json(options[:traits])
        pj.save
      end
      pj
    else
      pj = PageJson.new(page_id: page_id)
      pj.build_json(options[:traits])
      pj
    end
  end

  def build_json(traits = nil)
    self[:ld] = TraitBank::JsonLd.data_feed_item(self[:page_id], traits))
    self[:ld] = self[:ld]
  end
end
