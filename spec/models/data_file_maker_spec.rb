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

  it 'prints the time that it is running' do
    time = Time.now
    allow(time).to receive(:strftime) { 'this is the strftime' }
    allow(Time).to receive(:now) { time }
    out = capture_stdout { DataFileMaker.perform(args) }
    expect(out).to match(/this is the strftime/)
  end

  it 'prints the values it is running' do
    out = capture_stdout { DataFileMaker.perform(args) }
    expect(out).to match(/#{dsf.id}/)
  end

  # NOTE - this is important because slave lag might cause us to miss a command entirely!
  it 'runs against master' do
    allow(DataSearchFile).to receive(:with_master) { nil }
    capture_stdout { DataFileMaker.perform(args) }
    expect(DataSearchFile).to have_received(:with_master)
  end

  it 'assumes cancelation (and prints it) if missing' do
    allow(DataSearchFile).to receive(:exists?) { false }
    out = capture_stdout { DataFileMaker.perform(args) }
    expect(out).to match(/assuming canceled/)
    expect(DataSearchFile).to have_received(:exists?).with(dsf.id)
  end

  it 'runs :build_file on the instance' do
    allow(dsf).to receive(:build_file)
    capture_stdout { DataFileMaker.perform(args) }
    expect(dsf).to have_received(:build_file)
  end

  it 'prints error messages' do
    allow(dsf).to receive(:build_file).and_raise("this error")
    out = capture_stdout { DataFileMaker.perform(args) }
    expect(out).to match(/this error/)
  end

end
