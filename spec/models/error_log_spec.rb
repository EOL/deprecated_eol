require "spec_helper"

describe ErrorLog do

  let(:error_log) { ErrorLog.new }

  describe '#display_backtrace' do

    it 'puts breaks in the backtrace' do
      allow(error_log).to receive(:backtrace) { %Q{foo\nand", "quotes} }
      expect(error_log.display_backtrace).to eq('foo<br />and<br />quotes')
    end

    it 'tells us when there is no backtrace' do
      expect(error_log.display_backtrace).to match(/no backtrace/)
    end

  end

end
