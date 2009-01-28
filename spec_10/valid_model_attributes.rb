# This is where we defined the hashes of valid_attributes for creating valid models
#
# see ValidActiveRecordAttributes for usage
module ValidModelAttributes
  def agent
    {
      :email => 'anagent@example.com',
      :created_at => 5.days.ago.to_s(:db),
      :homepage => "",
      :full_name => "An Agent",
      :username => 'an_agent',
      :password => 'test',
      :password_confirmation => 'test',
      :hashed_password => '098f6bcd4621d373cade4e832627b4f6', # test
      :agent_status_id => 2
    }
  end
  def agent_role
    {
      :label => 'Author'
    }
  end
  def comment
    {
      :parent_id => ( DataObject.first || DataObject.create_valid ).id,
      :parent_type => 'data_object',
      :body => 'This data object is the friggin COOLEST!',
      :dependencies => %w( user )
    }
  end
  def content_partner
    {
      :created_at => 5.days.ago.to_s(:db),
      :description_of_data => "",
      :notes => "blah",
      :dependencies => %w( agent )
    }
  end
  def curator_activity
    {
      :code => 'approve'
    }
  end
  def curator_data_object_log
    {
      :dependencies => %w( user data_object curator_activity )
    }
  end
  def curator_comment_log
    {
      :dependencies => %w( user comment curator_activity )
    }
  end
  def data_type
    {
      :label => 'Image',
      :schema_value => ''
    }
  end
  def data_object
    {
      :guid => '',
      :rights_statement => '',
      :rights_holder => '',
      :thumbnail_url => '',
      :thumbnail_cache_url => '',
      :bibliographic_citation => '',
      :description => '',
      :object_title => '',
      :source_url => '',
      :object_url => '',
      :object_cache_url => '',
      :location => '',
      :latitude => 1.0,
      :longitude => 1.0,
      :altitude => 1.0,
      :data_rating => 1.0,
      :vetted_id => 2,
      :dependencies => %w( data_type mime_type language license visibility )
    }
  end
  def visibility
    {
      :label => 'Visibile'
    }
  end
  def data_object_log
    {
      :user_agent => 'firefox',
      :ip_address_raw => '1.2.3.4',
      :dependencies => %w( ip_address user data_object data_type agent )
    }
  end
  def data_object_tag
    {
      :key => 'chunky',
      :value => 'bacon'
    }
  end
  def data_object_tags
    {
      :dependencies => %w( data_object data_object_tag )
    }
  end
  def ip_address
    {
      :number => 16909060,
      :country_code => 'US',
      :success => true,
      :state => 'AZ',
      :latitude => 33.7788,
      :longitude => 117.959,
      :provider => 'test'
    }
  end
  def log_daily
    {
      :day => Date.today,
      :total => 0,
      :user_agent => 'Mozilla/Firefox',
      :data_type_id => DataType.first.id # <== don't do this!  gotta fix it ...
    }
  end
  def mime_type
    {
      :label => 'text/plain'
    }
  end 
  def language
    {
      :name => 'English',
      :label => 'en',
      :iso_639_1 => '',
      :iso_639_2 => '',
      :iso_639_3 => '',
      :source_form => ''
    }
  end
  def license
    {
      :title => 'Creative Commons',
      :source_url => '',
      :version => '1.0',
      :logo_url => '',
      :description => 'a neato license'
    }
  end
  def role
    {
      :title => 'Super Admin'
    }
  end
  def user
    {
      :default_taxonomic_browser => 'text',
      :expertise => 'middle',
      :remote_ip => '128.167.250.123',
      :content_level => 2,
      :email => 'this_is_crap@fake.com',
      :given_name => 'John',
      :family_name => 'Smith',
      :flash_enabled => true,
      :mailing_list => true,
      :vetted => false,
      :credentials => '',
      :username => 'jsmith',
      :active => true,
      :hashed_password => Digest::MD5.hexdigest('secret squirrel'),
      :entered_password => "secret squirrel",
      :dependencies => %w( language )
    }
  end
end

# Gives us a pretty syntax for getting valid attributes: ValidAttributesFor.model_name
class ValidAttributesFor
  extend ValidModelAttributes

  def self.method_missing *args
    raise "No valid attributes defined for model: #{args.first}"
  end
end
