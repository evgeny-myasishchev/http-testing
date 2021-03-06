require 'spec_helper'

describe "HTTP requests sender" do
  it "should get '/say-hello'" do
    #Start HttpTesting context on port 30013
    c = HttpTesting::Context.start(30013) do |request, response|
      # request - instance of WEBrick::HTTPRequest
      # response - instance of WEBrick::HTTPResponse
      
      #Check method and path
      request.request_method.should eql "GET"
      request.path.should eql '/say-hello'
      
      #Set response
      response.body = "Hello World"
    end
    
    #Send get request
    result = Net::HTTP.get(URI.parse('http://localhost:30013/say-hello'))
    
    #Wait for request to complete
    c.wait
    
    #Check the result
    result.should eql "Hello World"
  end  
  
  it "should post '/hello-there'" do
    #Starting context
    c = HttpTesting::Context.start(30013) do |request, response|
      #Checking method, path and body of request
      request.request_method.should eql "POST"
      request.path.should eql '/hello-there'
      request.body.should eql "from=Mike"
      
      #Setting response
      response.body = "Hello"
    end
    
    #Send post request
    response = Net::HTTP.post_form(URI.parse('http://localhost:30013/hello-there'), :from => "Mike")
    
    #Wait for request to complete
    c.wait
    
    #Check the result
    response.body.should eql "Hello"
  end
end