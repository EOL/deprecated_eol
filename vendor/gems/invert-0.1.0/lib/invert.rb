# Inverse comparison wrapper. Terribly useful to use with <tt>sort_by</tt> to do asc/desc multisorting per each key.
#
# Based on the post by glenn mcdonald:
#   http://stackoverflow.com/questions/73032/how-can-i-sort-by-multiple-conditions-with-different-orders
#   http://stackoverflow.com/users/7919/glenn-mcdonald
#
# Examples:
#   [1, 2, 3].sort_by {|i| Invert(i)}                           # => [3, 2, 1]
#   ["alfa", "bravo", "charlie"].sort_by {|s| Invert(s)}        # => ["charlie", "bravo", "alfa"]
#
# Multi-sort:
#   users.sort_by {|r| [Invert(r.age), r.name]}

# Wrap an object to invert <tt><=></tt> method.
#   items.sort_by {|r| [r.prop1, Invert.new(r.prop2)]}
class Invert
  attr_reader :r

  def initialize(r)
    @r = r
  end

  def <=>(other)
    -(@r <=> other.r)
  end
end

# A shortened form of <tt>Invert.new</tt>.
#   items.sort_by {|r| [r.prop1, Invert(r.prop2)]}
def Invert(*args)
  Invert.new(*args)
end
