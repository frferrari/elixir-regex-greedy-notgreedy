#Elixir/Erlang experiment

##Installing and running the application

You need Elixir to be installed on your computer

Extract the given file and run the tests

	mix test test/elregex_test.exs --trace

Compile the application :

	mix escript.build

Run the application :

	cat test.txt | ./elregex "foo %{0} is a %{1}" 

Run the application in debug mode :

	cat test.txt | ./elregex "foo %{0} is a %{1}" --debug
