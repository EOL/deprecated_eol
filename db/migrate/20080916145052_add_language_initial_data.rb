class AddLanguageInitialData < ActiveRecord::Migration
  def self.up
    
    # had to use new instead of create since we want to specify custom IDs for these languages
    unless Language.find_by_id(1)
        l=Language.new(:name=>'English', :label=>'',:iso_639_1=>'en', :iso_639_2=>'', :iso_639_3=>'',:sort_order=>'1', :source_form => '',:activated_on=>'2008-01-01 00:00:00')
        l.id=1
        l.save
    end

    unless Language.find_by_id(2)    
      l=Language.new(:name=>'Francais', :label=>'',:iso_639_1=>'fr', :iso_639_2=>'', :iso_639_3=>'',:sort_order=>'2', :source_form => '',:activated_on=>'2008-01-01 00:00:00')
      l.id=2
      l.save    
    end
        
    unless Language.find_by_id(3)    
      l=Language.new(:name=>'Deutsch', :label=>'',:iso_639_1=>'de', :iso_639_2=>'', :iso_639_3=>'',:sort_order=>'3', :source_form => '',:activated_on=>'2008-01-01 00:00:00')
      l.id=3
      l.save
    end
    
    unless Language.find_by_id(4)    
      l=Language.new(:name=>'Russian', :label=>'',:iso_639_1=>'ru', :iso_639_2=>'', :iso_639_3=>'',:sort_order=>'4', :source_form => '',:activated_on=>'2008-01-01 00:00:00')
      l.id=4
      l.save
    end
    
    unless Language.find_by_id(5)    
      l=Language.new(:name=>'Ukrainian', :label=>'',:iso_639_1=>'ua', :iso_639_2=>'', :iso_639_3=>'',:sort_order=>'5', :source_form => '',:activated_on=>'2008-01-01 00:00:00')
      l.id=5
      l.save
    end
    
    unless Language.find_by_id(501)    
      l=Language.new(:name=>'', :label=>'',:iso_639_1=>'scient', :iso_639_2=>'', :iso_639_3=>'',:sort_order=>'1', :source_form => '')
      l.id=501
      l.save
    end
        
  end

  def self.down
    Language.delete(1)
    Language.delete(2)
    Language.delete(3)
    Language.delete(4)
    Language.delete(5)
    Language.delete(501)
  end
end
