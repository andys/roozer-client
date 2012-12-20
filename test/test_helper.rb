require 'webrick'

class NewRequestException < Exception
end

class TestServlet < WEBrick::HTTPServlet::AbstractServlet
  class << self
    attr_accessor :request, :response, :wakeupthread
  end
  def service(request, response)
    self.class.request = request.dup
    response.status = self.class.response.first
    response.body = self.class.response.last
    TestServlet.wakeupthread.raise NewRequestException.new
  end
end

def accept_request(*response)
  TestServlet.request = nil
  TestServlet.response = response
  begin
    TestServlet.wakeupthread = Thread.current
    yield
    $webserver_timeout.times { sleep 1 }
  rescue NewRequestException
  end
  TestServlet.request
end

def setup_webserver(timeout=3)
  $webserver_timeout = timeout
  $webserverthread ||= Thread.new do
     $webserver ||= WEBrick::HTTPServer.new :BindAddress => '127.0.0.1', :Port => 7999, :DocumentRoot => File.dirname(__FILE__), :Logger => WEBrick::Log.new("/dev/null"), :AccessLog => [nil, nil]
     $webserver.mount '/test', TestServlet
     $webserver.start
  end
end
