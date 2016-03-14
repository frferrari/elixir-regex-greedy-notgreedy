defmodule Patreg do
	@moduledoc """	
	Compile with 
		mix escript.build

	Run with: 
		cat test.txt | elregex "bar %{0G} foo %{1}"
		or
		cat test.txt | elregex "bar %{0G} foo %{1}" --debug

	When --debug you will see each line of the input preceded by true of false
	depending whether or not the line matched against the regex. Also when
	the line matched you will see the list of groups that matched.
	"""
	require Logger

	@not_greedy_regex 			~r"%\\{([0-9]+)}"							# Ex: %{0} or %{1} or %{18} ...
	@greedy_regex 					~r"%\\{([0-9]+)G}"						# Ex: %{0G} or %{1G} or %{22G} ...
	@space_limitation_regex ~r"%\\{([0-9]+)S([0-9]+)}"		# Ex: %{0S1} or %{1S3} or %{18S2} or %{4S23} ...

	@doc """
	"""
	def main(args) do
    {options, argv, _} = OptionParser.parse(args, switches: [debug: :boolean])

		if length(argv) > 0 && String.length(hd(argv)) > 0 do
			process(IO.stream(:stdio, :line), hd(argv), Keyword.get(options, :debug, false))
		else
			IO.puts "Wrong arguments received on command line"
			IO.puts "Usage :"
			IO.puts "cat test.txt | elregex \"bar %{0G} foo %{1}\" [--debug]"
		end
	end

	@doc """
	Converts the input pattern given on the command-line to a perl regex, this regex will be
	compiled to improve performances, in case the regex has been successfully compiled then 
	each line	available from the stdin is read and matched against the compiled regex.

	If debug == false then the matching lines are filtered and printed
	If debug == true  then all the lines are matched against the regex and the result is 
										 printed along with the matched groups
	"""
	def process(input_stream, pattern, debug \\ true) do
		Logger.info("The input pattern is #{inspect pattern}")

		{status, result} = token_to_regex(Regex.escape(pattern), [:not_greedy, :space_limitation, :greedy])
		|> Regex.compile 

		case {status, result} do
			{:ok, compiled_regex} -> 
				case debug do
					false -> 
						match_input_lines(input_stream, compiled_regex)
					true -> 
						match_input_lines_debug(input_stream, compiled_regex)
				end

			{:error, _} -> 
				Logger.error("Error during the regex generation #{inspect result}")
				:error
		end
	end

	@doc """
	Process each line from stdin and filter those that match the compiled regex
	"""
	def match_input_lines(input_stream, compiled_regex) do
		input_stream
		|> Stream.map(&String.strip/1) # Removes the new line at the end of each line
		|> Enum.filter(fn(input_line) -> maybe_print_line(compiled_regex, input_line) end)
	end

	@doc """
	Process each line from stdin and print each line with the result of the match
	against the compiled regex along with the matched groups
	"""
	def match_input_lines_debug(input_stream, compiled_regex) do
		input_stream
		|> Stream.map(&String.strip/1) # Removes the new line at the end of each line
		|> Enum.map(fn(input_line) -> maybe_print_line_debug(compiled_regex, input_line) end)
	end

	@doc """
	Match a given string against a compiled regex and print that line if it successfully matched
	"""
	def maybe_print_line(compiled_regex, input_line) do
		if Regex.match?(compiled_regex, input_line) do
			IO.puts input_line
			true
		else
			false
		end
	end

	@doc """
	Match a given string against a compiled regex and print that line if it successfully matched
	Also prints an array of each matched group
	"""
	def maybe_print_line_debug(compiled_regex, input_line) do
		if Regex.match?(compiled_regex, input_line) do
			match = Regex.scan(compiled_regex, input_line, [capture: :all_but_first])
			Logger.info("true  > #{input_line} >>> #{inspect match}")
			match
		else
			Logger.info("false > #{input_line}")
			false
		end
	end

	@doc """
	Converts a token string to a perl regex
	"""
	def token_to_regex(pattern, _actions = []) do
		regex = "^#{pattern}$"
		Logger.info("The generated regex is #{inspect regex}")
		regex
	end

	def token_to_regex(pattern, _actions = [h|t]) do
		new_pattern = token_to_regex_action(pattern, h)
		token_to_regex(new_pattern, t)
	end

	@doc """
	Converts tokens of type %{0} to a regex
	"""
	def token_to_regex_action(pattern, _action = :not_greedy) do
		Regex.replace(@not_greedy_regex, pattern, "(?<\\1>(?:[^\s]+?[\s]*?)+?)")
	end

	@doc """
	Converts tokens of type %{0G} to a regex
	"""
	def token_to_regex_action(pattern, _action = :greedy) do
		Regex.replace(@greedy_regex, pattern, "(?<\\1>(?:[^\s]+[\s]*)+)")
	end

	@doc """
	Converts tokens of type %{1S2} to a regex
	"""
	def token_to_regex_action(pattern, _action = :space_limitation) do
		Regex.replace(@space_limitation_regex, pattern, &token_to_regex_space_limitation/3)
	end

	@doc """
	"""
	def token_to_regex_action(pattern, action) do
		IO.puts "Unhandled action #{action}"
		pattern
	end

	@doc """
	Converts tokens of type %{1S2}
	"""
	def token_to_regex_space_limitation(_the_match, arg_number_string, _space_limitation_string = "0") do
		"(?<#{arg_number_string}>[^\s]+[\s]*)"
	end

	@doc """
	Converts tokens of type %{1S2}
	"""
	def token_to_regex_space_limitation(_the_match, arg_number_string, space_limitation_string) do
		space_limitation = String.to_integer(space_limitation_string)
		"(?<#{arg_number_string}>(?:[^\s]+[\s]){#{space_limitation}}(?:[^\s]+[\s]*))"
	end
end
