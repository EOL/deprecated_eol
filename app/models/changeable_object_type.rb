class ChangeableObjectType < ActiveRecord::Base

    has_many :actions_histories

    validates_presence_of   :ch_object_type
    validates_uniqueness_of :ch_object_type

  end

  # == Schema Info
  # Schema version: 20090611220129_create_changeable_object_types
  #
  # Table name: changeable_object_types
  #
  # id              int(11)       not null, primary key
  # ch_object_type	varchar(255)	utf8_general_ci
  # created_at      datetime
  # updated_at      datetime
