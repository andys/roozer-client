require 'rest_client'
require 'json'

class RoozerClient
  attr_accessor :urls, :timeout
  def initialize(options={})
    opts = options.dup
    @urls = (opts.delete(:url) || ENV['ROOZER_URL'] || 'http://127.0.0.1:2987/').split(/;/).map(&:strip)
    @path = opts.delete(:path)
    @timeout = opts.delete(:timeout) || 10
    @opts = {timeout: @timeout, open_timeout: @timeout}.merge(opts)
  end

  def get(path)
    begin
      res = request(:get, path)
      res['value'] if res['type'] == 'file' 
    rescue RestClient::Exception => e
      raise unless e.http_code == 404
    end
  end
  alias :[] :get

  def list(path=nil)
    begin
      res = request(:get, path)
      res['value'] if res['type'] == 'dir' 
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
      fullpath = [@path,path].compact.map(&:to_s).join('/')
      response = resource["/#{fullpath}"].send(method, *[({value: data}.to_json if data), {content_type: :json, accept: :json}].compact)
      JSON.parse(response) rescue {}
    rescue Errno::ECONNREFUSED, RestClient::RequestTimeout
      puts "#{$!.class}, retrying..."
      @urls.rotate!
      sleep 5
      retry
    end
  end
  
end

