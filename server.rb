require 'webrick'
load 'model.rb'

server = WEBrick::HTTPServer.new Port: 8080, DocumentRoot: '/home/oleg/taglex'
WEBrick::HTTPUtils::DefaultMimeTypes.store('rhtml', 'text/html')
server.mount '/', WEBrick::HTTPServlet::FileHandler, '/home/oleg/taglex'
server.mount_proc '/refresh' do |request, response|
  data = {
    face: {
      questions: request.query['face_questions'].split("\n\n"),
      examples: request.query['face_examples'].split("\n\n")
    },
    back: {
      answers: request.query['back_answers'].split("\n\n"),
      examples: request.query['back_examples'].split("\n\n")
    }
  }
  id = request.query['id']
  Model.refresh id: id, data: data
  response.set_redirect(WEBrick::HTTPStatus::TemporaryRedirect, "/get.rhtml?id=#{id}")
end
trap 'INT' do server.shutdown end
server.start
