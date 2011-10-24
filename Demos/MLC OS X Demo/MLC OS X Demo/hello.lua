-{ extension "match" }

require 'metalua.runtime'

function fib (n)
	match n with
	| 0 -> return 1
	| 1 -> return 1
	| n -> return fib(n - 1) + fib(n - 2)
	end
end

print(fib(4))
