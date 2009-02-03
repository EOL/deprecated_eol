activerecord-comments
=====================

Super-duper simple gem for getting table/column comments defined in the database.

Background
----------

I wanted a way to easily get to the comments defined in the database, via ActiveRecord. 
While the underlying implementation may change to become faster and more database agnostic, 
the public API should remain the same.

Install
-------

    $ sudo gem install remi-activerecord-comments -s http://gems.github.com

Usage
-----

    >> require 'activerecord-comments'
    
    >> Fox.comment
    => "Represents a Fox, a creature that craves chunky bacon"

    >> ActiveRecord::Base.comment :foxes
    => "Represents a Fox, a creature that craves chunky bacon"

    >> ActiveRecord::Base.connection.comment :foxes
    => "Represents a Fox, a creature that craves chunky bacon"

    >> Fox.columns
    => [#<ActiveRecord::...>, #<ActiveRecord::...>]

    >> Fox.columns.first.name
    => "id"

    >> Fox.columns.first.comment
    => "Primary Key"

    >> Fox.column_comment :id
    => "Primary Key"

    >> ActiveRecord::Base.column_comment :id, :foxes
    => "Primary Key"

    >> ActiveRecord::Base.connection.column_comment :id, :foxes
    => "Primary Key"


Database Support
----------------

For right now, I'm just supporting MySQL as it's the only database I'm currently using 
that supports database comments.

If you want to extend activerecord-comments to support comments for your favorite database, 
the gem is coded in such a way that it should be really easy to extend.

See [mysql_adapter.rb][mysql_adapter] for an example of the methods your database adapter 
needs to support (just `#comment(table)` and `#column_comment(column,table)`).


SQL
---

If you're unsure how to add comments to your MySQL tables/columns, most MySQL GUIs support 
this, or you can add comments to your `CREATE TABLE` declarations ...

    CREATE TABLE foo ( 
      id INT COMMENT 'i am the primary key', 
      foo VARCHAR(100) COMMENT 'foo!' 
    ) COMMENT 'this table rocks'

for more MySQL examples, see [spec/mysql_comments_spec.rb][mysql_spec]


Future Ideas
------------

- create `db-doc` or (something) that provides a system for documenting your database schema, whether it be via .yml files or as database comments or whatever.  then make `activerecord-comments` an extension to that (basically just a different data store for your schema documentation).  there should always be a way to easily document your schema, regardless of whether or not your database(s) supports comments.  and, with or without database comments, there should be an easy way to see which tables/columns you have and haven't documented!


[mysql_adapter]: http://github.com/remi/activerecord-comments/tree/master/lib/activerecord-comments/mysql_adapter.rb
[mysql_spec]:    http://github.com/remi/activerecord-comments/tree/master/spec/mysql_comments_spec.rb
