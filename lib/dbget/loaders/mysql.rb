module DBGet
  module Loaders
    class MySQL
      include Utils
      include Constants

      def self.boot(dump)
        # some boot here

        self.new(dump)
      end

      def initialize(dump)
        @dump = dump
      end

      def load!
        command = "#{MYSQL_CMD} "
        command += "-h#{@dump.host} "
        command += "-P#{@dump.port} "
        command += "-u#{@dump.username} "
        command += "-p#{@dump.password} " if @dump.password

        if @dump.clean
          Utils.say_with_time "Dropping database..." do
            system "echo \"DROP DATABASE IF EXISTS #{@dump.database}\" | #{command}"
          end
        end

        system "echo \"CREATE DATABASE IF NOT EXISTS #{@dump.database}\" | #{command}"

        if File.exist?(@dump.db_path) and !File.size?(@dump.db_path).nil?
          command += " #{@dump.database} "

          Utils.say_with_time "Dumping #{@dump.db}..." do
            system "#{command}< #{File.join(@dump.dump_path, @dump.db)}"
          end

          if FileUtils.rm_rf(File.join(@dump.dump_path, @dump.db))
            Utils.say "Cleaned temporary file!"
          end
        else
          raise "Dump for #{@dump.db} not found!"
        end

        Utils.say "Hooray! Dump for #{@dump.db} done!"
      end
    end
  end
end
