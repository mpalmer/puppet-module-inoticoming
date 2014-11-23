module Puppet::Parser::Functions
	newfunction(:inoticoming_command_from_actions, :type => :rvalue) do |args|
		unless args.length == 1
			raise Puppet::ParserError,
			      "`inoticoming_command_from_actions` takes exactly one argument"
		end

		unless args[0].is_a? Array
			raise Puppet::ParserError,
			      "`inoticoming_command_from_actions` must be passed an array"
		end

		shellquote = Puppet::Parser::Functions.function(:shellquote)

		unless shellquote
			raise Puppet::Error,
			      "inoticoming_command_from_actions: could not find shellquote function"
		end

		args[0].map do |action|
			bits = []

			%w{prefix suffix regexp}.each do |opt|
				if action[opt]
					bits << send(shellquote, ["--#{opt}", action[opt]])
				end
			end

			"#{bits.join(' ')} #{action['command']} \\;"
		end.join(' ')
	end
end
