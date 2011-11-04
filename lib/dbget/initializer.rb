module DBGet
  class Initializer
    def self.boot(options)
      self.new(options).init
    end

    def initialize(options)
      @options = options
    end

    def init
      load_dbget_config

      @options[:databases].each do |d|
        dump_options = { :db => d,
                         :date => @options[:date],
                         :key => @options[:key],
                         :dbtype => @options[:dbtype],
                         :server => @options[:server],
                         :verbose => @options[:verbose] }

        db_dump = DBGet::DBDump.new(dump_options)
        load_db_dumps(db_dump)
      end
    end

    protected

    def load_dbget_config
      config_path = File.join(@options[:dbget_path], 'dbget.yml')

      raise "Cannot find #{config_path}!" unless File.exists?(config_path)

      @dbget_config = YAML.load_file(config_path)
    end

    def load_db_dumps(db_dump)
      config_loader = DBGet::ConfigLoader.new(@dbget_config, @options)
      db_dump.load!(config_loader.get_config(db_dump))
    end

    def cleanup_db_dumps(db_dumps)
      db_dumps.each do |db_dump|
        db_dump.clean_up!
      end
    end

  end
end
