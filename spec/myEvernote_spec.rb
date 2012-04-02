# -*- encoding: utf-8 -*-
require 'rubygems'
require 'rspec'
require './lib/myEvernote'
require 'pp'

describe MyEvernote do
  before do
    @e = MyEvernote.new()
    @UpDelNotebookGuid = '71cdd6f9-5070-4508-bc80-a3f835a61a55'
    @UpDelNotebookName = 'UpDeleteNotebook'
    @NotebookGuid = '450b52e6-2daa-4b04-9012-4623a8e12ef5'
    @NotebookName = 'TestNotebook'
  end
  describe 'ノートブックを取得するとき' do
    it '正常にログインできる' do
puts @e.authentication
      @e.authentication.user.username.should be == "kk_ataka_t"
    end
    it '正常にGUIDとノートブック名が対応づけられている' do
      @e.notebooks[@NotebookGuid].should be == @NotebookName
      @e.notebooks.index(@NotebookName).should be == @NotebookGuid
    end
    it '全ノートブックを取得できる' do
      @e.getNotebooks().length.should be 4
    end
    it '特定のノートブックを取得できる(GUID)' do
      @e.getNotebook(@NotebookGuid).name.should be == @NotebookName
    end
    it 'ノートブック内のノートを取得できる' do
      @e.getNote(@NotebookGuid)
    end
  end
  describe 'GUIDの妥当性を確認するとき' do
    it 'GUIDは妥当性である' do
      @e.isGuid(@NotebookGuid).should be true
    end
    it '妥当なGUIDではない(妥当ではない文字)' do
      @e.isGuid('XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX').should be false
    end
    it '妥当なGUIDではない(桁が違う)' do
      @e.isGuid('33880e53-4c9f-4104-a6e6-777ed1e3cef211111').should be false
    end
  end
end
