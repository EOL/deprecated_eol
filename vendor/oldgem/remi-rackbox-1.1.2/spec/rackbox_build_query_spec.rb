require File.dirname(__FILE__) + '/spec_helper'

# add String#unescape to make spec more readable
# 'user[name]=bob' is more readable than 'user%5Bname%5D=bob'
class String
  def unescape
    Rack::Utils.unescape self
  end
end

describe RackBox, 'build_query' do

  it 'should support single variable' do
    RackBox.build_query( :hello => 'there' ).unescape.should =='hello=there'
  end

  it 'should support multiple variables' do
    result = RackBox.build_query( :hello => 'there', :foo => :bar ).unescape
    ['hello=there&foo=bar', 'foo=bar&hello=there'].should include(result) # could come in any order!
  end

  it 'should support inner hashes' do
    result = RackBox.build_query( :user => { :name => 'bob', :password => 'secret' } ).unescape
    result.should include('user[name]=bob')
    result.should include('user[password]=secret')
  end

  it 'should support inner inner inner ... hashes' do
    result = RackBox.build_query( :a => { :b => { :c => 'IamC' }, :x => 'xXx' }, :y => 'x' ).unescape
    result.should include('a[b][c]=IamC')
    result.should include('a[x]=xXx')
    result.should include('y=x')
  end

end
