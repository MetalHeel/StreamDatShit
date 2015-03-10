require 'rubygems'
require 'bundler/setup'

require 'ngrok/tunnel'
require 'socket'


ngrok_thread = Thread.new {
	Ngrok::Tunnel.start
	puts Ngrok::Tunnel.ngrok_url
}

socket_thread = Thread.new {
	server = TCPServer.new('localhost', 3001)

	loop do
		the_socket = server.accept
		input = the_socket.gets
		pieces = input.split(' ')
		request = pieces[1]

		STDERR.puts request
		
		path = "/home/metalheel/Music/" + request

		if File.exists?(path)
			file = File.open(path)
			chunk = file.read()

			the_socket.print "HTTP/1.1 200 OK\r\n" +
	               "Content-Type: audio/mpeg\r\n" +
	               "Connection: close\r\n"
	        the_socket.print "\r\n"

	        begin
	        	the_socket.write(chunk)
	        rescue Exception => ex
	        	STDERR.puts ex
	        end

		else
			response = "I don't know what to do with this.\r\n"
			the_socket.print "HTTP/1.1 200 OK\r\n" +
	               "Content-Type: text/plain\r\n" +
	               "Content-Length: #{response.bytesize}\r\n" +
	               "Connection: close\r\n"
	        the_socket.print "\r\n"
	        the_socket.print response
	    end
	end
}

ngrok_thread.join
socket_thread.join