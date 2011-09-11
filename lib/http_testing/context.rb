require 'webrick'
require 'monitor'

class HttpTesting::Context
  include WEBrick
  # extend MonitorMixin
  
  def initialize(port, options = {})
    @options = {
      :wait_timeout => 3 #seconds
    }.merge options
    @port = port
    
    @monitor      = Monitor.new
    @completed_cond = @monitor.new_cond
    @started_cond   = @monitor.new_cond
    
    @started   = false
    @completed = false
    @error     = nil
  end
  
  def self.start(port, options = {}, &block)
    new(port, options).start(&block)
  end
  
  def start(&block)
    @started   = false
    @completed = false
    @error     = nil
    
    #Starting separate thread for the server
    @main = Thread.start do
      @server = HTTPServer.new( :Port => @port, :Logger => Log.new(nil, BasicLog::ERROR), :AccessLog => [])
      @server.mount_proc("/", nil) do |request, response|
        begin
          yield(request, response)
        rescue
          @error = $!
        end
        
        @completed = true
        @monitor.synchronize do
          @completed_cond.signal
        end
      end
      @started = true
      @monitor.synchronize do
        @started_cond.signal
      end
      @server.start
    end
    
    #Waiting for server to start
    @monitor.synchronize do
      @started_cond.wait_until { @started }
    end
    self
  end
  
  def wait
    @monitor.synchronize do
      @completed_cond.wait(@options[:wait_timeout]) unless @completed
    end
    @server.shutdown
    raise HttpTesting::HttpTestingError.new "HTTP Connection was not completed within #{@options[:wait_timeout]} seconds" unless @completed
    raise @error if @error
  end
end
