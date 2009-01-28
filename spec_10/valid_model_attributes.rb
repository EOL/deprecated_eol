  def comment
    {
      :parent_id => ( DataObject.first || DataObject.create_valid ).id,
      :parent_type => 'data_object',
      :body => 'This data object is the friggin COOLEST!',
      :dependencies => %w( user )
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
