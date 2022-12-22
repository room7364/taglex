load 'couchlib.rb'
class Input
  Map = {
    "?" => {side: :face, type: :questions},
    ">" => {side: :face, type: :examples},
    "!" => {side: :back, type: :answers},
    "<" => {side: :back, type: :examples}
  }
  def initialize(line)
    @markup = line.slice!(0)
    @content = line
  end
  def valid?
    Map.key? @markup
  end
  def content
    @content
  end
  def side
    self.valid? ? Map[@markup][:side] : nil
  end
  def type
    self.valid? ? Map[@markup][:type] : nil
  end
end
def init_doc
  {
    face: {
      questions: Array.new,
      examples: Array.new
    },
    back: {
      answers: Array.new,
      examples: Array.new
    }
  }
end
doc = init_doc
current_side = :face
counter = 0
File.readlines('cards_01.txt').each do |line|
  puts line.dump
  input = Input.new(line)
  if input.valid? then
    if current_side == :back && input.side == :face then
      doc = Couch::Doc.new doc
      doc.push "taglex"
      counter = counter + 1
      doc = init_doc
    end
    doc[input.side][input.type].append input.content
    current_side = input.side
  end
  #puts "Continue?"
  #i = gets.chomp
  #break if i != "y"
end
puts "#{counter} cards added"
