require "spec_helper"

describe ResourceValidation do

  it 'uses resource validation queue' do
    expect(ResourceValidation.class_eval { @queue }).to eq(:resource_validation)
  end

end
