require 'webrick'
load 'model.rb'

server = WEBrick::HTTPServer.new Port: 8080
WEBrick::HTTPUtils::DefaultMimeTypes.store('rhtml', 'text/html')
server.mount '/', WEBrick::HTTPServlet::FileHandler, '/home/oleg/taglex'
trap 'INT' do server.shutdown end
server.start
