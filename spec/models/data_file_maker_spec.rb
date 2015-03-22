require "spec_helper"

describe DataFileMaker do

  let(:dsf)  { build_stubbed(DataSearchFile) }
  let(:args) { { "data_file_id" => dsf.id } }

  before do
    # NOT NEEDED: allow(DataSearchFile).to receive(:with_master)
    allow(DataSearchFile).to receive(:exists?) { true }
    allow(DataSearchFile).to receive(:find) { dsf }
    allow(dsf).to receive(:build_file) { nil }
  end

  # NOTE - Resque always uses this class variable to know which queue to run in.
  it 'runs in data queue' do
    expect(DataFileMaker.instance_eval { @queue }).to eq('data')
  end

  it 'runs against master' do
    allow(DataSearchFile).to receive(:with_master) { nil }
    DataFileMaker.perform(args)
    expect(DataSearchFile).to have_received(:with_master)
  end

  it 'assumes cancelation (and prints it) if missing' do
    allow(DataSearchFile).to receive(:exists?) { false }
    DataFileMaker.perform(args)
    expect(DataSearchFile).to have_received(:exists?).with(dsf.id)
  end

  it 'runs :build_file on the instance' do
    allow(dsf).to receive(:build_file)
    DataFileMaker.perform(args)
    expect(dsf).to have_received(:build_file)
  end

end
