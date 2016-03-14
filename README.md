#Elixir/Erlang assignment

##Installing and running the application

You need Elixir to be installed on your computer

Extract the given file and run the tests

	mix test test/al_assignment_test.exs --trace

Compile the application :

	mix escript.build

Run the application :

	cat test.txt | al_assignment "foo %{0} is a %{1}" 

Run the application in debug mode :

	cat test.txt | al_assignment "foo %{0} is a %{1}" --debug
