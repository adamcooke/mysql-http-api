$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'mysql_api/server'
run MySQLAPI::Server
