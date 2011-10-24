print(package.path)

require 'metalua.compiler'
require 'metalua.mlc'
require 'serialize'

compiler = {}

compiler.loadfile = function (file)
	return mlc.luafile_to_function(file)
end

compiler.loadstring = function (str)
	return mlc.luastring_to_function(str)
end
