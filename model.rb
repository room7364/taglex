load 'couch/couch.rb'
require 'json'
module Model
  def self.find(word)
    responses = Couch['taglex']['words'].find word
    data = responses.map { |response| JSON.parse response }
    data.map do |card|
      card.filter { |key, value| key[0] != '_' }
    end
  end
end
