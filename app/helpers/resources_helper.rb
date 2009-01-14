module ResourcesHelper

  def frequency(hours)
    freq = ''
    case hours
      when 0
        freq = 'Import Once'
      when 7 * 24
        freq = 'Weekly'  
      when 30 * 24
        freq = 'Monthly'  
      when 60 * 24
        freq = 'Bi-Monthly'  
      when 91 * 24
        freq = 'Quarterly'  
      else
        freq = hours.blank? ? '' : "#{hours} hours" 
    end
    freq
  end
end
