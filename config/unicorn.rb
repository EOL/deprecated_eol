rails_env = ENV['RAILS_ENV'] || 'production'
worker_processes 2
working_directory "/var/www/eolvv/"

# This loads the application in the master process before forking worker processes
# Read more about it here: # http://unicorn.bogomips.org/Unicorn/Configurator.html
preload_app true
timeout 60

# This is where we specify the socket.
# We will point the upstream Nginx module to this socket later on
# 下面这个地址要与nginx.conf的upstream相对应
listen "/var/www/eolvv/tmp/sockets/unicorn.sock", :backlog => 64 
pid "/var/www/eolvv/tmp/pids/unicorn.pid" 

# Set the path of the log files inside the log folder of the eol
stderr_path "/var/www/eolvv/log/unicorn.stderr.log"
stdout_path "/var/www/eolvv/log/unicorn.stdout.log"
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
