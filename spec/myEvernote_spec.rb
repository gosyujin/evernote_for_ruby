# -*- encoding: utf-8 -*-
require "rubygems"
require "rspec"
require "./lib/myEvernote"
require "pp"

describe MyEvernote do
  before :all do
    @e = MyEvernote.new()
    @UpDelNotebookGuid = "71cdd6f9-5070-4508-bc80-a3f835a61a55"
    @UpDelNotebookName = "UpDeleteNotebook"
    @NotebookGuid = "450b52e6-2daa-4b04-9012-4623a8e12ef5"
    @NotebookName = "TestNotebook"
    @SandboxGuid = "33880e53-4c9f-4104-a6e6-777ed1e3cef2"
    @SandboxName = "Sandbox"
  end
  describe "ノートブックを取得するとき" do
    it "正常にログインできる" do
      @e.authentication.user.username.should be == "kk_ataka_t"
    end
    it "正常にGUIDとノートブック名が対応づけられている" do
      @e.notebooks[@NotebookGuid].should be == @NotebookName
      @e.notebooks.index(@NotebookName).should be == @NotebookGuid
    end
    it "全ノートブックを取得できる" do
      @e.getNotebooks().length.should be 4
    end
    it "特定のノートブックを取得できる(GUID)" do
      @e.getNotebook(@NotebookGuid).name.should be == @NotebookName
    end
    it "ノートブック内のノートを取得できる" do
      @e.getNote("", @NotebookGuid, 1).notes[0].title.should be == "TestNote"
      @e.getNote("violated", nil, 1).notes[0].title.should be == "rspec_sample_note"
      @e.getNote("violated", @NotebookGuid, 1).notes[0].title.should be == "rspec_sample_note"
    end
  end
  describe "ノートを操作するとき" do
    it "デフォルトノートブックにノートをアップできる" do
      now = (Time.now.to_i * 1000).to_s
      @e.upload("title"+now, "content"+now, nil)
      note = @e.getNote("content"+now, @SandboxGuid, 1)
      note.notes[0].title.should be == "title"+now
    end
    it "デフォルトノートブックに添付ファイル付きノートをアップできる" do
      now = (Time.now.to_i * 1000).to_s
      @e.upload("title"+now, "content"+now, "./lib/enlogo.png")
      note = @e.getNote("content"+now, @SandboxGuid, 1)
      note.notes[0].title.should be == "title"+now

      now = (Time.now.to_i * 1000).to_s
      @e.upload("title"+now, "content"+now, "./lib/enlogo.zip")
      note = @e.getNote("content"+now, @SandboxGuid, 1)
      note.notes[0].title.should be == "title"+now
    end
    it "デフォルトノートブックに存在しない添付ファイルを指定するとエラーになる" do
      now = (Time.now.to_i * 1000).to_s
      @e.upload("title"+now, "content"+now, "./lib/shouldnotfound.zip")
      pending("合格条件は検索しても見つからない事？")
    end
    it "ノートを論理削除できる" do
      pending("コンフリクトする。Error: DATA_CONFLICT(ErrorCode: 10), Parameter: Note.guid")
      now = (Time.now.to_i * 1000).to_s
      note = @e.getNote("content"+now, @SandboxGuid, 1)
      @e.delete(note.notes[0].guid)
      note_after = @e.getNote("content"+now, @SandboxGuid, 1)
      note.notes.length.should_not be == note_after.notes.length
    end
  end
  describe "GUIDの妥当性を確認するとき" do
    it "GUIDは妥当性である" do
      @e.isGuid(@NotebookGuid).should be true
    end
    it "妥当なGUIDではない(妥当ではない文字)" do
      @e.isGuid("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX").should be false
    end
    it "妥当なGUIDではない(桁が違う)" do
      @e.isGuid("33880e53-4c9f-4104-a6e6-777ed1e3cef211111").should be false
    end
  end
  context "Evernoteの使用量を確認するとき" do
    it "0 byte以上の使用量を取得できる" do
      @e.get_upload().should_not be == 0
    end
  end
end
