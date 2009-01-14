# This is a database-free activerecord model used for the agent contact forms
# which appear when a license isn't accepted.
class AgentContactForm < ActiveRecord::Base  
  self.abstract_class = true
  
  def create_or_update
    errors.empty?
  end
  
  def self.columns
    @columns ||= []
  end
  
  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
    reset_column_information
  end
  
  def self.reset_column_information
    generated_methods.each { |name| undef_method(name) }
    @column_names = @columns_hash = @content_columns = @dynamic_methods_hash = @read_methods = nil
  end

  # -------------------------------

  column :email, :string
  column :name, :string
  column :comment, :text
  column :subject, :string

  validates_presence_of :name, :comment
  validates_format_of :email,
     :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => 'is not a valid e-mail address'     
end