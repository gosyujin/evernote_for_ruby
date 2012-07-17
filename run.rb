require 'evernote'

if ARGV.length == 0 then
	puts "Usage: #{$0} NOTE_TITLE CONTENT_TEXT"
	puts "       #{$0} sync"
	exit
end

e = MyEvernote.new()
if ARGV[0] == "sync" then
	e.sync
	e.get_upload
else
	e.upload(ARGV[0], ARGV[1])
end
