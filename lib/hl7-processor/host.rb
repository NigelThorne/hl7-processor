require 'socket'

module HL7Processor
  class Host

    attr_reader :config

    def initialize(config = Configuration.new)
      @config = config
      yield @config if block_given?
    end

    def start
      puts "Listening for HL7 messages on port #{@config.port}."

      Socket.tcp_server_loop(@config.port) do |socket, client_addrinfo|
        begin
          read_socket(socket)
        rescue EOFError
          puts "#{Time.now.to_s}: Client closed the connection."
        end
      end

    end

    private

    def read_socket(socket)
      while(true)
        llp_line = socket.readline('\r')
        begin
          llp = LLPMessage.from_llp(llp_line)
          channel_instances = @config.channels.collect {|c| c.new }
          config.processor.process(channel_instances, llp)
        rescue LLPSyntaxError => e
          puts "#{Time.now.to_s}: Syntax Error #{e.message}"
        end
      end
    end

  end
end
