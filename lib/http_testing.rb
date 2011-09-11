module HttpTesting
  class HttpTestingError < StandardError
  end
  
  autoload :Context, 'http_testing/context'
  autoload :VERSION, 'http_testing/version'
end