require 'rubygems'
require 'rspec'
require 'evernote'

describe MyEvernote do
    context "Initialize, auth" do
        it "complete." do
            e = MyEvernote.new
        end
    end

    context "upload" do
        it "complete." do
            e = MyEvernote.new
            e.upload("Testだ#{Time.now.to_i * 1000}", "#{Dir.pwd}\\test\\test.txt")
        end
#        it "空のときはアップロードエラーになる" do
#            e = MyEvernote.new
#            e.upload("", "")
#        end
    end
end
