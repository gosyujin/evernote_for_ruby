#!/bin/ruby
# = Evernoteを操作するクラス
dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.push("#{dir}/lib/")
$LOAD_PATH.push("#{dir}/lib/Evernote/EDAM")

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
require 'syslog'

class MyEvernote
    # 初期化処理。ユーザ名、パスワードを入力し認証を行う。
    def initialize
        # https://sandbox.evernote.com/Registration.action
        # まずはsandboxで新規ユーザ登録！
        user = Pit.get("evernote", :require => {
            "developerToken" => "your evernote token.", 
            "userName" => "your evernote userName.", 
            "password" => "your evernote password.", 
            "consumerKey" => "your evernote consumerKey.", 
            "consumerSecret" => "your evernote consumerSecret.", 
        })
        userTo = Pit.get("evernoteTo", :require => {
            "developerToken" => "your evernote token.", 
            "userName" => "your evernote userName.", 
            "password" => "your evernote password.", 
            "consumerKey" => "your evernote consumerKey.", 
            "consumerSecret" => "your evernote consumerSecret.", 
        })
        # Pitを使わずにソース内にべた書き用
        # user = {
        #    "userName" => "your evernote userName.", 
        #    "password" => "your evernote password.", 
        #    "consumerKey" => "your evernote consumerKey.", 
        #    "consumerSecret" => "your evernote consumerSecret.", 
        #}
        # userTo = {
        #    "userName" => "your evernote userName.", 
        #    "password" => "your evernote password.", 
        #    "consumerKey" => "your evernote consumerKey.", 
        #    "consumerSecret" => "your evernote consumerSecret.", 
        #}
        
        evernoteHost = "sandbox.evernote.com"
        userStoreUrl = "https://#{evernoteHost}/edam/user"
        userStoreTransport = Thrift::HTTPClientTransport.new(userStoreUrl)
        userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
        userStore = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)
        # 認証
        #@auth = auth(user, userStore)
        #@authToken = @auth.authenticationToken
        @authToken = user["developerToken"]

        noteStoreUrlBase = "https://#{evernoteHost}/edam/note/"
        noteStoreUrl = userStore.getNoteStoreUrl(@authToken)
        noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
        noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
        @noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
        
        evernoteHostTo = "www.evernote.com"
        userStoreUrlTo = "https://#{evernoteHostTo}/edam/user"
        userStoreTransportTo = Thrift::HTTPClientTransport.new(userStoreUrlTo)
        userStoreProtocolTo = Thrift::BinaryProtocol.new(userStoreTransportTo)
        userStoreTo = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocolTo)
        # 同期先アカウント
        #@authTo = auth(userTo, userStoreTo)
        #@authTokenTo = @authTo.authenticationToken
        @authTokenTo = userTo["developerToken"]

        noteStoreUrlBaseTo = "https://#{evernoteHostTo}/edam/note/"
        noteStoreUrlTo = userStoreTo.getNoteStoreUrl(@authTokenTo)
        noteStoreTransportTo = Thrift::HTTPClientTransport.new(noteStoreUrlTo)
        noteStoreProtocolTo = Thrift::BinaryProtocol.new(noteStoreTransportTo)
        @noteStoreTo = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocolTo)
    end

    # ユーザ認証を行う。認証に成功した場合AuthenticationResultを返す。認証に失敗した場合終了する。
    def auth(user, userStore)
        # バージョンチェック
        versionOK = userStore.checkVersion("Ruby EDAMTest",
                        Evernote::EDAM::UserStore::EDAM_VERSION_MAJOR,
                        Evernote::EDAM::UserStore::EDAM_VERSION_MINOR)
        # puts "Is my EDAM protocol version up to date?  #{versionOK}"
        if (!versionOK) then
            exit(1)
        end
        begin
            authResult = userStore.authenticate(
                user["userName"],
                user["password"],
                user["consumerKey"],
                user["consumerSecret"])
            # puts "Auth: #{authResult.user.username}"
            return authResult
        rescue Evernote::EDAM::Error::EDAMUserException => ex
            parameter = ex.parameter
            errorCode = ex.errorCode
            errorText = Evernote::EDAM::Error::EDAMErrorCode::VALUE_MAP[errorCode]
            puts "Auth: #{errorText}, Parameter: #{parameter}, ErrorCode: #{errorCode}"
            exit
        end
    end
    
    # 引き数に指定されたファイルを読み込む。文末に<br/>を加える
    def inputText(path)
        text = ""
        File::open(path).each do |f|
            f.gsub!(/&/, '&amp;')
            f.gsub!(/ /, '&nbsp;') 
            f.gsub!(/</, '&lt;')
            f.gsub!(/>/, '&gt;')
            f.gsub!(/"/, '&quot;')
            if f =~ /.*\t.*/ then
                f.gsub!(/\t/, '&nbsp;&nbsp;&nbsp;&nbsp;')
            end
            text += f + '<br/>'
        end
        return text
    end
    
    # 2つのアカウント間のSandboxノートを同期
    def sync()
        # "Sandbox"のnote一覧(GUID)を取得
        notes = findNotes(getNotebooks.index("Sandbox"))
        notes.each do |key, value|
            # GUIDを元にnoteを取得
            note = @noteStore.getNote(@authToken, key, true, true, true, true)
            # タイトルの頭に"sandbox "を追加
            note.title = "sandbox " + note.title
            puts note.title
            # notebookGuidを同期先のGUIDに変更
            note.notebookGuid = "a81435b5-66cc-49a0-b45c-cf5c27cdceed"
            @noteStoreTo.createNote(@authTokenTo, note)
            # 再取得 
            note = @noteStore.getNote(@authToken, key, true, true, true, true)
            # notebookGuidをWaitのGUIDに変更
            note.notebookGuid = "2d8ec8b5-5706-434d-a1dc-4ea0c6ba1993"
            @noteStore.updateNote(@authToken, note)
        end
    end
    
    # アップロードを行う。
    def upload(title, path, defaultNotebook=nil)
        # ファイル読み込み
        # 存在チェック
        text = inputText(path)
        
        # デフォルトノートブックを取得
        up = getDefaultNotebook.values[0]
        
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
            puts "       Notebook: #{up}"
            puts "       Title:    #{result.title}"
            puts "       Created:  #{result.created}"
        rescue Evernote::EDAM::Error::EDAMUserException => ex
            parameter = ex.parameter
            errorCode = ex.errorCode
            errorText = Evernote::EDAM::Error::EDAMErrorCode::VALUE_MAP[errorCode]
            puts "Upload: #{errorText}, Parameter: #{parameter}, ErrorCode: #{errorCode}"
        rescue => ex
            puts "Upload: error. #{ex}"
            puts ex.class
            puts ex.message
            puts ex.backtrace
        end
    end
    
    # ノートブック名とGUIDの一覧を取得する
    def getNotebooks()
        notemap = {}
        notebooks = @noteStore.listNotebooks(@authToken)
        notebooks.each do |notebook|
            # puts "IsDefault?: #{notebook.defaultNotebook}"
            notemap[notebook.guid] = notebook.name
        end
        return notemap
    end
    
    # デフォルトノートブック名とGUIDを取得する
    def getDefaultNotebook()
        { @noteStore.getDefaultNotebook(@authToken).guid => 
            @noteStore.getDefaultNotebook(@authToken).name }
    end
    
    # ノート名とGUIDを取得する
    def findNotes(arg=nil)
        notemap = {}
        filter = Evernote::EDAM::NoteStore::NoteFilter.new
        if arg != nil then
            if isGuid(arg) then
                filter.notebookGuid = arg
            else
                filter.words = arg
            end
        end
        
        begin
            notebooks = @noteStore.findNotes(@authToken, filter, 0, 15)
        rescue Evernote::EDAM::Error::EDAMNotFoundException => ex
            puts "Find: error. #{ex}"
            puts ex.class
            puts ex.message
            puts ex.backtrace
            exit
        end

        notebooks.notes.each do |note|
            notemap[note.guid] = note.title
        end
        return notemap
    end
    
    # GUIDかどうかの判定を行う
    def isGuid(guid)
        if guid =~ /[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}/ then
            return true
        else
            return false
        end
    end
    
    # 使用量を取得
    def get_upload()
        sync_state = @noteStoreTo.getSyncState(@authTokenTo)
        puts "syslog"
        Syslog.open("Evernote")
        Syslog.log(Syslog::LOG_INFO, "#{sync_state.uploaded}")
        Syslog.close
        puts sync_state.uploaded
    end
end
