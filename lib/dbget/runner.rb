module DBGet
  class Runner
    def initialize
      @options = {}
      set_default_options
      @optparse = init_option_parser
      @args = nil
    end

    def init_option_parser
      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: dbget [options] db1 db2 ...\n"
        opts.separator "Options:"

        opts.on('-d', '--date DATE', 'Date of database dump (yyyy-mm-dd).') do |date|
          @options[:date] = date
        end

        opts.on('-c', '--clean', 'Drops the database before dumping') do
          @options[:clean] = true
        end

        opts.on('-k', '--key KEY', 'Specify ssh connection key') do |key|
          @options[:key] = key
        end

        opts.on('-s', '--server SERVER', 'Specify the server that contained the database.') do |server|
          @options[:server] = server
        end

        opts.on('-a', '--append-date', 'Append the given date as suffix') do
          @options[:append_date] = true
        end

        opts.on('--collections COLLECTION', 'Only dump specific mongodb collections separated by comma') do |collection|
          @options[:collections] = collection
        end

        opts.on('-v', '--verbose', 'Execute NERD mode!') do
          @options[:verbose] = true
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

      optparse
    end

    def set_default_options
      @options[:append_date] = false
      @options[:verbose] = false
      @options[:clean] = false
      @options[:date] = 'xxxx-xx-xx'
      @options[:collections] = 'EMPTY'
    end

    def run!(args, type)
      check_path
      @args = args
      has_arguments?

      @optparse.parse!
      @options[:db_type] = type

      dbget
    end

    def dbget
      controller = DBGet::Controller.new(@args, @options)
      controller.boot
      controller.connect
    end

    def has_arguments?
      if @args.length == 0
        puts @optparse.help
        exit
      end
    end

    def check_path
      if ENV.include?('DBGET_PATH')
        @options[:dbget_path] = ENV['DBGET_PATH']
      else
        raise "Cannot find DBGET_PATH!"
      end
    end
  end
end
