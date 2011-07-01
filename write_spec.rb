require 'rubygems'
require 'rspec'
require 'write'

describe Write do
	w = Write.new
	context "認証を行うとき" do
		it "正常に認証できる" do
		end
	end
	context "Uploadするとき" do
		it "正常にアップできる" do
			w.upload("Testだ#{Time.now.to_i * 1000}", "test")
		end
		it "空のときはアップロードエラーになる" do
			w.upload("", "")
		end
	end
end
