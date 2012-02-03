module DBGet
  class Runner
    def self.boot(args, dbtype)
      DBGet::Constants.const_set("MYSQL_CMD", `which mysql 2>/dev/null`.strip)
      DBGet::Constants.const_set("SSH_CMD", `which ssh 2>/dev/null`.strip)
      DBGet::Constants.const_set("MONGORESTORE_CMD", `which mongorestore 2>/dev/null`.strip)
      DBGet::Constants.const_set("FIND_CMD", `which find 2>/dev/null`.strip)
      DBGet::Constants.const_set("TAR_CMD", `which tar 2>/dev/null`.strip)

      self.new(args, dbtype)
    end

    def initialize(args, dbtype)
      options = {}
      options[:append_date] = false
      options[:verbose] = false

      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: dbget [options] db1 db2 ...\n"
        opts.separator "Options:"

        opts.on('-d', '--date DATE', 'Date of database dump (yyyy-mm-dd).') do |date|
          options[:date] = date
        end

        opts.on('-c', '--clean', 'Drops the database before dumping') do
          options[:clean] = true
        end

        opts.on('-f', '--force', 'Force the use of dbget in production.') do
          options[:force] = true
        end

        opts.on('-n', '--name NAME', 'Explicitly declare a database name for dumping.') do |name|
          options[:opt_db_name] = name
        end

        opts.on('-i', '--key KEY', 'Specify ssh connection key') do |key|
          options[:key] = key
        end

        opts.on('-s', '--server SERVER', 'Specify the server that contained the database.') do |server|
          options[:server] = server
        end

        opts.on('-a', '--append-date', 'Append the given date as suffix') do
          options[:append_date] = true
        end

        opts.on('-v', '--verbose', 'Execute NERD mode!') do
          options[:verbose] = true
        end

        opts.on('-V', '--version', 'Version') do
          puts DBGet::VERSION
          exit
        end

        opts.on('-h', '--help', 'Display this screen') do
          puts opts
          exit
        end
      end

      optparse.parse!

      if args.length == 0
        puts optparse.help
      else
        options[:dbtype] = dbtype
        options[:databases] = args.dup

        run(options)
      end
    end

    def run(opts)
      if ENV.include?('DBGET_PATH')
        opts[:dbget_path] = ENV['DBGET_PATH']
      else
        raise "Cannot find DBGET_PATH!"
      end

      # lets turn off opt_db_name if we have more arguments
      # this feature is not supported at the moment
      if opts[:databases].count > 1 and opts.include?(:opt_db_name)
        raise "You cannot use -n with multiple databases!"
      end

      # check if -a switch is give but no -d
      if opts[:append_date] and !opts.include?(:date)
        raise "You cannnot use -a without -d!"
      end

      DBGet::Initializer.boot(opts)
    end
  end
end
