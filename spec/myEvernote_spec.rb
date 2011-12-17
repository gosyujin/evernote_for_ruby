require 'rubygems'
require 'rspec'
require 'MyEvernote'
require 'kconv'
require 'pp'

describe MyEvernote do
# プラットフォームがWindowsの場合標準出力をKconv.tosjisでラップ
if RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|cygwin|bccwin/ then
  def $stdout.write(str)
    super Kconv.tosjis(str)
  end
end

  before do
    @e = MyEvernote.new()
    @SandboxGuid = '33880e53-4c9f-4104-a6e6-777ed1e3cef2'
    @SandboxName = 'Sandbox'
  end
  describe 'ノートブックを取得するとき' do
    it '正常にログインできる' do
      @e.authentication.user.username.should be == "kk_ataka_t"
    end
    it '正常にGUIDとノートブック名が対応づけられている' do
      @e.notebooks[@SandboxGuid].should be == @SandboxName
      @e.notebooks.index(@SandboxName).should be == @SandboxGuid
    end
    it '全ノートブックを取得できる' do
      @e.getNotebooks().length.should be 2
    end
    it '特定のノートブックを取得できる(GUID)' do
      @e.getNotebook(@SandboxGuid).name.should be == @SandboxName
    end
    it 'ノートブック内のノートを取得できる' do
      pp @e.getNote(@SandboxGuid)
    end
  end
  describe 'GUIDの妥当性を確認するとき' do
    it 'GUIDは妥当性である' do
      @e.isGuid(@SandboxGuid).should be true
    end
    it '妥当なGUIDではない(妥当ではない文字)' do
      @e.isGuid('XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX').should be false
    end
    it '妥当なGUIDではない(桁が違う)' do
      @e.isGuid('33880e53-4c9f-4104-a6e6-777ed1e3cef211111').should be false
    end
  end
end
