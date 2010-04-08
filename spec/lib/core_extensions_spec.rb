require File.dirname(__FILE__) + '/../spec_helper'

describe String do

  describe "normalize" do
    
    it "should remove undesired characters" do
      ':;,.()[]!?*_\\/"\''.normalize.should == ''
    end

    it "should remove multiple spaces, tabs" do
      "a a  a   a    a".normalize.should == "a a a a a"
      "a\ta\t a\t\ta".normalize.should == "a a a a"
    end

    it "should remove tags" do
      "<i>a</i> a <>        <><>".normalize.should == "a a "
    end

    it "should covert ascii to lower case" do
      "ABCDEFG".normalize.should == "abcdefg"
    end

    it "should do all substitutions together" do 
      "abc<\t        i>a</i>:; ,.(Laddnda\t   )[]!?*_\\dd  \t  dd/\"'".normalize.should == "abca laddnda dd dd"
    end
  
  end

  describe 'sanitize HTML' do
    
    it 'should rescue "more" sign' do
      t1 = 'aaa >1 b'
      t1.sanitize_html.should == 'aaa &gt;1 b'
      
      t1 = 'aaa > 1 b'
      t1.sanitize_html.should == 'aaa &gt; 1 b'
      
    end
    
    
    it 'should understand tags before numbers' do
      # numbers only
      t1 = '<p><strong> 3       <em>DROSOPHILA</em> INFORMATION SERVICE</strong></p>'
      t1.sanitize_html.should == '<p><strong> 3       <em>DROSOPHILA</em> INFORMATION SERVICE</strong></p>'
      
      t2 = '<strong>1<em>–</em>14</strong>'
      t2.sanitize_html.should == '<strong>1<em>–</em>14</strong>'      
      
      t3 = 'E. Novitski, who was editor for many years, reissued all but the  ephemera of <em>DIS</em> <strong>1<em>–</em>14</strong> and <em>DIS</em> <strong>15<em>–</em>24</strong> in single volumes. Back issues  of <em>DIS</em> may be available from the  editor.</p>'
      t3.sanitize_html.should == 'E. Novitski, who was editor for many years, reissued all but the  ephemera of <em>DIS</em> <strong>1<em>–</em>14</strong> and <em>DIS</em> <strong>15<em>–</em>24</strong> in single volumes. Back issues  of <em>DIS</em> may be available from the  editor.'
      
      t4 = '(Figs. <a href="http://www.morphbank.net/Show/?pop=Yes&amp;id=464802" target="_blank">7</a>-<a href="http://www.morphbank.net/Show/?pop=Yes&amp;id=464803" target="_blank">8</a>).'
      t4.sanitize_html.should == '(Figs. <a href="http://www.morphbank.net/Show/?pop=Yes&amp;id=464802" target="_blank">7</a>-<a href="http://www.morphbank.net/Show/?pop=Yes&amp;id=464803" target="_blank">8</a>).'
      
      # numbers and letters between tags
      t5 = '<li>1925<em>–</em>39     Muller, H.J. 1939. <em>Bibliography on the genetics of</em> <em>Drosophila</em>.  Imperial Bureau of Animal Breeding and Genetics. Oliver and Boyd, Edinburgh.  (2965 References indexed in Part II.)</li>'
      t5.sanitize_html.should == '<li>1925<em>–</em>39     Muller, H.J. 1939. <em>Bibliography on the genetics of</em> <em>Drosophila</em>.  Imperial Bureau of Animal Breeding and Genetics. Oliver and Boyd, Edinburgh.  (2965 References indexed in Part II.)</li>'
    end    
  end
end


describe Array do
  it 'should group hashes by an attribute' do
    arr = [{'id' => 2, 'value' => 'first'},
           {'id' => 1, 'value' => 'first'}]
    arr.group_hashes_by!('value')
    arr.length.should == 1
    arr[0]['id'].should == 2
  end
  
  it 'should group objects by an attribute' do
    obj = DataObject.gen
    obj2 = obj.clone
    obj2.id = 99999
    arr = [obj2, obj]
    
    arr.group_objects_by!('guid')
    arr.length.should == 1
    arr[0].id.should == obj2.id
  end
end




