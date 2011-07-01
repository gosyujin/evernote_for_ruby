#!/bin/ruby
# = Evernoteを操作するクラス
dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.push("#{dir}/lib/ruby")
$LOAD_PATH.push("#{dir}/lib/ruby/Evernote/EDAM")

require 'thrift/types'
require 'thrift/struct'
require 'thrift/protocol/base_protocol'
require 'thrift/protocol/binary_protocol'
require 'thrift/transport/base_transport'
require 'thrift/transport/http_client_transport'
require 'Evernote/EDAM/user_store'
require 'Evernote/EDAM/user_store_constants.rb'
require 'Evernote/EDAM/note_store'
require 'Evernote/EDAM/limits_constants.rb'

require 'rubygems'
require 'pit'
require 'pp'

class Write
	# 初期化処理。ユーザ名、パスワードを入力し認証を行う。
	def initialize
		# https://sandbox.evernote.com/Registration.action
		# まずはsandboxで新規ユーザ登録！
		@user = Pit.get("evernote", :require => {
			"userName" => "your evernote userName.", 
			"password" => "your evernote password.", 
			"consumerKey" => "your evernote consumerKey.", 
			"consumerSecret" => "your evernote consumerSecret.", 
		})
		# Pitを使わずにソース内にべた書き用
		# @user = {
		#	"userName" => "your evernote userName.", 
		#	"password" => "your evernote password.", 
		#	"consumerKey" => "your evernote consumerKey.", 
		#	"consumerSecret" => "your evernote consumerSecret.", 
		#}

		evernoteHost = "sandbox.evernote.com"
		userStoreUrl = "https://#{evernoteHost}/edam/user"
		userStoreTransport = Thrift::HTTPClientTransport.new(userStoreUrl)
		userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
		@userStore = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)
		@auth = auth()
		# Tokenだけ別出し
		@authToken = @auth.authenticationToken
		
		noteStoreUrlBase = "https://#{evernoteHost}/edam/note/"
		noteStoreUrl = noteStoreUrlBase + @auth.user.shardId
		noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
		noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
		@noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
	end

	# ユーザ認証を行う。認証に成功した場合AuthenticationResultを返す。認証に失敗した場合終了する。
	def auth
		begin
			authResult = @userStore.authenticate(
				@user["userName"], @user["password"], 
				@user["consumerKey"], @user["consumerSecret"])
			puts "Auth: #{authResult.user.username}"
			return authResult
		rescue Evernote::EDAM::Error::EDAMUserException
			puts "Auth: error."
			puts "Exit."
			exit
		end
	end
	
	# 引き数に指定されたファイルを読み込む。文末に<br/>を加える
	# タブを&nbsp;、<を&lt;、>を&gt;に変換する。
	def inputText(path)
		text = ""
		File::open(path).each do |f|
			if f =~ /.*\t.*/ then
				# <>も変換する？
				f.gsub!(/\t/, '&nbsp;&nbsp;&nbsp;&nbsp;')
				f.gsub!(/</, '&lt;')
				f.gsub!(/>/, '&gt;')
			end
			text += f + '<br/>'
		end
		return text
	end

	# アップロードを行う。
	def upload(title, path, defaultNotebook=nil)
		# ファイル読み込み
		# 存在チェック
		text = inputText(path)

		# up先ノートブック
		up = nil
		# Notebookのリストを取得
		notebooks = @noteStore.listNotebooks(@authToken)
		notebooks.each do |notebook|
			puts "IsDefault?: #{notebook.defaultNotebook} ,Name: #{notebook.name}"
			# デフォルトになっているノートブックを確認
			if notebook.defaultNotebook then
				 up = notebook
			end
		end

		# ノート作成
		note = Evernote::EDAM::Type::Note.new()
		note.title = title
		note.content = '<?xml version="1.0" encoding="UTF-8"?>' +
			'<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml.dtd">' +
			'<en-note>' + text + '</en-note>'
		note.created = Time.now.to_i * 1000
		note.updated = note.created
		begin
			result = @noteStore.createNote(@authToken, note)
			puts "Upload: complete."
			puts "       Title: #{result.title}"
			puts "       Created: #{result.created}"
		rescue Evernote::EDAM::Error::EDAMUserException => ex
			puts "Upload: error. "
			puts ex.class
			puts ex.message
			puts ex.backtrace
		rescue => ex
			puts "Upload: error. #{ex}"
			puts ex.class
			puts ex.message
			puts ex.backtrace
		end
	end
end

#w = Write.new
#w.upload(ARGV[0], ARGV[1])
