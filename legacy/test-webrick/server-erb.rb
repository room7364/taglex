require 'webrick'

server = WEBrick::HTTPServer.new Port: 8080
WEBrick::HTTPUtils::DefaultMimeTypes.store('rhtml', 'text/html')
server.mount '/', WEBrick::HTTPServlet::FileHandler, '/home/oleg/www/test'
trap 'INT' do server.shutdown end
server.start
