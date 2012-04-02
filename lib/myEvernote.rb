require 'rubygems'
require 'pit'
require 'kconv'
require 'pp'

dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.push("#{dir}/ruby")
$LOAD_PATH.push("#{dir}/ruby/Evernote/EDAM")

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

class MyEvernote
  # 初期化。UserStoreを作成し、認証。
  # 認証が通ったらNoteStoreを作成する。
  def initialize()
    @core = Pit.get("evernote", :require => {
      "userName" => "your evernote userName.", 
      "password" => "your evernote password.", 
      "consumerKey" => "your evernote consumerKey.", 
      "consumerSecret" => "your evernote consumerSecret.", 
    })

    host = "sandbox.evernote.com"
    userStoreUrl = "https://#{host}/edam/user"
    userStoreTransport = Thrift::HTTPClientTransport.new(userStoreUrl)
    userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
    userStore = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)
    # 認証
    @authentication = auth(userStore)
    @token = @authentication.authenticationToken

    noteStoreUrlBase = "https://#{host}/edam/note/"
    noteStoreUrl = noteStoreUrlBase + @authentication.user.shardId
    noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    @noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
    # 全ノートブックを取得し、"GUID" => "ノートブック名"のハッシュを作る
    @notebooks = Hash::new
    getNotebooks.each do |note|
      @notebooks[note.guid] = note.name
    end
  end
  attr_reader :authentication
  attr_reader :notebooks
  
  # ユーザ認証を行う。
  # 認証に成功した場合AuthenticationResultを返す。
  # 認証に失敗した場合終了する。
  def auth(userStore)
    # バージョンチェック
    versionOK = userStore.checkVersion("MyEvernote",
      Evernote::EDAM::UserStore::EDAM_VERSION_MAJOR,
      Evernote::EDAM::UserStore::EDAM_VERSION_MINOR)
#    puts "Is my EDAM protocol version up to date? #{versionOK}"
    if (!versionOK) then
      exit(1)
    end
    begin
      auth = userStore.authenticate(
        @core["userName"],
        @core["password"],
        @core["consumerKey"],
        @core["consumerSecret"])
#      puts "Auth Success: #{auth.user.username}"
      return auth
    rescue Evernote::EDAM::Error::EDAMUserException => ex
      parameter = ex.parameter
      errorCode = ex.errorCode
      errorText = Evernote::EDAM::Error::EDAMErrorCode::VALUE_MAP[errorCode]
      puts "Auth Error: #{errorText}(ErrorCode: #{errorCode}), Parameter: #{parameter}"
      exit
    end
  end
  
  # 全ノートブックを取得する
  def getNotebooks()
    @noteStore.listNotebooks(@token)
  end
  
  # ノートブックの検索を行う
  def getNotebook(key)
    if isGuid(key) then
      # GUIDから検索
      return @noteStore.getNotebook(@token, key)
    else
      # ワードから検索？
      #filter = Evernote::EDAM::NoteStore::NoteFilter.new
      #filter.notebookGuid = '2d8ec8b5-5706-434d-a1dc-4ea0c6ba1993'
      #@noteStore.findNotes(@token, filter, 0, 5)
    end
  end
  
  # ノートの検索を行う
  def getNote(notebookGuid, count=100)
    filter = Evernote::EDAM::NoteStore::NoteFilter.new
    filter.notebookGuid = notebookGuid
    @noteStore.findNotes(@token, filter, 0, count)
  end

  # ノートのアップを行う
  def upload()
    # ノートブックの選択
    notebook = @noteStore.getDefaultNotebook(@token)

    note = Evernote::EDAM::Type::Note.new()
    note.title = "testtit" + (Time.now.to_i * 1000).to_s
    note.content = '<?xml version="1.0" encoding="UTF-8"?>' +
      '<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml.dtd">' +
      '<en-note>testcon</en-note>'
    note.created = Time.now.to_i * 1000
    note.updated = note.created

    result = @noteStore.createNote(@token, note)
    puts "Notebook:#{notebook}\nTitle   :#{note.title}\nCreated :#{note.created}"
    return result
  end

  # ノートの削除(ゴミ箱)を行う
  def delete(guid)
    # 存在確認してから
    @noteStore.deleteNote(@token, guid)
  end

  # ノートの完全削除を行う
  def purge()
    @noteStore.expungeInactiveNotes(@token)
  end

  # GUIDかどうかの判定を行う
  def isGuid(guid)
    if guid =~ /#{Evernote::EDAM::Limits::EDAM_GUID_REGEX}/ then
      return true
    else
      return false
    end
  end
end

if __FILE__ == $0 then 
  if ARGV.length == 0 then
    puts "Usage: #{$0} NOTE_TITLE CONTENT_TEXT"
    puts "       #{$0} sync"
    exit
  end

  e = MyEvernote.new()
  if ARGV[0] == "sync" then
    e.sync
  else
    e.upload(ARGV[0], ARGV[1])
  end
end
