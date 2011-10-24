print('harro')
print(package.path)

package.path = "?;?.lua;?.luac;/usr/local/lib/?.luac;/usr/local/lib/?.lua"
print(package.path)

require 'metalua.mlc'

print(tostring(mlc.convert))
