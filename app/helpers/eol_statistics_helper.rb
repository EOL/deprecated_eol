module EolStatisticsHelper

  # Compares statistics for dates one and two and returns class names for both
  def greater(is_greatest = false)
    is_greatest ? 'greater' : nil
  end

end
