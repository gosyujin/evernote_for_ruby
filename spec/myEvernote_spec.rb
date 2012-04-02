# -*- encoding: utf-8 -*-
require "rubygems"
require "rspec"
require "./lib/myEvernote"
require "pp"

describe MyEvernote do
  before do
    @e = MyEvernote.new()
    @UpDelNotebook_guid = "71cdd6f9-5070-4508-bc80-a3f835a61a55"
    @UpDelNotebook_name = "UpDeleteNotebook"
    @Notebook_guid = "450b52e6-2daa-4b04-9012-4623a8e12ef5"
    @Notebook_name = "TestNotebook"
    @new_note_guid = ""
  end
  describe "ノートブックを取得するとき" do
    it "正常にログインできる" do
      @e.authentication.user.username.should be == "kk_ataka_t"
    end
    it "正常にGUIDとノートブック名が対応づけられている" do
      @e.notebooks[@Notebook_guid].should be == @Notebook_name
      @e.notebooks.index(@Notebook_name).should be == @Notebook_guid
    end
    it "全ノートブックを取得できる" do
      @e.getNotebooks().length.should be 4
    end
    it "特定のノートブックを取得できる(GUID)" do
      @e.getNotebook(@Notebook_guid).name.should be == @Notebook_name
    end
    it "ノートブック内のノートを取得できる" do
      @e.getNote(@Notebook_guid)
    end
  end
  describe "ノートを操作するとき" do
    it "デフォルトノートブックにノートをアップできる" do
      result = @e.upload()
      @new_note_guid = result["guid"]
    end
    it "ノートを論理削除できる" do
      @e.delete(@new_note_guid)
    end
  end
  describe "GUIDの妥当性を確認するとき" do
    it "GUIDは妥当性である" do
      @e.is_guid(@Notebook_guid).should be true
    end
    it "妥当なGUIDではない(妥当ではない文字)" do
      @e.is_guid("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX").should be false
    end
    it "妥当なGUIDではない(桁が違う)" do
      @e.is_guid("33880e53-4c9f-4104-a6e6-777ed1e3cef211111").should be false
    end
  end
end
