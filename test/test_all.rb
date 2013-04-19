require "#{File.dirname(__FILE__)}/../lib/roozer_client"
require 'test/unit'
require "#{File.dirname(__FILE__)}/test_helper"

class TestRoozerClient < Test::Unit::TestCase

  def setup
    @url = setup_webserver
    @client = RoozerClient.new(url: @url, path: 'test')
  end
 
  def test_list
    result = nil
    response = accept_request(200, {name:"/test",type:"dir",value:["sub1","sub2"]}.to_json) do
      result = @client.list
    end
    assert response
    assert_equal 'GET', response.request_method
    assert_equal '/test', response.path
    assert_equal ["sub1","sub2"], result
  end

  def test_get
    result = nil
    datahash = {'a' => 'b'}
    response = accept_request(200, {name:"/test/sub1",type:"file",value:datahash}.to_json) do
      result = @client.get('sub1')
    end
    assert response
    assert_equal 'GET', response.request_method
    assert_equal '/test/sub1', response.path
    assert_equal datahash, result
  end

  def test_delete
    result = nil
    datahash = {'a' => 'b'}
    response = accept_request(204, '') do
      @client.delete('sub1')
    end
    assert response
    assert_equal 'DELETE', response.request_method
    assert_equal '/test/sub1', response.path
  end


  def test_put
    response = accept_request(204, '') do
      @client.put('sub2', x1: 'x2')
    end
    assert response
    assert_equal 'PUT', response.request_method
    assert_equal '/test/sub2', response.path
    assert_equal '{"value":{"x1":"x2"}}', response.body
  end


  def test_get_404
    result = nil
    response = accept_request(404, {error: 'not found'}.to_json) do
      result = @client.get('xxx')
    end
    assert response
    assert_equal '/test/xxx', response.path
    assert_nil result
  end

  def test_update_same
    result = nil
    datahash = {'a' => 1}
    response = accept_request(200, {name:"/test/sub1",type:"file",value:datahash}.to_json) do
      result = @client.update('sub1', datahash)
    end
    assert response
    assert_equal 'GET', response.request_method
    assert_equal '/test/sub1', response.path
    assert_equal nil, result
  end


#  def test_failover
#    @client = RoozerClient.new(url: "http://127.0.0.1:7997;#{@url}", path: 'test')
#    test_list
#  end
  
end
