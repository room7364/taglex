load 'couch/couch.rb'
require 'json'
module Model
  def self.stems(word)
    uri = URI "https://dictionaryapi.com/api/v3/references/collegiate/json/#{word}?key=76c8c286-f23a-4067-9773-dc26eed295dd"
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new uri
      response = http.request request
      data = JSON.parse(response.body)
      return data if data.size == 0
      arrays = data.map { |elem| elem['meta']['stems'] }
      stems = arrays.inject { |accum, array| accum + array }
      stems.filter! { |stem| stem.split.size == 1 }
      stems.uniq
    end
  end
  def self.get(id)
    JSON.parse Couch::Docs.get(table: "taglex", id: id)
  end
  def self.oldest
    JSON.parse Couch::Docs.oldest("taglex")
  end
  def self.find(word)
    responses = Couch::Docs.select table: "taglex", attr: "words", value: word
    responses.map { |response| JSON.parse response }
  end
  def self.refresh(id:, data:)
    Couch::Docs.refresh table: "taglex", id: id, doc: JSON.generate(data)
  end
  def self.quested(id)
    data = self.get id
    if data['quested'] then
      data['quested'] = data['quested'] + 1
    else
      data['quested'] = 1
    end
    self.refresh id:id, data: data
  end
end
