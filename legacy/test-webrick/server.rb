require 'webrick'

server = WEBrick::HTTPServer.new Port: 8080, DocumentRoot: '/home/oleg/www/test'
server.mount_proc('/home') do |request, response|
  puts 'Response has been made'
  response.body = "Webrick is working!!!"
end
trap 'INT' do server.shutdown end
server.start
