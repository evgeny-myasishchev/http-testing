require 'spec_helper'

describe HttpTesting::Context do
  def context(options = {})
    HttpTesting::Context.new(30013, options)
  end
  
  it "should start web server at specified port" do
    started = false
    c = context
    c.start do |request, response|
      started = true
    end
    Net::HTTP.get(URI.parse('http://localhost:30013/'))
    c.wait
    started.should be_true
  end
  
  describe "wait" do
    it "should raise exception if no request received withing wait_timeout" do
      c = context(:wait_timeout => 0)
      c.start do |request, response| end
      lambda { c.wait }.should raise_error(HttpTesting::HttpTestingError)
    end
    
    it "should reraise exception that was raised in start block" do
      c = context(:wait_timeout => 0)
      c.start do |request, response| 
        raise "Error in start block"
      end
      Net::HTTP.get(URI.parse('http://localhost:30013/'))
      lambda { c.wait }.should raise_error(RuntimeError)
    end
  end
end