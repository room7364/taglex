require 'base64'
require 'net/http'
require 'json'
require 'securerandom'
module Couch
  class BadResponse < Exception
  end
  config_file = File.open "./config.json"
  config = JSON.load config_file
  config_file.close
  Host = "#{config['host']}:5984"
  Login = config["login"]
  Password = config["password"]
  class Table
    def initialize(name)
      @name = name
    end
    def map(view_name, js_func)
      uri = URI("http://#{Host}/#{@name}/_design/main")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Put.new uri
        request.basic_auth Login, Password
        request.body = JSON.generate({
          views: {
           view_name => {
             map: js_func
           }
          }
        }) 
        response = http.request request
        raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
        return response
      end
    end
    def view(view_name)
      uri = URI("http://#{Host}/#{@name}/_design/main/_view/#{view_name}")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri
        request.basic_auth Login, Password
        response = http.request request
        raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
        return response
      end
    end
    def get(id)
      uri = URI("http://#{Host}/#{@name}/#{id}")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri
        request.basic_auth Login, Password
        response = http.request request
        return response.body
      end
    end
    def find(view_name, key)
      uri = URI("http://#{Host}/#{@name}/_design/main/_view/#{view_name}?key=\"#{key}\"")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri
        request.basic_auth Login, Password
        response = http.request request
        docs = JSON.parse(response.body)["rows"].map { |row| self.get(row["id"]) }
        return docs 
      end
    end
    def push(doc)
      uri = URI("http://#{Host}/#{@name}/#{SecureRandom.uuid}")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Put.new uri
        request.basic_auth Login, Password
        request.body = doc
        response = http.request request
        raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
      end
    end
    def query(body)
      uri = URI("http://#{Host}/#{@name}/_find")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Post.new uri
        request.basic_auth Login, Password
        request['Content-Type'] = 'application/json'
        body = JSON.generate({selector: JSON.parse(body)})
        request.body = body
        response = http.request request
        return response.body
      end
    end
    def replicate(to_name)
      uri = URI("http://#{Host}/_replicate")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Post.new uri
        request.basic_auth Login, Password
        request['Content-Type'] = 'application/json'
        query = {
          source: @name,
          target: to_name
        }
        request.body = JSON.generate query
        response = http.request request
        raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
        return response.body
      end
    end
  end
  def self.[](name)
    Table.new name
  end
  def self.add(name)
    uri = URI("http://#{Host}/#{name}")
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Put.new uri
      request.basic_auth Login, Password
      response = http.request request
      raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
    end
  end
  def self.delete(name)
    uri = URI("http://#{Host}/#{name}")
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Delete.new uri
      request.basic_auth Login, Password
      response = http.request request
      raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
    end
  end
  def self.list
    uri = URI("http://#{Host}/_all_dbs")
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new uri 
      request.basic_auth Login, Password
      response = http.request request
      return eval(response.body)
    end
  end
end
