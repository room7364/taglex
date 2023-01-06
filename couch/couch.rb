require 'base64'
require 'net/http'
require 'json'
require 'securerandom'
module Couch
  class BadResponse < Exception
  end
  config_file = File.open "./couch/config.json"
  config = JSON.load config_file
  config_file.close
  Host = "#{config['host']}:5984"
  Login = config["login"]
  Password = config["password"]
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
  def self.views(table)
    uri = URI("http://#{Host}/#{table}/_design/main")
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new uri
      request.basic_auth Login, Password
      response = http.request request
      return JSON.parse(response.body)['views'].keys
    end
  end
  def self.map(table:, view:, js_func:)
    uri = URI("http://#{Host}/#{table}/_design/main")
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Put.new uri
      request.basic_auth Login, Password
      request.body = JSON.generate({
        views: {
         view => {
           map: js_func
         }
        }
      }) 
      response = http.request request
      raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
      return response
    end
  end
  def view(table:, view:)
    uri = URI("http://#{Host}/#{table}/_design/main/_view/#{view}")
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new uri
      request.basic_auth Login, Password
      response = http.request request
      raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
      return response
    end
  end
  def replicate(from:, to:)
    uri = URI("http://#{Host}/_replicate")
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Post.new uri
      request.basic_auth Login, Password
      request['Content-Type'] = 'application/json'
      query = {
        source: from,
        target: to
      }
      request.body = JSON.generate query
      response = http.request request
      raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
      return response.body
    end
  end
  module Docs
    def self.get(table:, id:)
      uri = URI("http://#{Host}/#{table}/#{id}")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri
        request.basic_auth Login, Password
        response = http.request request
        return response.body
      end
    end
    def self.select(table:, attr:, value:)
      uri = URI("http://#{Host}/#{table}/_design/main/_view/#{attr}?key=\"#{value}\"")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri
        request.basic_auth Login, Password
        response = http.request request
        docs = JSON.parse(response.body)["rows"].map { |row| self.get(table: table, id: row["id"]) }
        return docs 
      end
    end
    def self.refresh(table:, id:, doc:)
      source = self.get table: table, id: id
      revision = JSON.parse(source)["_rev"]
      data = JSON.parse doc
      data["_rev"] = revision
      doc = JSON.generate data
      uri = URI("http://#{Host}/#{table}/#{id}")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Put.new uri
        request.basic_auth Login, Password
        request.body = doc
        response = http.request request
        raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
      end
    end
    def push(table:, doc:)
      uri = URI("http://#{Host}/#{table}/#{SecureRandom.uuid}")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Put.new uri
        request.basic_auth Login, Password
        request.body = doc
        response = http.request request
        raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
      end
    end
    def query(table:, body:)
      uri = URI("http://#{Host}/#{table}/_find")
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
  end
end
