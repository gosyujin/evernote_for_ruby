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
            puts @e.inputText("#{Dir.pwd}\\test\\test.txt")
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
        before do
            @e = MyEvernote.new
        end
        it "complete." do
            pp @e.findNotes()
        end
        it "complete. search word" do
            pp @e.findNotes("outlook")
        end
        it "complete. search GUID" do
            pp @e.findNotes("33880e53-4c9f-4104-a6e6-777ed1e3cef2")
        end
#        it "EDAMNotFoundException" do
#            @e.findNotes("33880e53-4c9f-4104-a6e6-777ed1e99999")
#        end
        it "complete. nothing" do
            pp @e.findNotes("hage")
        end
    end
    
    context "isGuid" do
        before do
            @e = MyEvernote.new
        end
        it "complete. true" do
            @e.isGuid("33880e53-4c9f-4104-a6e6-777ed1e3cef2").should be_true
        end
        it "complete. false" do
            @e.isGuid("97f679bf-a2cadd-f4e5sa-aqe1e-25d122087168").should be_false
            @e.isGuid("97fASASf-aadd-f4ea-aq1e-25d122087168").should be_false
            @e.isGuid("outlook").should be_false
        end
    end
end