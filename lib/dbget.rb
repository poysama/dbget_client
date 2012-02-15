require 'fileutils'
require 'yaml'
require 'zlib'
require 'optparse'

DBGET_LIB_ROOT = File.expand_path('../dbget', __FILE__)
require File.join(DBGET_LIB_ROOT, 'version')

module DBGet
  autoload :Initializer, File.join(DBGET_LIB_ROOT, 'initializer')
  autoload :DBDump, File.join(DBGET_LIB_ROOT, 'db_dump')
  autoload :Loaders, File.join(DBGET_LIB_ROOT, 'loaders')
  autoload :Constants, File.join(DBGET_LIB_ROOT, 'constants')
  autoload :ConfigLoader, File.join(DBGET_LIB_ROOT, 'config_loader')
  autoload :Runner, File.join(DBGET_LIB_ROOT, 'runner')
  autoload :Utils, File.join(DBGET_LIB_ROOT, 'utils')
end
