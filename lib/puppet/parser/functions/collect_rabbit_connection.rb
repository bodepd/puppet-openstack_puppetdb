require 'puppet/face'
Puppet::Parser::Functions.newfunction(
  :collect_rabbit_connection,
  :type => :rvalue,
  :doc => <<-EOT

Queries puppetdb in order to derive the connection string
to use to connect to rabbitmq.

This assumes that the puppetmaster compiling this catalog is configured
to use puppetdb.

It accepts 2 arguments, the query to use to restrict nodes,
and the fact to use to connect to the rabbit host.

  collect_rabbit_connection('fqdn', 'operatingsystem=RedHat and architecture=amd64')

Returns a hash with all of the required rabbit connections.

EOT
) do |args|
  host_fact, query = args
  # should the fact be static?
  rabbit_host = function_query_nodes(['Class[nova::rabbitmq]', host_fact]).uniq
  raise(Puppet::Error, "Did not find a rabbit db node") if rabbit_host.empty?
  raise(Puppet::Error, "Found more than one rabbit db node") if rabbit_host.size > 1
  resources       = function_query_resource(['Class[nova::db::mysql]', query])
  rabbit_class    = resources['Class[Nova::Db::Mysql]']
  rabbit_params   = rabbit_class['parameters']

  rabbit_port     = rabbit_params['dbname'] || raise(Puppet::Error, 'cannot find dbname')
  rabbit_user     = rabbit_params['user'] || raise(Puppet::Error, 'cannot find db user')
  rabbit_password = rabbit_params['password'] || raise(Puppet::Error, 'cannot find db passwd')

  {
    'host'     => rabbit_host,
    'port'     => rabbit_port,
    'user'     => rabbit_user,
    'password' => rabbit_password
  }

end
