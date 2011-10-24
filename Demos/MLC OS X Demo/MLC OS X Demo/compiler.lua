print(package.path)

require 'metalua.compiler'
require 'metalua.mlc'
require 'serialize'

compiler = {}

compiler.loadfile = function (file)
	return mlc.luafile_to_function(file)
end
