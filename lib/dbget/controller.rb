module DBGet
  class Controller
    include Constants

    attr_reader :connector, :config, :databases, :options

    def initialize(databases, options)
      @databases = databases
      @options = options
      @connections = []
    end

    def boot
      load_dbget_config
      @config = DBGet::Config.instance
      store_connections
    end

    def store_connections
      @databases.each do |database|
        @connections << Connector.new(database, @config, @options)
      end
    end

    def connect
      @connections.each do |connection|
        connection.send_data!
      end
    end

    protected

    def load_dbget_config
      config_path = File.join(@options[:dbget_path], DBGET_CONFIG_FILE)

      if File.exists?(config_path)
        DBGet::Config.load_from_yaml(config_path)
      else
        raise "Cannot find #{config_path}!"
      end
    end
  end
end
