# A normalized name is a unique part of a Name
#
# Name is broken down into parts, each of which is a NormalizedName.
#
# NormalizedName's are related to Name's via NormalizedLink.
#
# Example:
#
#   >> @name.string
#   => "Why Hello There"
#
#   >> @name.normalized_links.map do |link|
#        link.normalized_name.name_part 
#      end
#   => ['Why', 'Hello', 'There']  # <--- each of these name_parts is a NormalizedName
#
class NormalizedName < SpeciesSchemaModel

  has_many :normalized_links

  # Parse a Name or String into name_parts
  #
  # ==== Parameters
  # name<~to_s>::
  #   The string to parse into parts
  #
  # ==== Returns
  # Array(String)::
  #   The unique parts of the given name
  #
  def self.parse_into_parts name
    name.to_s.
      gsub(' and ',' '). # remove ' and ', useless word ... keep a space as a separator tho
      gsub(/[^\w ]/,''). # remove all non-alphanumeric characters
      gsub('_','').      # remove underscores (the previous line doesn't catch them for some reason)
      split              # split on spaces
  end

  # Parse a name into its parts (NormalizedNames)
  #
  # This will actually create NormalizedNames
  #
  # ==== Parameters
  # name<~to_s>::
  #   The string to parse into parts
  # 
  # ==== Returns
  # Array(NormalizedName)::
  #   NormalizedNames for the unique parts of the given name
  #
  def self.parse! name
    parse_into_parts(name).map do |name_part|
      NormalizedName.find_or_create_by_name_part(name_part)
    end
  end
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: normalized_names
#
#  id        :integer(4)      not null, primary key
#  name_part :string(100)     not null

