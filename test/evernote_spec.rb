require 'rubygems'
require 'rspec'
require 'evernote'
require 'pp'

describe MyEvernote do
    context "Initialize, auth" do
        it "complete." do
            @e = MyEvernote.new
        end
    end

    context "inputText" do
        before do
            @e = MyEvernote.new
        end
        it "complete." do
            puts @e.inputText("#{Dir.pwd}/test.txt")
        end
    end
    
    context "getNotebooks" do
        before do
            @e = MyEvernote.new
        end
        it "complete." do
            pp @e.getNotebooks
        end
    end
    
    context "getDefaultNotebook" do
        before do
            @e = MyEvernote.new
        end
        it "complete." do
            pp @e.getDefaultNotebook
        end
    end
    
    context "findNotes" do
        word = "outlook"
        notebook = "Sandbox"
        guid = "33880e53-4c9f-4104-a6e6-777ed1e3cef2"
        nothWord = "hage"
        
        before do
            @e = MyEvernote.new
        end
        it "complete. all" do
            pp @e.findNotes()
        end
        it "complete. search word: #{word}" do
            pp @e.findNotes(word)
        end
        it "complete. search GUID: #{guid}" do
            pp @e.findNotes(guid)
        end
        it "complete. search notebook: #{notebook}" do
            pp @e.findNotes(@e.getNotebooks.index(notebook))
        end
        it "complete. nothing: #{nothWord}" do
            pp @e.findNotes(nothWord)
        end
#        it "EDAMNotFoundException" do
#            @e.findNotes("33880e53-4c9f-4104-a6e6-777ed1e99999")
#        end
    end
    
    context "sync" do
        before do
            @e = MyEvernote.new
        end
        it "complete. " do
            @e.sync()
        end
    end
    
    context "isGuid" do
        guid = "33880e53-4c9f-4104-a6e6-777ed1e3cef2"
        no_guid = ["8e53-4c9f-4104-a6e6-777ed1e3cef2",
            "97fASASf-aadd-f4ea-aq1e-25d122087168",
            "outlook"
        ]
        before do
            @e = MyEvernote.new
        end
        it "complete. true: #{guid}" do
            @e.isGuid(guid).should be_true
        end
        it "complete. false: #{no_guid.join(",")}" do
            no_guid.each do |guid|
                @e.isGuid(guid).should be_false
            end
        end
    end
end
