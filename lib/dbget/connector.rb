require 'net/ssh'

module DBGet
  class Connector
    include Utils
    include Constants

    attr_accessor :collections
    attr_reader :db, :db_path
    attr_reader :clean, :verbose

    def initialize(database, config, options)
      @db = database
      @options = Utils.stringify(options)
      @config = config.merge!(@options)
      @login = @config['login']
      @db_type = @options['db_type']
      @server = @config['server']
      @date = @config['date']
      @clean = @config['clean']
      @verbose = @config['verbose']
      @collections = @config['collections']
      @custom_name = @config['name']
      @append_date = @config['append_date']
      @ssh_params = init_ssh_params
    end

    def send_data!
      user, host = @config['login'].split('@')

      Net::SSH.start(host, user) do |ssh|

        channel = ssh.open_channel do |ch|
          ch.exec(@ssh_params) do |ch, success|
            raise "SSH connection failure." unless success

            ch.on_data do |c,data|
              $stdout.puts data
            end

            ch.on_extended_data do |c, type, data|
              $stderr.print data
            end

          end
          channel.wait

        end
      end
    end

    def init_ssh_params
      "%s db=%s db_type=%s server=%s date=%s clean=%s verbose=%s collections=%s custom_name=%s append_date=%s" %
        [@login, @db, @db_type, @server, @date, @clean, @verbose, @collections, @custom_name, @append_date]
    end
  end
end
