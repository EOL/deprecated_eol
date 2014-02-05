module EOL::LivesHere
  module SpecHelper

    def stub_request_mol(success = true)
      if success
        body = {
          success: true,
          results: [] # FIXME: waiting on finalized response structure
        }.to_json
      end
      stub_request(:get, /api.mol.org/).
        to_return(status: 200, body: body, headers: {})
    end

  end
end
