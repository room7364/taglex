require 'webrick'
require 'csv'
load 'model.rb'

server = WEBrick::HTTPServer.new Port: 8080, DocumentRoot: '/home/oleg/taglex'
WEBrick::HTTPUtils::DefaultMimeTypes.store('rhtml', 'text/html')
server.mount '/', WEBrick::HTTPServlet::FileHandler, '/home/oleg/taglex'
server.mount_proc '/refresh' do |request, response|
  tags = CSV.parse(request.query['tags'].force_encoding('utf-8').strip).flatten!.map { |line| line.strip }
  data = {
    face: {
      questions: request.query['face_questions'].force_encoding('utf-8').strip.split("\n\n").map { |line| line.strip },
      examples: request.query['face_examples'].force_encoding('utf-8').strip.split("\n\n").map { |line| line.strip }
    },
    back: {
      answers: request.query['back_answers'].force_encoding('utf-8').strip.split("\n\n").map { |line| line.strip },
      examples: request.query['back_examples'].force_encoding('utf-8').strip.split("\n\n").map { |line| line.strip }
    },
    tags: tags
  }
  id = request.query['id']
  Model.refresh id: id, data: data
  response.set_redirect(WEBrick::HTTPStatus::TemporaryRedirect, "/get.rhtml?id=#{id}")
end
server.mount_proc '/quested' do |request, response|
  Model.quested request.query['id']
  response.set_redirect(WEBrick::HTTPStatus::TemporaryRedirect, "/quest.rhtml")
end
trap 'INT' do server.shutdown end
server.start
