require 'webrick'

class TestServlet < WEBrick::HTTPServlet::AbstractServlet
  class << self
    attr_accessor :request, :response #, :wakeupthread
  end
  def service(request, response)
    # Save the request
    body = request.body # this is needed to read the chunks from the other side before duping
    self.class.request = request.dup
    
    # return the canned response
    response.status = self.class.response.first
    response.body = self.class.response.last
  end
end

def accept_request(*response)
  TestServlet.request = nil
  TestServlet.response = response
  yield
  TestServlet.request
end

def setup_webserver(timeout=5)
  port = 7999
  $webserver_timeout = timeout
  Thread.abort_on_exception = true
  
  if !$webserver
    newflag = true 
    $webserver = WEBrick::HTTPServer.new :BindAddress => '127.0.0.1', :Port => port, :DocumentRoot => File.dirname(__FILE__), :Logger => WEBrick::Log.new("/dev/null"), :AccessLog => [nil, nil]
    $webserver.mount '/', TestServlet
    $webserverthread ||= Thread.new do
       $webserver.start
    end
  end
  sleep 3 if newflag
  "http://127.0.0.1:#{port}/"
end
