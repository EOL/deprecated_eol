
Inverse Comparison Wrapper
==========================

Introduction
------------

To <tt>sort_by</tt> in reverse order, use the <tt>Invert</tt> wrapper supplied in this gem.

This gem is based on post by **glenn mcdonald**:

* [http://stackoverflow.com/questions/73032/how-can-i-sort-by-multiple-conditions-with-different-orders](http://stackoverflow.com/questions/73032/how-can-i-sort-by-multiple-conditions-with-different-orders)
* [http://stackoverflow.com/users/7919/glenn-mcdonald](http://stackoverflow.com/users/7919/glenn-mcdonald)


Setup
-----

    $ gem sources --add http://rubygems.org
    $ gem install invert


Examples
--------

    [1, 2, 3].sort_by {|i| Invert(i)}                           # => [3, 2, 1]
    ["alfa", "bravo", "charlie"].sort_by {|s| Invert(s)}        # => ["charlie", "bravo", "alfa"]

Multi-sort:
    users.sort_by {|r| [Invert(r.age), r.name]}


Feedback
--------

Send bug reports, suggestions and criticisms through [project's page on GitHub](http://github.com/dadooda/invert).
