require "#{File.dirname(__FILE__)}/../lib/restinator"
require 'test/unit'
require "#{File.dirname(__FILE__)}/test_helper"

class TestRoozerClient < Test::Unit::TestCase

  def setup
    setup_webserver
  end
 
 def test_get
   resp = accept_request(200, 'test') do
     `( echo GET /test/123 HTTP/1.0 ; echo ) | nc 127.0.0.1 7999`
   end
   assert_equal 'GET', resp.request_method
   assert_equal '/test/123', resp.path
 end
 
end
