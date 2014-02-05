module EOL::LivesHere::Result
  class Mol < Base

    def valid?
      !@hash.nil? && @hash[:success]
    end

    private

    def parse
      return if @hash.nil?
      @taxon_groups = Hash[ @hash[:results].map do |h|
        [ h['class'], h['species'].collect{|s| s['eol_page_id']}.compact.uniq ]
      end ]
      @taxon_concept_ids = @hash[:results].collect do |h|
        h['species'].collect{|t| t['eol_page_id'].to_i}
      end.compact.flatten.uniq
    end

  end
end
