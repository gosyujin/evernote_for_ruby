require 'evernote'

if ARGV.length != 2 then
	puts "Usage: #{$0} NOTE_TITLE CONTENT_TEXT"
	exit
end

e = MyEvernote.new()
e.upload(ARGV[0], ARGV[1])

