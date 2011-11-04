require 'fileutils'
require 'yaml'
require 'zlib'
require 'optparse'

module DBGet
  MYSQL_CMD = `which mysql`.strip
  SSH_CMD = `which ssh`.strip
  MONGORESTORE_CMD = `which mongorestore`.strip
  FIND_CMD = `which find`.strip
  TAR_CMD = `which tar`.strip

  autoload :Initializer, File.join(File.dirname(__FILE__), 'dbget/initializer')
  autoload :DBDump, File.join(File.dirname(__FILE__), 'dbget/db_dump')
  autoload :ConfigLoader, File.join(File.dirname(__FILE__), 'dbget/config_loader')
  autoload :Runner, File.join(File.dirname(__FILE__), 'dbget/runner')
  autoload :Utils, File.join(File.dirname(__FILE__), 'dbget/utils')
end
