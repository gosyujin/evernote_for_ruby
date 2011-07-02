require 'write'

if ARGV.length != 2 then
	puts "Usage: #{$0} NOTE_TITLE CONTENT_TEXT"
	exit
end

w = Write.new()
w.upload(ARGV[0], ARGV[1])

