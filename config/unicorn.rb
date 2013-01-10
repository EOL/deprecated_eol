
 # Minimal sample configuration file for Unicorn (not Rack) when used
 # with daemonization (unicorn -D) started in your working directory.
 #
 # See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
 # documentation.
 # See also http://unicorn.bogomips.org/examples/unicorn.conf.rb for
 # a more verbose configuration using more features.

# app_path = "/var/www/eol"
# listen 80 # by default Unicorn listens on port 8080
# worker_processes 3 # this should be >= nr_cpus
# pid "#{app_path}/tmp/pids/unicorn.pid"
# stderr_path "#{app_path}/log/unicorn.log"
# stdout_path "#{app_path}/log/unicorn.log"

rails_env = ENV['RAILS_ENV'] || 'development'
worker_processes 2
working_directory "/var/www/eol/"
# This loads the application in the master process before forking
# worker processes
# Read more about it here:
# http://unicorn.bogomips.org/Unicorn/Configurator.html
preload_app true
timeout 300
# This is where we specify the socket.
# We will point the upstream Nginx module to this socket later on
# ???¸ö·Ҫ?nginx.confµ?pstream?¶?¦
listen "/var/www/eol/tmp/sockets/unicorn.sock", :backlog => 64
pid "/var/www/eol/tmp/pids/unicorn.pid"
# Set the path of the log files inside the log folder of the testapp
stderr_path "/var/www/eol/log/unicorn.stderr.log"
stdout_path "/var/www/eol/log/unicorn.stdout.log"
# http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow  
if GC.respond_to?(:copy_on_write_friendly=)
        GC.copy_on_write_friendly = true
end
before_fork do |server, worker|
# This option works in together with preload_app true setting
# What is does is prevent the master process from holding
# the database connection
defined?(ActiveRecord::Base) and
         ActiveRecord::Base.connection.disconnect!
end
after_fork do |server, worker|
# Here we are establishing the connection after forking worker
# processes
defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
