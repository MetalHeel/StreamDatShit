module NgrokWrapper

	class ProcessWrapper
		def start(console_statement)
			@@process_id = spawn(console_statement)
		end

		def finish
			Process.kill(@@process_kill_const, @@process_id)
		end

		private
			@@process_kill_const = 9
			@@process_id = 0
	end

	class LogReader
		attr_accessor :file_name

		def initialize(file_name)
			@file_name = file_name
		end

		def read_all()
			File.open(@file_name, 'rb') {|f| f.read}
		end

		def get_lines_by_expression(expression)
			text = read_all
			regex = Regexp.new(expression)
			regex.match(text)
		end

		def single_match_by_expression(expression)
			get_lines_by_expression(expression)[-1]
		end

		def polling_log_yields_change(poll_wait = nil, previous_content = nil)
			previous_content = (previous_content == nil ? "" : previous_content)
			poll_wait = (poll_wait == nil ? 10 : poll_wait)
			tally = 0
			while read_all == previous_content do
				tally += 1
				if (tally > poll_wait)
					return false
				end
				sleep(1)
			end
			return true
		end

		def create
			destroy
			file = File.new(@file_name, 'w')
			file.close if !file.closed?
		end

		def destroy
			File.delete(file_name) if File.exists?(file_name)
		end
	end

	class NgrokFacade
		attr_reader :port, :url, :log_reader
		
		def initialize(port, log_file)
			@port = port
			@log_reader = LogReader.new(log_file)
		end

		def start
			@log_reader.create
			console_input = "./ngrok -log=#{@log_reader.file_name} #{@port}"
			@@proc_wrapper.start(console_input)
			if (log_reader.polling_log_yields_change)
				@url = pry_url_from_log_file
				@log_reader.destroy
			end
		end

		def finish
			@@proc_wrapper.finish
		end

		private
			@@proc_wrapper = ProcessWrapper.new
			
			def pry_url_from_log_file()
				expr = "(?<=Tunnel established).*(http:\/\/.*$)"
				@log_reader.single_match_by_expression(expr)
			end
	end
end

#usage example
ngrok_facade = NgrokWrapper::NgrokFacade.new(3001, 'logfile1.txt')

#starts ngrok
ngrok_facade.start

#ngrok url
puts ngrok_facade.url

#kills ngrok process
ngrok_facade.finish