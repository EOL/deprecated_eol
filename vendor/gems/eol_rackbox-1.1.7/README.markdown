RackBox
=======

[RackBox][] adds [Merb][]-style [blackbox testing][blackbox] to [Rack][] apps (including [Rails][])

This currently only works with [RSpec][].

DEPRECATED
----------

**NOTE**: Although I really love the RackBox syntax (which was stolen from Merb's request spec), 
rack-test has gotten much more love than RackBox and I haven't had time to refactor RackBox.

I recommend using rack-test instead!  RackBox will likely be ported to a rack-test extension 
that provides the syntax I enjoy.

Screencast
----------

[Watch the 'Screencast'][screencast]

Installation
------------

    $ sudo gem install remi-rackbox -s http://gems.github.com

NOTE: right now, [RackBox][] requires [thin][].  Soon, I'll likely remove [thin][] as 
a dependency and will only require [rack][].

Rails (fast!)
-------------

    $ sudo gem install rspec rspec-rails thin
    $ sudo gem install remi-rackbox -s http://gems.github.com

    $ rails new_app
    $ cd new_app
    $ ./script/generate rspec
    $ ./script/generate blackbox_spec Home Page

    $ rake spec
    

Rails (manual)
--------------

To write [RackBox][] tests in [Rails][] apps, make a `blackbox` directory under your `spec` directory 
and add this to the Spec configure block in your `spec_helper.rb` file:

    config.use_blackbox = true

Also, add `require 'rackbox'` to the top of your `spec_helper.rb`

You can see a working example of blackbox testing a [Rails][] application here: [examples/rails](http://github.com/remi/rackbox/tree/master/examples/rails)

Rack
----

To write [RackBox][] tests in [Rack][] apps, I'm currently assuming that you have a `config.ru` rackup file. 
If so, your app should load, otherwise you can explicitly configure [RackBox][] to read your [Rack][] app:

    RackBox.app = [your Rack app]

Basides that, the configuration is the same as [Rails][].  Make a `blackbox` directory under your 
`spec` directory and add this to the Spec configure block in your `spec_helper.rb` file:

    config.use_blackbox = true

Also, add `require 'rackbox'` to the top of your `spec_helper.rb`

You can see a working example of blackbox testing a [Rack][] application here: [examples/rack](http://github.com/remi/rackbox/tree/master/examples/rack)

NOTE: If you want to be able to use nice RSpec matchers like `request('/').should have_tag('p')` in your 
blackbox specs in your [Rack][] apps, you should `sudo gem install webrat` and [RackBox][] will include 
[Webrat][]'s helpers in your specs.

Usage
-----

Ideally, the usage of [RackBox][] should be identical to [Merb][]-style blackbox testing.  I need to find good documentation 
on how things work in [Merb][] so I can duplicate any functionality I'm missing.  For now, it's really simple!

    describe Foo do

      it 'should have foxes on the home page' do
        request('/').body.should include('Foxes')
      end

      it 'should let me know that I was logged in' do
        response = request(login_path, :method => :post, :params => { 'user' => 'bob', :password => 'secret' })
        response.body.should include('Welcome bob, you were successfully logged in!')
      end

    end

`request` gives you a [`Rack::Response`](http://rack.rubyforge.org/doc/classes/Rack/Response.html) which has 
`body`, `headers`, `status` methods ([and more](http://rack.rubyforge.org/doc/classes/Rack/Response.html))

Script
------

[RackBox][] also comes with a `rackbox` script.

    # prints usage ... this is all you really need  :)
    $ rackbox

    # prints out information about the app in the current directory (if found).
    # this looks like a config.ru or a Rails environment
    $ rackbox info

    # prints out the response for a call to GET '/' on your application
    $ rackbox request --method get /foo
    $ rackbox get /foo
    $ rackbox /foo

TODO
----

see [RackBox][]'s [Lighthouse Tickets](http://remitaylor.lighthouseapp.com/projects/27570-rackbox)
* look at using Rack::Cookies as a cookie jar instead of doing it ourselves
* look at Rack::NestedParams and see if it can replace our own logic


[rackbox]:    http://github.com/remi/rackbox
[merb]:       http://merbivore.com
[rack]:       http://rack.rubyforge.org
[rails]:      http://rubyonrails.org
[rspec]:      http://rspec.info
[webrat]:     http://github.com/brynary/webrat
[thin]:       http://code.macournoyer.com/thin
[screencast]: http://remi.org/2009/01/29/introducing-rackbox_merb-esque-blackbox-testing-for-rack-and-rails-apps.html
[rubygem]:    http://www.rubygems.org
[blackbox]:   http://en.wikipedia.org/wiki/Black_box_testing
[sinatra]:    http://sinatra.github.com
