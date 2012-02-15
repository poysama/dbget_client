module DBGet
  module Loaders
    autoload :MongoDB, File.join(DBGET_LIB_ROOT, 'loaders/mongodb')
    autoload :MySQL, File.join(DBGET_LIB_ROOT, 'loaders/mysql')
  end
end
