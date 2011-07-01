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
			w.upload("Testだ#{Time.now.to_i * 1000}", "test.txt")
		end
		it "空のときはアップロードエラーになる" do
			w.upload("", "")
		end
	end

	context "ファイルを読み込むとき" do
		it "読み込みファイルの行を正規表現で捜査できる" do
			puts w.inputText("test.txt")
		end
	end
end
