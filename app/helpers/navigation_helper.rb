module NavigationHelper
  def convert_to_nbsp(input_string)
    if input_string.nil? == false
      return input_string.gsub('&', '&amp;').gsub(' ','&nbsp;')
    else
      return ''
    end
  end
end
