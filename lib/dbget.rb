require 'fileutils'
require 'yaml'
require 'optparse'

DBGET_LIB_ROOT = File.expand_path('../dbget', __FILE__)
require File.join(DBGET_LIB_ROOT, 'version')

module DBGet
  autoload :Config, File.join(DBGET_LIB_ROOT, 'config')
  autoload :Connector, File.join(DBGET_LIB_ROOT, 'connector')
  autoload :Constants, File.join(DBGET_LIB_ROOT, 'constants')
  autoload :Controller, File.join(DBGET_LIB_ROOT, 'controller')
  autoload :Runner, File.join(DBGET_LIB_ROOT, 'runner')
  autoload :Utils, File.join(DBGET_LIB_ROOT, 'utils')
end
