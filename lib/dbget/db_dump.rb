module DBGet
  class DBDump
    include Utils
    include Constants

    attr_reader :db, :database, :password

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
            load_mysql!
          else
            load_mongo!
          end
        else
          raise "Database #{@db} for #{@dbtype} is not found on #{DBGET_CONFIG_FILE}!"
        end
      else
        raise "There was a problem fetching the database from the server!"
      end
    end

    def load_mysql!
      command = "#{MYSQL_CMD} "
      command += "-h#{@host} "
      command += "-P#{@port} "
      command += "-u#{@username} "
      command += "-p#{@password} " if @password

      if @clean
        Utils.say_with_time "Dropping database..." do
          system "echo \"DROP DATABASE IF EXISTS #{@database}\" | #{command}"
        end
      end

      system "echo \"CREATE DATABASE IF NOT EXISTS #{@database}\" | #{command}"

      if File.exist?(@db_path) and !File.size?(@db_path).nil?
        command += " #{@database} "

        Utils.say_with_time "Dumping #{db}..." do
          system "#{command}< #{File.join(@dump_path, @db)}"
        end

        if FileUtils.rm_rf(File.join(@dump_path, @db))
          Utils.say "Cleaned temporary file!"
        end
      else
        raise "Dump for #{@db} not found!"
      end

      Utils.say "Hooray! Dump for #{@db} done!"
    end

    def load_mongo!
      temp_path = File.join(@dump_path, "#{@db}_#{Utils.randomize(16)}")

      if !File.exists?(temp_path)
        FileUtils.mkdir(temp_path)

        Utils.say_with_time "Extracting archive..." do
          `#{TAR_CMD} -C #{temp_path} -xf #{File.join(@dump_path, @db)}`
        end

        Utils.say_with_time "Moving mongo files..." do
          `#{FIND_CMD} #{temp_path} -name '*.bson'`.each_line do |l|
              FileUtils.mv(l.chomp!, File.join(temp_path, File.basename(l)))
          end
        end
      end

      dump_files = Dir["#{temp_path}/*#{MONGO_FILE_EXT}"]

      if !@collections.empty?
        @collections = @collections.collect do |c|
          File.join(temp_path, c.concat(MONGO_FILE_EXT))
        end

        dump_files &= @collections
      end

      dump_files.each do |d|
        # do not include indexes
        if File.basename(d) != "system.indexes#{MONGO_FILE_EXT}"
          Utils.say_with_time "Dumping #{d}..." do
            if !@verbose
              `#{MONGORESTORE_CMD} -d #{@database} #{d} --drop`
            else
              system "#{MONGORESTORE_CMD} -d #{@database} #{d} --drop"
            end
          end
        end
      end

      Utils.say "Hooray! Dump for #{@db} done!"

      if FileUtils.rm_rf(File.join(@dump_path, @db))
       Utils.say "Dump file removed!"
      end

      if FileUtils.rm_rf(temp_path)
        Utils.say "Temp directory removed!"
      end
    end

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

          # read and write the rest of the shit
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
