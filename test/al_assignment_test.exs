defmodule AlAssignmentTest do
	use ExUnit.Case, async: false

	import Patreg
  doctest AlAssignment

	setup_all do
		{:ok, [	sample: [	"foo blah is a bar", 
											"foo blah is a very big boat",
											"foo blah is bar",
											"foo blah",
											"foo blah is",
											"the big brown fox ran away",
											"bar foo bar foo bar foo bar foo",
											"one two three four five six seven eight nine ten eleven twelve",
											"the %{1bad} ran away big brown fox",
											"r.g{}[]|%$^\()e*+?x [i]njection",
											"the big brown fox ran away big brown lion"
						 				]
					]
		}
	end

	test "It should succeed when getting a regex for a space_limitation action" do
		assert token_to_regex_space_limitation("", "3", "1") == "(?<3>(?:[^ ]+[ ]){1}(?:[^ ]+[ ]*))"
		assert token_to_regex_space_limitation("", "0", "2") == "(?<0>(?:[^ ]+[ ]){2}(?:[^ ]+[ ]*))"
		assert token_to_regex_space_limitation("", "8", "25") == "(?<8>(?:[^ ]+[ ]){25}(?:[^ ]+[ ]*))"
	end

	test "It should succeed when converting a token string with :space_limitation" do
		assert token_to_regex(Regex.escape("My %{0S1} is %{1S0} rich"), [:space_limitation])  == "^My\\ (?<0>(?:[^ ]+[ ]){1}(?:[^ ]+[ ]*))\\ is\\ (?<1>[^ ]+[ ]*)\\ rich$"
		assert token_to_regex(Regex.escape("My %{0S2} is %{1S12} rich"), [:space_limitation]) == "^My\\ (?<0>(?:[^ ]+[ ]){2}(?:[^ ]+[ ]*))\\ is\\ (?<1>(?:[^ ]+[ ]){12}(?:[^ ]+[ ]*))\\ rich$"
	end

	test "It should succeed when converting a token string with :greedy" do
		assert token_to_regex(Regex.escape("My %{0G} is %{1G} rich"), [:greedy]) == "^My\\ (?<0>(?:[^ ]+[ ]*)+)\\ is\\ (?<1>(?:[^ ]+[ ]*)+)\\ rich$"
	end

	test "It should succeed when converting a token string with :not_greedy" do
		assert token_to_regex(Regex.escape("My %{0} is %{1} rich"), [:not_greedy]) == "^My\\ (?<0>(?:[^ ]+?[ ]*?)+?)\\ is\\ (?<1>(?:[^ ]+?[ ]*?)+?)\\ rich$"
	end

	test "It should succeed when applying the set of 3 actions" do
		assert token_to_regex(Regex.escape("My %{0} is %{1S2} rich and %{0G}"), [:not_greedy, :space_limitation, :greedy]) == "^My\\ (?<0>(?:[^ ]+?[ ]*?)+?)\\ is\\ (?<1>(?:[^ ]+[ ]){2}(?:[^ ]+[ ]*))\\ rich\\ and\\ (?<0>(?:[^ ]+[ ]*)+)$"
	end

	#
	#
	#
	test "It should succeed when applying an unsuited action" do
		assert token_to_regex(Regex.escape("My %{0G} is rich"), [:space_limitation]) == "^My\\ %\\{0G}\\ is\\ rich$"
		assert token_to_regex(Regex.escape("My %{0} is rich"), [:space_limitation]) == "^My\\ %\\{0}\\ is\\ rich$"

		assert token_to_regex(Regex.escape("My %{0} is %{1} rich"), [:greedy]) == "^My\\ %\\{0}\\ is\\ %\\{1}\\ rich$"
		assert token_to_regex(Regex.escape("My %{0S1} is %{1S5} rich"), [:greedy]) == "^My\\ %\\{0S1}\\ is\\ %\\{1S5}\\ rich$"

		assert token_to_regex(Regex.escape("My %{0G} is %{1G} rich"), [:not_greedy]) == "^My\\ %\\{0G}\\ is\\ %\\{1G}\\ rich$"
		assert token_to_regex(Regex.escape("My %{0S1} is %{1S2} rich"), [:not_greedy]) == "^My\\ %\\{0S1}\\ is\\ %\\{1S2}\\ rich$"
	end

	test "It should succeed when converting a token string with an unknown action" do
		assert token_to_regex(Regex.escape("My %{0} is rich"), [:dummy]) == "^My\\ %\\{0}\\ is\\ rich$"
	end

	#
	#
	#
	test "It should succeed when processing a string sample against foo %{0} is a %{1}", context do
		assert process(Stream.map(context[:sample], &(&1)), "foo %{0} is a %{1}") == [[["blah", "bar"]], [["blah", "very big boat"]], false, false, false, false, false, false, false, false, false]
	end

	test "It should succeed when processing a string sample against foo %{0} is a %{1S0}", context do
		assert process(Stream.map(context[:sample], &(&1)), "foo %{0} is a %{1S0}") == [[["blah", "bar"]], false, false, false, false, false, false, false, false, false, false]
	end

	test "It should succeed when processing a string sample against foo %{0} is %{1S0} bar", context do
		assert process(Stream.map(context[:sample], &(&1)), "foo %{0} is %{1S0} bar") == [[["blah", "a"]], false, false, false, false, false, false, false, false, false, false]
	end

	test "It should succeed when processing a string sample against foo %{0} %{1S0} a bar", context do
		assert process(Stream.map(context[:sample], &(&1)), "foo %{0} %{1S0} a bar") == [[["blah", "is"]], false, false, false, false, false, false, false, false, false, false]
	end

	test "It should succeed when processing a string sample against foo %{0} %{1S1} bar", context do
		assert process(Stream.map(context[:sample], &(&1)), "foo %{0} %{1S1} bar") == [[["blah", "is a"]], false, false, false, false, false, false, false, false, false, false]
	end

	test "It should succeed when processing a string sample against the %{0S1} %{1} ran away", context do
		assert process(Stream.map(context[:sample], &(&1)), "the %{0S1} %{1} ran away") == [false, false, false, false, false, [["big brown", "fox"]], false, false, false, false, false]
	end

	test "It should succeed when processing a string sample against the %{0S1} fox ran %{1}", context do
		assert process(Stream.map(context[:sample], &(&1)), "the %{0S1} fox ran %{1}") == [false, false, false, false, false, [["big brown", "away"]], false, false, false, false, [["big brown", "away big brown lion"]]]
	end

	test "It should succeed when processing a string sample against the %{0S1} fox %{1}", context do
		assert process(Stream.map(context[:sample], &(&1)), "the %{0S1} fox %{1}") == [false, false, false, false, false, [["big brown", "ran away"]], false, false, false, false, [["big brown", "ran away big brown lion"]]]
	end

	test "It should succeed when processing a string sample against the %{0S1} %{1}", context do
		assert process(Stream.map(context[:sample], &(&1)), "the %{0S1} %{1}") == [false, false, false, false, false, [["big brown", "fox ran away"]], false, false, [["%{1bad} ran", "away big brown fox"]], false, [["big brown", "fox ran away big brown lion"]]]
	end

	test "It should succeed when processing a string sample against the %{0S4}", context do
		assert process(Stream.map(context[:sample], &(&1)), "the %{0S4}") == [false, false, false, false, false, [["big brown fox ran away"]], false, false, false, false, false]
	end

	test "It should succeed when processing a string sample against the %{0S1} fox %{1S1}", context do
		assert process(Stream.map(context[:sample], &(&1)), "the %{0S1} fox %{1S1}") == [false, false, false, false, false, [["big brown", "ran away"]], false, false, false, false, false]
	end

	test "It should succeed when processing a string sample against %{0S1} brown fox %{1S1}", context do
		assert process(Stream.map(context[:sample], &(&1)), "%{0S1} brown fox %{1S1}") == [false, false, false, false, false, [["the big", "ran away"]], false, false, false, false, false]
	end

	test "It should succeed when processing a string sample against %{0G} fox %{1S1}", context do
		assert process(Stream.map(context[:sample], &(&1)), "%{0G} fox %{1S1}") == [false, false, false, false, false, [["the big brown", "ran away"]], false, false, false, false, false]
	end

	test "It should succeed when processing a string sample against %{0} fox %{1S1}", context do
		assert process(Stream.map(context[:sample], &(&1)), "%{0} fox %{1S1}") == [false, false, false, false, false, [["the big brown", "ran away"]], false, false, false, false, false]
	end

	test "It should succeed when processing a string sample against bar %{0G} foo %{1}", context do
		assert process(Stream.map(context[:sample], &(&1)), "bar %{0G} foo %{1}") == [false, false, false, false, false, false, [["foo bar foo bar", "bar foo"]], false, false, false, false]
	end

	test "It should succeed when processing a string sample against the %{1} ran away %{2} fox", context do
		assert process(Stream.map(context[:sample], &(&1)), "the %{1} ran away %{2} fox") == [false, false, false, false, false, false, false, false, [["%{1bad}", "big brown"]], false, false]
	end

	test "It should succeed when processing a string sample against one %{1S3} %{2G} %{3S2} %{4G} eleven twelve", context do
		assert process(Stream.map(context[:sample], &(&1)), "one %{1S3} %{2} %{3S2} %{4} eleven twelve") == [false, false, false, false, false, false, false, [["two three four five", "six", "seven eight nine", "ten"]], false, false, false]
	end

	#
	#
	#
	test "It should succeed when processing a string sample against r.g{}[]|%$^\()e*+?x %{0}", context do
		assert process(Stream.map(context[:sample], &(&1)), "r.g{}[]|%$^\()e*+?x %{0}") == [false, false, false, false, false, false, false, false, false, [["[i]njection"]], false]
	end

	test "It should succeed when processing a string sample against the %{1} ran %{2} fox", context do
		assert process(Stream.map(context[:sample], &(&1)), "the %{1} ran %{2} fox") == [false, false, false, false, false, false, false, false, [["%{1bad}", "away big brown"]], false, false]
	end
	
	test "It should succeed when processing a string sample against the foo %{1} is a %{1}", context do
		assert process(Stream.map(context[:sample], &(&1)), "foo %{1} is a %{1}") == :error
	end
end
