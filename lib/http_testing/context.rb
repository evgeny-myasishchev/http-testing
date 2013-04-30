require 'webrick'
require 'monitor'

class HttpTesting::Context
  include WEBrick
  
  def initialize(port, options = {})
    @options = {
      wait_timeout: 3, #seconds
      verbose: false,
      log_factory: HttpTesting::DefaultLogFactory
    }.merge options
    @port = port
    
    @monitor = Monitor.new
    @completed_cond = @monitor.new_cond
    @started_cond = @monitor.new_cond
    
    @started = false
    @completed = false
    @error = nil
    
    logger_factory = @options[:verbose] ? @options[:log_factory] : HttpTesting::EmptyLoggerFactory
    @log = logger_factory.create_logger('http-testing::context')
  end
  
  def self.start(port, options = {}, &block)
    new(port, options).start(&block)
  end
  
  def start(&block)
    @started   = false
    @completed = false
    @error     = nil
    
    #Starting separate thread for the server
    @log.info 'Starting main worker thread...'
    @main = Thread.start do
      @log.info "Starting http server on port: #{@port}."
      @server = HTTPServer.new(Port: @port, Logger: Log.new(nil, BasicLog::ERROR), AccessLog: [])
      @server.mount_proc("/", nil) do |request, response|
        @log.info "Connection started. Path: #{request.path}."
        begin
          @log.info 'Yielding request and response...'
          yield(request, response)
        rescue
          @log.error "Block raised error #{$!}"
          @error = $!
        end
        
        @completed = true
        @monitor.synchronize do
          @completed_cond.signal
        end
        @log.info 'Connection completed.'
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
    @log.info 'Server started.'
    self
  end
  
  def wait
    @monitor.synchronize do
      unless @completed
        @log.info 'Waiting for connection to complete...'
        @completed_cond.wait(@options[:wait_timeout]) 
      end
    end
    @log.info "Stopping http server on port: #{@port}."
    @server.shutdown
    raise HttpTesting::HttpTestingError.new "HTTP Connection was not completed within #{@options[:wait_timeout]} seconds" unless @completed
    raise @error if @error
  end
end
