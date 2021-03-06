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
  
  def delete(path)
    request(:delete, path)
  end
  
  def deltree(path)
    tree(path).each do |entry|
      begin
        delete(entry)
      rescue RestClient::ResourceNotFound
      end
    end
  end
  
  def tree(path=nil)
    result = []
    entries = list(path)
    if entries
      entries.each do |entry|
        result.push(*tree("#{path}/#{entry}"))
      end
    end
    result.push path
  end
  
  def update(path, data)
    existing_data = get(path) rescue nil
    put(path, data) unless data && existing_data == JSON.parse(data.to_json)
  end
  
  def self.data_to_json(data)
    {value: data}.to_json if data
  end
  
  def request(method, path, data=nil)
    begin
      url = @urls.first
      resource = RestClient::Resource.new(url, @opts)
      fullpath = [@path,path].compact.map(&:to_s).join('/')
      response = resource["/#{fullpath}"].send(method, *[self.class.data_to_json(data), {content_type: :json, accept: :json}].compact)
      JSON.parse(response) rescue {}
    rescue SystemCallError, RestClient::RequestTimeout, RestClient::ServerBrokeConnection, RestClient::InternalServerError
      puts "#{$!.class}, retrying..."
      @urls.rotate!
      sleep 5
      retry
    end
  end
  
end
