load 'couch/couch.rb'
require 'json'
module Model
  def self.find(word)
    response = Couch['taglex']['words'].find word
    data = JSON.parse(response[0])
    data.filter { |key, value| key[0] != '_' }
  end
end
