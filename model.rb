load 'couch/couch.rb'
require 'json'
module Model
  def self.stems(word)
    uri = URI "https://dictionaryapi.com/api/v3/references/collegiate/json/#{word}?key=76c8c286-f23a-4067-9773-dc26eed295dd"
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new uri
      response = http.request request
      data = JSON.parse(response.body)
      arrays = data.map { |elem| elem['meta']['stems'] }
      arrays.inject { |accum, array| accum + array }
    end
  end
  def self.find(word)
    responses = Couch['taglex']['words'].find word
    data = responses.map { |response| JSON.parse response }
    data.map do |card|
      card.filter { |key, value| key[0] != '_' }
    end
  end
end
