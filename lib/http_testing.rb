module HttpTesting
  class HttpTestingError < StandardError
  end
  
  class DefaultLogFactory
    def self.create_logger(name)
      require 'logger' unless defined? Logger
      log = Logger.new(STDOUT)
      log.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime.strftime('%Y-%m-%d %H:%M:%S,%L')} [#{severity}] (#{name}) - #{msg}\n"
      end
      log
    end
  end
  
  class EmptyLoggerFactory
    def self.fatal(*args); end
    def self.error(*args); end
    def self.warn(*args); end
    def self.info(*args); end
    def self.debug(*args); end
    
    def self.create_logger(*args)
      self
    end
  end
  
  
  autoload :Context, 'http_testing/context'
  autoload :VERSION, 'http_testing/version'
end