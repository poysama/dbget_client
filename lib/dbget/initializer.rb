module DBGet
  class Initializer
    include Constants

    def self.boot(options)
      self.new(options).init
    end

    def initialize(options)
      @options = options
    end

    def init
      load_dbget_config

      # lets turn off opt_db_name if we have more arguments
      # this feature is not supported at the moment
      if @options[:databases].count > 1 and @options.include?(:opt_db_name)
        raise "You cannot use -n with multiple databases!"
      end

      @options[:databases].each do |d|
        @options[:db] = d

        db_dump = DBGet::DBDump.new(@options)

        load_db_dumps(db_dump)
      end
    end

    protected

    def load_dbget_config
      config_path = File.join(@options[:dbget_path], DBGET_CONFIG_FILE)

      if File.exists?(config_path)
        @dbget_config = YAML.load_file(config_path)
      else
        raise "Cannot find #{config_path}!"
      end
    end

    def load_db_dumps(db_dump)
      if !@dbget_config.empty?
        config_loader = DBGet::ConfigLoader.new(@dbget_config, @options)
      else
        raise "Your dbget.yml is empty!"
      end

      db_dump.load!(config_loader.get_config(db_dump))
    end

    def cleanup_db_dumps(db_dumps)
      db_dumps.each do |db_dump|
        db_dump.clean_up!
      end
    end
  end
end
