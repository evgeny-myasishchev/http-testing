require 'webrick'
require 'monitor'

class HttpTesting::Context
  include WEBrick
  
  def initialize(port, options = {})
    @options = {
      wait_timeout: 3, #seconds
      verbose: false,
      requests_dumps_path: nil, #Path to the folder to dump requests
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
    @log.debug 'Starting main worker thread...'
    @main = Thread.start do
      @log.info "Starting http server on port: #{@port}."
      
      access_log = []
      access_log << [$stdout, WEBrick::AccessLog::COMMON_LOG_FORMAT] if @options[:verbose]
      @server = HTTPServer.new(
        Port: @port, 
        Logger: Log.new(nil, BasicLog::ERROR), 
        AccessLog: access_log,
        RequestCallback: proc do |request, response|
          if @options[:requests_dumps_path]
            dump_request(request, @options[:requests_dumps_path])
          end
        end)
      
      @server.mount_proc("/", nil) do |request, response|
        @log.info "Connection started. Path: #{request.path}."
        begin
          @log.debug 'Yielding request and response...'
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
        @log.debug "Waiting for connection to complete. Wait timeout: #{@options[:wait_timeout]} seconds."
        @completed_cond.wait(@options[:wait_timeout]) 
      end
    end
    @log.info "Stopping http server on port: #{@port}."
    @server.shutdown
    raise HttpTesting::HttpTestingError.new "HTTP Connection was not completed within #{@options[:wait_timeout]} seconds" unless @completed
    raise @error if @error
  end

  private
    def dump_request(request, dumps_path)
      FileUtils.mkpath(dumps_path) unless File.exists?(dumps_path)
      timestamp = Time.now.strftime('%Y%m%d%H%M%S%L')
      request_dump_path = File.join(dumps_path, "#{timestamp}-#{request.request_method}.txt")
      @log.debug "Dumping request to: #{request_dump_path}"
      File.open(request_dump_path, 'w') do |f|
        f.write(request.request_line)
        f.write(request.raw_header.join(''))
        f.write("\r\n")
        f.write(request.body)
      end
    end
end
