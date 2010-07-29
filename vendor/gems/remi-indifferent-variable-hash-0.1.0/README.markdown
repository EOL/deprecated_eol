Indifferent Variable Hash
=========================

This tiny library / gem could likely use a new name as "Indifferent Hash" 
can mean a number of things.

Here's what this let's you do:

    $ sudo gem install remi-indifferent-variable-hash -s http://gems.github.com
    $ irb

    >> require 'rubygems'
    >> require 'indifferent-variable-hash'

    # extend a class with IndifferentVariableHash

    >> class Dog
         extend IndifferentVariableHash
       end

    >> Dog.foo = 'bar'
    => "bar"

    >> Dog.foo
    => "bar"

    >> Dog.variables
    => {"foo"=>"bar"}

    >> Dog['foo']
    => "bar"

    >> Dog.new.foo
    NoMethodError: undefined method `foo' for #<Dog:0x7f37c87d87d0>
      from (irb):8
      from :0

    # include IndifferentVariableHash in a class, for instances

    >> class Dog
         include IndifferentVariableHash
       end

    >> Dog.new.foo
    => nil

    >> rover = Dog.new
    => #<Dog:0x7f37c87bfe38>

    >> rover.foo = 'bar'
    => "bar"

    >> rover.foo
    => "bar"

    >> rover[:foo]
    => "bar"

    >> rover.variables
    => {"foo"=>"bar"}

... why?
--------

Why not!  I often add functionality similar to this to some classes that hold config-like information.  eg. MyApp.config might return an object that includes IndifferentVariableHash so I can say `MyApp.config.foo = 'bar'` or `MyApp.config[:foo] = 'bar'`.  Alternatively, I might like the syntax `MyApp.foo = 'bar'` or `MyApp[:foo] = 'bar'` ... *OR* I might want both syntaxes, so I extend MyApp with IndifferentVariableHash but I also alias 'config' to 'variables.'

I use this often enough that I figured I should gem-ify it so I can easily use it in some of my projects, when I want it.

If it helps anyone else out there, so be it!  Enjoy  :)
