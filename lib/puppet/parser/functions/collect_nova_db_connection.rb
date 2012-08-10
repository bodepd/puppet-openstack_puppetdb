require 'puppet/face'
Puppet::Parser::Functions.newfunction(
  :collect_nova_db_connection,
  :type => :rvalue,
  :doc => <<-EOT

Queries puppetdb in order to derive the connection string that should be used
to connect to nova's database.

This assumes that the puppetmaster that is compiling the catalog is also
configured to connect to puppetdb.

It accepts 2 arguments.

- The fact to return to represent the db host
- The query used to retrict the node that is returned.

Example:

    collect_nova_db_connection('fqdn', 'operatingsystem=RedHat and architecture=amd64')

It returns a string that can be used to configure the sql connection.

'mysql://db_user:db_passwd@db_host/db_name'

EOT
) do |args|
  host_fact, query = args
  # should the fact be static?
  db_host   = function_query_nodes(['Class[nova::db::mysql]', host_fact]).uniq
  raise(Puppet::Error, "Did not find a nova db node") if db_host.empty?
  raise(Puppet::Error, "Found more than one nova db node") if db_host.size > 1
  resources      = function_query_resource(['Class[nova::db::mysql]', query])
  db_class  = resources['Class[Nova::Db::Mysql]']
  db_params = db_class['parameters']

  db_name   = db_params['dbname'] || raise(Puppet::Error, 'cannot find dbname')
  db_user   = db_params['user'] || raise(Puppet::Error, 'cannot find db user')
  db_passwd = db_params['password'] || raise(Puppet::Error, 'cannot find db passwd')

  sql_conn = "mysql://#{db_user}:#{db_passwd}@#{db_host}/#{db_name}"

end
