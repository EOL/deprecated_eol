# See https://github.com/rspec/rspec-rails/blob/master/spec/rspec/rails/mocks/mock_model_spec.rb
# In model spec use:
#   let(:model) { ModelToTest.new(params) }
#   it_behaves_like 'ActiveModel'

shared_examples_for "ActiveModel" do
  require 'active_model/lint'
  include ActiveModel::Lint::Tests

  ActiveModel::Lint::Tests.public_instance_methods.map { |method| method.to_s }.grep(/^test/).each do |method|
    example(method.gsub('_', ' ')) { send method }
  end

  def model
    subject
  end

end
