module DBGet
  module Loaders
    class MongoDB
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
        temp_path = File.join(@dump.dump_path, "#{@dump.db}_#{Utils.randomize(16)}")

        if !File.exists?(temp_path)
          FileUtils.mkdir(temp_path)

          Utils.say_with_time "Extracting archive..." do
            `#{TAR_CMD} -C #{temp_path} -xf #{File.join(@dump.dump_path, @dump.db)} 2> /dev/null`
          end

          Utils.say_with_time "Moving mongo files..." do
            `#{FIND_CMD} #{temp_path} -name '*#{MONGO_FILE_EXT}'`.each_line do |l|
              FileUtils.mv(l.chomp!, File.join(temp_path, File.basename(l)))
            end
          end
        end

        dump_files = Dir["#{temp_path}/*#{MONGO_FILE_EXT}"]

        if !@dump.collections.empty?
          @dump.collections = @dump.collections.collect do |c|
            File.join(temp_path, c.concat(MONGO_FILE_EXT))
          end

          dump_files &= @dump.collections
        end

        dump_files.each do |d|
          # do not include indexes
          if File.basename(d) != "system.indexes#{MONGO_FILE_EXT}"
            Utils.say_with_time "Dumping #{d}..." do
              if !@dump.verbose
                `#{MONGORESTORE_CMD} -d #{@dump.database} #{d} --drop`
              else
                system "#{MONGORESTORE_CMD} -d #{@dump.database} #{d} --drop"
              end
            end
          end
        end

        Utils.say "Hooray! Dump for #{@dump.db} done!"

        if FileUtils.rm_rf(File.join(@dump.dump_path, @dump.db))
         Utils.say "Dump file removed!"
        end

        if FileUtils.rm_rf(temp_path)
          Utils.say "Temp directory removed!"
        end
      end
    end
  end
end
