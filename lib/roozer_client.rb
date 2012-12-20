require 'rest_client'
require 'json'

class RoozerClient
  attr_accessor :urls, :timeout
  def initialize(options={})
    opts = options.dup
    @urls = (opts.delete(:url) || ENV['ROOZER_URL'] || 'http://127.0.0.1:2987/').split(/;/).map(&:strip)
    @path = "#{opts.delete(:path) || ''}/"
    @timeout = opts.delete(:timeout) || 10
    @opts = {timeout: @timeout, open_timeout: @timeout}.merge(opts)
  end
  

  def get(path)
    begin
      res = request(:get, path)
      res['path'] && res['path']['type'] == 'file' ?  res['path']['value'] : nil
    rescue RestClient::Exception => e
      raise unless e.http_code == 404
    end
  end
  alias :[] :get

  def list(path='')
    begin
      res = request(:get, path)
      res['path'] && res['path']['type'] == 'dir' ?  res['path']['value'] : nil
    rescue RestClient::Exception => e
      raise unless e.http_code == 404
    end
  end

  def put(path, data)
    request(:put, path, data)
  end
  alias :[]= :put
  
  def request(method, path, data=nil)

    begin
      url = @urls.first
      resource = RestClient::Resource.new(url, @opts)
      response = resource["#{@path}#{path}"].send(method, *[({value: data}.to_json if data), {content_type: :json, accept: :json}].compact)
      JSON.parse(response) rescue {}
    rescue Errno::ECONNREFUSED, RestClient::RequestTimeout
      @urls.rotate!
      sleep 5
      retry
    end
  end
  
end


=begin

  rc = RoozerClient.new(url: 'http://orch1:2988;http://orch1:2987', path: 'bigcloud')
  rc.list
  rc['x'] = { a: 'b' }
  rc['x']
  rc.request(:delete, 'x')
    
  
=end
