module EOL::LivesHere::Result
  class Base

    attr_accessor :response, :taxon_groups, :taxon_concept_ids

    def initialize(response)
      @response = response
      parse
    end

    def valid?
      fail
    end

    private

    def parse
      fail
    end

  end
end
