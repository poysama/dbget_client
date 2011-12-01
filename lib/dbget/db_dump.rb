module DBGet
  class DBDump
    include Utils

    DEFAULTS = {
        :db => "",
        :date => "",
        :db_name => "",
        :filename => "",
        :key => "",
        :verbose => false
      }

    attr_reader :db, :db_name, :filename, :fullpath, :database, :password

    def initialize(attributes)
      attributes = DEFAULTS.merge(attributes)
      @db = attributes[:db]
      @date = attributes[:date]
      @db_name = attributes[:db_name]
      @filename = attributes[:filename]
      @key = attributes[:key]
      @dbtype = attributes[:dbtype] || 'mysql'
      @server = attributes[:server]
      @verbose = attributes[:verbose]
      @header = {}
    end

    def load!(db_config)
      @server ||= db_config['source']['server']
      @database = db_config['mapping'][@db][@dbtype]
      @host = db_config['target'][@dbtype]['host']
      @port = db_config['target'][@dbtype]['port']
      @username = db_config['target'][@dbtype]['username']
      @password = db_config['target'][@dbtype]['password']
      @dump_path = db_config['source']['dump_path']
      @db_path = File.join(@dump_path, "#{@db}")
      @clean = db_config[:clean]

      get_db_from_server(db_config)

      if @header[:status] == 'SUCCESS'
        puts "Dumping #{@db} to #{@dbtype} using connection: "
        puts "  host: #{@host}"
        puts "  port: #{@port}"
        puts "  user: #{@username}"
        puts "  database: #{@database}"

        if @dbtype == 'mysql'
          load_mysql!
        else
          load_mongo!
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

      if @db_config
        puts "Dropping database..."
        system "echo \"DROP DATABASE IF EXISTS #{@database}\" | #{command}"
      end

      system "echo \"CREATE DATABASE IF NOT EXISTS #{@database}\" | #{command}"

      if File.exist?(@db_path) and !File.size?(@db_path).nil?
        command += " #{@database} "
        system "#{command}< #{File.join(@dump_path, @db)}"
        puts "Cleaned temporary file" if FileUtils.rm_rf(File.join(@dump_path, @db))
      else
        puts "Dump for #{@db} not found!"
      end

      puts "Done!"
    end

    def load_mongo!
      temp_path = File.join(@dump_path, "#{@db}_#{randomize(16)}")

      if !File.exists?(temp_path)
        FileUtils.mkdir(temp_path)
        `#{TAR_CMD} -C #{temp_path} -xf #{File.join(@dump_path, @db)}`

        `#{FIND_CMD} #{temp_path} -name '*.bson'`.each_line do |l|
          FileUtils.mv(l.chomp!, File.join(temp_path, File.basename(l)))
        end
      end

      Dir["#{temp_path}/*.bson"].each do |d|
        # do not include indexes
        if File.basename(d) != 'system.indexes.bson'
          if !@verbose
            `#{MONGORESTORE_CMD} -d #{@database} #{d} --drop`
          else
            system "#{MONGORESTORE_CMD} -d #{@database} #{d} --drop"
          end
        end
      end

      puts "Dump file removed!" if FileUtils.rm_rf(File.join(@dump_path, @db))
      puts "Temp directory removed!" if FileUtils.rm_rf(temp_path)
    end

    def get_db_from_server(db_config)
      user = db_config['source']['user']
      host = db_config['source']['host']

      FileUtils.mkdir_p(@dump_path) unless File.exist? @dump_path

      puts "Loading data... This may take a while..."

      ssh_params = "#{user}@#{host} db=#{@db} date=#{@date} " +
                   "dbtype=#{@dbtype} server=#{@server}"

      if !@key.nil?
        ssh_cmd = "#{SSH_CMD} -i #{@key} #{ssh_params}"
      else
        ssh_cmd = "#{SSH_CMD} #{ssh_params}"
      end

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
