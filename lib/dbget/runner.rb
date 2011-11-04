module DBGet
  class Runner
    def initialize(args, dbtype)
      options = {}

      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: dbget [options] db1 db2 ...\n"
        opts.separator "Options:"

        opts.on('-d', '--date DATE', 'Date of database dump (mm-dd-yyyy).') do |date|
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
          options[:ssh_key] = key
        end

        opts.on('-s', '--server SERVER', 'Specify the server that contained the database.') do |server|
          options[:server] = server
        end

        opts.on('-v', '--verbose', 'Execute NERD mode!') do
          options[:verbose] = true
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

      DBGet::Initializer.boot(opts)
    end
  end
end
