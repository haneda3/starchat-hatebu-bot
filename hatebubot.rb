# encoding: utf-8
require File.dirname(__FILE__) + '/../starchat-api-client/starchatapiclient'
require File.dirname(__FILE__) + '/hatebu'
require 'yaml'
require 'mechanize'
require 'uri'
require 'ipaddr'

def exist_ngword?(ngwords, text)
  ngwords.each do |wd|
    if text.index(wd) != nil then
      return true
    end
  end
  return false
end

ERROR_HATEBUNG_MSG = "はてブ禁止でした"
ERROR_IPADDR_MSG = "IPアドレスははてブしない"
ERROR_NGWORD_MSG = "NGワードだったのではてブしない"
ERROR_SITE_MSG = "サイトが見つからないのではてブしない"
TITLE_MSG = "【タイトル】"
SUCCESS_MSG = "【はてブした】"

setting = YAML.load_file(File.dirname(__FILE__) + '/config.yaml')

s = StarChatApiClient.new(setting['host'], setting['username'], setting['password'])

loop do
  begin
    s.get_stream do |body|
      next if body['type'] != 'message'

      message = body['message']
      mes = message['body'].tr('　', ' ') # 全角スペース撲滅

      # notice確認
#      next if message['notice'] != false

      # はてブ禁止だったら抜ける
      if mes =~ /.*!.*/ then
        p ERROR_HATEBUNG_MSG
        next
      end
      
      # NGワードだったら抜ける
      if exist_ngword?(setting['ngword'], message['body']) then
        p ERROR_NGWORD_MSG
          #s.post_comment(message['channel_name'], ERROR_NGWORD_MSG)
        next
      end

      if mes =~ /((http|https):\/\/\S+)\s*/ then
        url = URI.encode($1)
        host = URI.parse(url).host

        begin
          # IPアドレスだったら抜ける
          IPAddr.new(host)
          p ERROR_IPADDR_MSG
          #s.post_comment(message['channel_name'], ERROR_IPADDR_MSG)
          next
        rescue ArgumentError
        end

        # 取得できないサイトだったら抜ける
        begin
          p url
          agent = Mechanize.new
          agent.get(url)
          p agent.page.title
          s.post_comment(message['channel_name'], TITLE_MSG + " " + agent.page.title)
        rescue
          p ERROR_SITE_MSG
          #s.post_comment(message['channel_name'], ERROR_SITE_MSG)
          next
        end
        
        # はてブする
        success, link = post_hatebu(setting["oauth"], url)
        if success then
          s.post_comment(message['channel_name'], SUCCESS_MSG + " " + link)
        end
      end
    end
  rescue
  end
  sleep(3)
end
