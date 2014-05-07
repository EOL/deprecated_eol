require "spec_helper"

describe SearchLog do

  describe '.log' do

    let(:request) do
      double("request", remote_ip: "12.34.56.7",
                        user_agent: "agent",
                        url: "some_url")
    end

    before do
      allow(SearchLog).to receive(:create) { "result" }
    end

    it 'returns nil with blank params' do
      expect(SearchLog.log({}, request, nil)).to be_nil
      expect(SearchLog).to_not have_received(:create)
    end

    it 'defaults to #ip2int on remote_ip' do
      allow(IpAddress).to receive(:ip2int) { "converted" }
      SearchLog.log({a:'b'}, request, nil)
      expect(IpAddress).to have_received(:ip2int).with("12.34.56.7")
      expect(SearchLog).to have_received(:create) do |opts|
        expect(opts[:ip_address_raw]).to eq("converted")
      end
    end

    it 'defaults to user_agent from request' do
      allow(request).to receive(:user_agent) { "fred" }
      SearchLog.log({a:'b'}, request, nil)
      expect(SearchLog).to have_received(:create) do |opts|
        expect(opts[:user_agent]).to eq("fred")
      end
    end

    it 'defaults to "unknown" user_agent when nil' do
      allow(request).to receive(:user_agent) { nil }
      SearchLog.log({a:'b'}, request, nil)
      expect(SearchLog).to have_received(:create) do |opts|
        expect(opts[:user_agent]).to eq("unknown")
      end
    end

    it 'defaults to request url' do
      allow(request).to receive(:path) { "of forgiveness" }
      SearchLog.log({a:'b'}, request, nil)
      expect(SearchLog).to have_received(:create) do |opts|
        expect(opts[:path]).to eq("of forgiveness")
      end
    end

    it 'defaults to "unknown" url when nil' do
      allow(request).to receive(:path) { nil }
      SearchLog.log({a:'b'}, request, nil)
      expect(SearchLog).to have_received(:create) do |opts|
        expect(opts[:path]).to eq("unknown")
      end
    end

    it 'adds user_id when provided' do
      SearchLog.log({a:'b'}, request, double(User, id: 5746))
      expect(SearchLog).to have_received(:create) do |opts|
        expect(opts[:user_id]).to eq(5746)
      end
    end

    it 'allows override of ip_address_raw, user_agent, and path' do
      SearchLog.log({ip_address_raw: 'this',
                     user_agent: 'that',
                     path: 'other'}, request, nil)
      expect(SearchLog).to have_received(:create) do |opts|
        expect(opts[:ip_address_raw]).to eq('this')
        expect(opts[:user_agent]).to eq('that')
        expect(opts[:path]).to eq('other')
      end
    end

    it 'returns the result of #create' do
      expect(SearchLog.log({a:'b'}, request, nil)).to eq("result")
    end

  end

  describe '.click_times_by_taxon_concept_id' do

    # NOTE - this is only used by admins and is a nasty SQL query.
    # ...not going to test it deeply, just run it as sanity check:
    it 'runs a #find_by_sql' do
      allow(SearchLog).to receive(:find_by_sql) {"yo"}
      expect(SearchLog.click_times_by_taxon_concept_id(1)).to eq("yo")
      expect(SearchLog).to have_received(:find_by_sql)
    end

  end

  describe '.paginated_report' do

    # NOTE - this is only used by admins and is a nasty SQL query.
    # ...not going to test it deeply, just run it as sanity check:
    it 'calls #paginate_by_sql on a sanitized array' do
      allow(SearchLog).to receive(:paginate_by_sql) {"done"}
      allow(ActiveRecord::Base).to receive(:sanitize_sql_array)
      expect(SearchLog.paginated_report).to eq("done")
      expect(SearchLog).to have_received(:paginate_by_sql)
    end

  end

  describe '.totals' do

    # NOTE - this is only used by admins and is a nasty SQL query.
    # ...not going to test it deeply, just run it as sanity check:
    # (TODO - if we keep this, re-write the code, it needn't be SQL.
    it 'runs a #find_by_sql' do
      allow(SearchLog).to receive(:find_by_sql)
      SearchLog.totals
      expect(SearchLog).to have_received(:find_by_sql)
    end

  end

end
