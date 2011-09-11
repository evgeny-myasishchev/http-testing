require 'webrick'
require 'monitor'

class HttpTesting::Context
  include WEBrick
  
  WAIT_TIMEOUT = 0 #Works with no timeout :)
  
  def initialize(port)
    @port = port
    
    @monitor = Monitor.new
    @completed_cond = @monitor.new_cond
    @started_cond = @monitor.new_cond
    
    @completed = false
    @error = nil
  end
  
  def start(&block)
    @completed = false
    @error = nil
    
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
      
      @server.start
    end
    
    #Waiting for server to start
    @monitor.synchronize do
      @started_cond.wait(WAIT_TIMEOUT)
    end
  end
  
  def wait
    @monitor.synchronize do
      @completed_cond.wait(WAIT_TIMEOUT)
    end
    
    @server.shutdown
    
    raise "HTTP Connection was not completed within #{WAIT_TIMEOUT} seconds" unless @completed
    raise @error if @error
  end
end