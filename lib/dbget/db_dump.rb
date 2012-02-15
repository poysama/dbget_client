module DBGet
  class DBDump
    include Utils
    include Constants

    attr_accessor :dump_path, :collections
    attr_reader :db, :database, :db_path
    attr_reader :host, :port, :username, :password
    attr_reader :clean, :verbose

    def initialize(options)
      @db = options[:db]
      @date = options[:date]
      @key = options[:key]
      @dbtype = options[:dbtype]
      @server = options[:server]
      @opt_db_name = options[:opt_db_name]
      @verbose = options[:verbose]
      @append_date = options[:append_date]
      @clean = options[:clean]
      @collections = options[:collections] || []
      @header = {}
    end

    def load!(db_config)
      @server ||= db_config['source']['server']
      @key ||= db_config['key']
      @database = @opt_db_name || db_config['mapping'][@db][@dbtype]
      @host = db_config['target'][@dbtype]['host']
      @port = db_config['target'][@dbtype]['port']
      @username = db_config['target'][@dbtype]['username']
      @password = db_config['target'][@dbtype]['password']
      @dump_path = db_config['source']['dump_path']
      @db_path = File.join(@dump_path, "#{@db}")

      if @append_date
        @database = @database.concat("_#{@date.delete('-')}")
      end

      get_dump(db_config)

      if @header[:status] == 'SUCCESS'
        if !@database.nil?
          Utils.say "Dump info of #{@db} to #{@dbtype} using connection: \n" +
          "  host: #{@host}\n" +
          "  port: #{@port}\n" +
          "  user: #{@username}\n" +
          "  database: #{@database}\n"

          if @dbtype == 'mysql'
            Loaders::MySQL.new(self).load!
          else
            Loaders::MongoDB.new(self).load!
          end
        else
          raise "Database #{@db} for #{@dbtype} is not found on #{DBGET_CONFIG_FILE}!"
        end
      else
        raise "There was a problem fetching the database from the server!"
      end
    end

    protected

    def get_dump(db_config)
      user = db_config['source']['user']
      host = db_config['source']['host']

      unless File.exist? @dump_path
        FileUtils.mkdir_p(@dump_path)
      end

      ssh_params = "#{user}@#{host} db=#{@db} date=#{@date} " +
                   "dbtype=#{@dbtype} server=#{@server}"

      if !@key.nil?
        ssh_cmd = "#{SSH_CMD} -i #{@key} #{ssh_params}"
      else
        ssh_cmd = "#{SSH_CMD} #{ssh_params}"
      end

      Utils.say "Fetching..."

      io_handle = IO.popen(ssh_cmd)

      parse_header(io_handle)

      if !io_handle.eof?
        File.open(@db_path, "w+") do |f|
          gz = Zlib::GzipReader.new(io_handle)

          while !io_handle.eof?
            g = gz.read(16*1024)
            f.write(g)
          end

          f.write(gz.read)

          gz.close
          f.close
        end
      end
    end

    def parse_header(io_handle)
      while (s = io_handle.readline) != "\r\n"
        s = s.split(': ')
        @header[s.first.to_sym] = s.last.chomp
      end

      print_header if @verbose

      if @header[:status] != "SUCCESS"
        raise "Server returned #{@header[:status]}!"
      end
    end

    def print_header
      @header.each do |k, v|
        puts ">> #{k.capitalize}: #{v}"
      end
    end
  end
end
