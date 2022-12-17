module Couch
  class BadResponse < Exception
  end
  require 'net/http'
  require 'json'
  require 'securerandom'
  config_file = File.open "./config.json"
  config = JSON.load config_file
  config_file.close
  Host = "#{config['host']}:5984"
  Login = config["login"]
  Password = config["password"]
  module Tables
    def Tables.add(db_name)
      uri = URI("http://#{Host}/#{db_name}")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Put.new uri
        request.basic_auth Login, Password
        response = http.request request
        raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
      end
    end
    def Tables.delete(db_name)
      uri = URI("http://#{Host}/#{db_name}")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Delete.new uri
        request.basic_auth Login, Password
        response = http.request request
        raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
      end
    end
    def Tables.list
      uri = URI("http://#{Host}/_all_dbs")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri 
        request.basic_auth Login, Password
        response = http.request request
        return eval(response.body)
      end
    end
  end
  class Doc
    def initialize(data)
      @data = data
    end
    def push(db_name)
      uri = URI("http://#{Host}/#{db_name}/#{SecureRandom.uuid}")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Put.new uri
        request.basic_auth Login, Password
        request.body = JSON.generate @data
        response = http.request request
        raise BadResponse, response.body if not JSON.parse(response.body)["ok"]
      end
    end
  end
  class Table
    def initialize(name)
      @name = name
    end
    def query(hash)
      uri = URI("http://#{Host}/#{@name}/_find")
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Post.new uri
        request.basic_auth Login, Password
        request['Content-Type'] = 'application/json'
        request.body = JSON.generate({selector: hash})
        response = http.request request
        return JSON.parse(response.body)
      end
    end
  end
end
