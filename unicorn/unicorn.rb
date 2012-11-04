# Unicorn sample config script
# #{Rails.root}/config/unicorn.rb

user 'www', 'www'

case ENV['RACK_ENV']
when 'staging'
  deploy_to = 'application_staging_path'
  worker_processes 8
when 'production'
  deploy_to = 'application_production_path'
  worker_processes 32
end

rails_root = "#{deploy_to}/current"
pid_file   = "#{deploy_to}/shared/pids/unicorn.pid"
socket_file = "#{deploy_to}/shared/sockets/unicorn.sock"

old_pid    = pid_file + '.oldbin'

stderr_path "#{deploy_to}/shared/log/unicorn.stderr.log"
stdout_path "#{deploy_to}/shared/log/unicorn.stdout.log"

timeout 300
listen socket_file, :backlog => 1024

pid pid_file

File.umask(027)

preload_app true

if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

before_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end
end