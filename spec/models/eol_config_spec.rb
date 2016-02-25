require "spec_helper"

describe 'EolConfig' do

  EOL_CONFIG_DEFAULTS = [
    :email_actions_to_curators,
    :email_actions_to_curators_address,
    :global_site_warning,
    :all_users_can_see_data,
    :reference_parsing_enabled,
    :reference_parser_pid,
    :reference_parser_endpoint,
    :notification_error_user_id ]

  describe '.create_defaults' do

    before(:all) do
      EolConfig.delete_all
      Rails.cache.clear
      EolConfig.create_defaults
    end

    EOL_CONFIG_DEFAULTS.each do |which|
      next if which == :global_site_warning
      it "should create #{which}" do
        expect(EolConfig.find_by_parameter(which)).to_not be_nil
      end
    end

  end

  describe '.global_site_warning' do

    before do
      EolConfig.clear_global_site_warning
    end

    subject { EolConfig.global_site_warning }

    it { should be_nil } # by default...

    it 'should be nil' do
      EolConfig.create(parameter: 'global_site_warning', value: "  ")
      expect(subject).to be_nil
    end

    # logic has been changed; check the code 
    # it 'should read value from DB' do
      # EolConfig.create(parameter: 'global_site_warning', value: "hello")
      # expect(subject).to eq("hello")
    # end

    # it 'should NOT read from the DB after caching' do
      # EolConfig.create(parameter: 'global_site_warning', value: "hello")
      # expect(subject).to eq("hello")
      # EolConfig.delete_all
      # expect(subject).to eq("hello")
    # end

  end

  describe '.clear_global_site_warning' do

    before do
      EolConfig.clear_global_site_warning
    end

    it 'should delete global_site_warning from DB' do
      EolConfig.create(parameter: 'global_site_warning', value: "hello")
      expect(EolConfig.exists?(parameter: 'global_site_warning')).to be_false
     end

    it 'should cause the value to be nil' do
      EolConfig.create(parameter: 'global_site_warning', value: "hello")
      expect(EolConfig.global_site_warning).to be_nil
    end

  end

  describe 'created methods' do

    before(:all) do
      EolConfig.create_defaults
    end

    EOL_CONFIG_DEFAULTS.each do |which|
      it "should define ##{which}" do
        expect { EolConfig.send(which) }.to_not raise_exception
        # NOTE - this will only work AFTER _which_ has been called.
        expect(EolConfig.respond_to?(which)).to be_true
      end
    end

    # NOTE - this allows the convention of
    #
    #        value = EolConfig.some_param rescue 'default value'
    #
    # ...for the record, I don't think that's the most elegant thing to do, but hey.
    it 'raises an exception if undefined' do
      expect { EolConfig.this_does_not_exist }.to raise_exception
    end

  end

end
