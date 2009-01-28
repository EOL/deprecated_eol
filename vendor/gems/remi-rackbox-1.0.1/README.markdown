RackBox
=======

[RackBox][] adds [Merb][]-style blackbox testing to [Rack][] apps (including [Rails][])

This currently only works with [RSpec][].

Installation
------------

    $ sudo gem install remi-rackbox -s http://gems.github.com

Rails
-----

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



[rackbox]:  http://github.com/remi/rackbox
[merb]:     http://merbivore.com
[rack]:     http://rack.rubyforge.org
[rails]:    http://rubyonrails.org
[rspec]:    http://rspec.info
