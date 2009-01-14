# some helpful extensions

class Array

  # some methods on Hash return an Array like [ [key,value], [key,value] ] instead 
  # of returning a Hash.  this turns an Array of that style back into a Hash.
  def hashify
    inject({}) do |all,this|
      all[this.first] = this.last
      all 
    end
  end

end

class Hash

  # does the same as Array#hashify.
  #
  # assumes an Array like [ [key,value], [key,value] ]
  def self.from_array array
    array.hashify
  end

end
