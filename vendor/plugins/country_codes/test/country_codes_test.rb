require 'test/unit'
require 'yaml'

# Load and init
RAILS_ROOT = '.'
require File.dirname(__FILE__) + '/../lib/country_codes'
CountryCodes.load_countries_from_yaml

# Test
class CountryCodesTest < Test::Unit::TestCase
  def test_find_by_name  
    assert_equal 'AU', CountryCodes.find_by_name('Australia')[:a2]
    assert_equal 'JP', CountryCodes.find_by_name('Japan')[:a2]
  end
  
  def test_missing_find_by_name
    assert_nil CountryCodes.find_by_name('MissingCountry')[:name]
  end
  
  def test_find_by_a2
    assert_equal 'Australia', CountryCodes.find_by_a2('AU')[:name]
    assert_equal 'Japan',     CountryCodes.find_by_a2('JP')[:name]
  end
  
  def test_missing_find_by_a2
    assert_nil CountryCodes.find_by_a2('MissingCountry')[:name]
  end
  
  def test_find_by_a3
    assert_equal 'Australia', CountryCodes.find_by_a3('AUS')[:name]
    assert_equal 'Japan',     CountryCodes.find_by_a3('JPN')[:name]
  end
  
  def test_missing_find_by_a3
    assert_nil CountryCodes.find_by_a2('MissingCountry')[:name]
  end
  
  def test_find_by_numeric
    assert_equal 'Australia', CountryCodes.find_by_numeric(36)[:name]
    assert_equal 'Japan',     CountryCodes.find_by_numeric(392)[:name]    
  end

  def test_missing_find_by_numeric
    assert_nil CountryCodes.find_by_numeric(-1)[:name]
  end
  
  def test_case_and_string_insensitivity
    assert_equal 'Australia', CountryCodes.find_by_name('AUSTRALIA')[:name]
    assert_equal 'Australia', CountryCodes.find_by_name('aUsTrAlIa')[:name]
    assert_equal 'Australia', CountryCodes.find_by_a2('aU')[:name]
    assert_equal 'Australia', CountryCodes.find_by_a3('AuS')[:name]    
    assert_equal 'Australia', CountryCodes.find_by_numeric('36')[:name]        
  end
  
  def test_bad_find_by_bad_name
    begin
      CountryCodes.find_by_number_of_penguins(73)
      flunk
    rescue
      assert true
    end
  end
  
  def test_find_by_no_name
    begin
      CountryCodes.find_by_('What?!')
      flunk
    rescue
      assert true
    end
  end
  
  def test_find_by_nothing_at_all
    begin
      CountryCodes.find_by('Huh?!')
      flunk
    rescue
      assert true
    end
  end
  
  def test_not_handled_method
    begin
      CountryCodes.take_over_country('Australia')
      flunk
    rescue
      assert true
    end
  end
  
  def test_find_X_by_Y_valid
    assert_equal 'AU', CountryCodes.find_a2_by_name('Australia')
    assert_equal 'JPN', CountryCodes.find_a3_by_numeric(392)
    assert_equal 'NO', CountryCodes.find_a2_by_a2('NO')
  end
  
  def test_find_X_by_Y_around_the_block
    # Isn't this fun! :)
    assert_equal 'Australia', CountryCodes.find_name_by_numeric(CountryCodes.find_numeric_by_a3(CountryCodes.find_a3_by_a2(CountryCodes.find_a2_by_name('Australia'))))
  end
  
  def test_find_X_by_T_invalid
    begin
      CountryCodes.find_name_by_magic('Abracadabra!')
      flunk
    rescue
      assert true
    end
    
    begin
      CountryCodes.find_magic_by_name('FooBar')
      flunk
    rescue
      assert true
    end
    
    begin
      CountryCodes.find_magic_by_magic('Roar')
      flunk
    rescue
      assert true
    end
  end
  
  def test_countries_for_select
    # Correct type is returned
    assert CountryCodes.countries_for_select('name').is_a?(Array)
  end
  
  def test_countries_for_select_works_for_each_attribute
    # Correct number of countries returned
    assert_equal 246, CountryCodes.countries_for_select('name').size
    assert_equal 246, CountryCodes.countries_for_select('a2').size
    assert_equal 246, CountryCodes.countries_for_select('a3').size
    assert_equal 246, CountryCodes.countries_for_select('numeric').size        
  end
  
  def test_countries_for_select_missing_attributes
    begin
      CountryCodes.countries_for_select
      flunk
    rescue
      assert true
    end
  end
  
  def test_countries_for_select_wrong_attribute
    begin
      CountryCodes.countries_for_select('number_of_ninjas')
      flunk
    rescue
      assert true
    end
  end
  
  def test_countries_for_select_mixed_good_and_bad_attributes
    begin
      CountryCodes.countries_for_select('name', 'number_of_ninjas')
      flunk
    rescue
      assert true
    end
  end
  
  def test_countries_for_select_multiple_attributes
    countries_by_name_and_a2 = CountryCodes.countries_for_select('name', 'a2')
    
    # Are we still getting the right number of results
    assert_equal 246, countries_by_name_and_a2.size
    
    # Lets look at a single result and check the information we're getting (and that it's ordered correctly!)
    australia = countries_by_name_and_a2.select { |c| c.first == 'Australia' }.flatten
    assert australia
    assert_equal 2, australia.size
    assert_equal 'Australia', australia[0]
    assert_equal 'AU', australia[1]
  end
  
  def test_countries_For_select_duplicate_attributes
    assert_equal 246, CountryCodes.countries_for_select('a2', 'a2', 'name', 'a2').size
  end
end
