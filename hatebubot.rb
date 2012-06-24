# encoding: utf-8
require '../starchat-api-client/starchatapiclient'
require './hatebu'
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

ERROR_IPADDR_MSG = "IPアドレスははてブしない"
ERROR_NGWORD_MSG = "NGワードだったのではてブしない"
ERROR_SITE_MSG = "サイトが見つからないのではてブしない"
TITLE_MSG = "【タイトル】"
SUCCESS_MSG = "【はてブした】"

setting = YAML.load_file('./config.yaml')

s = StarChatApiClient.new(setting['host'], setting['username'], setting['password'])

s.get_stream do |body|
  next if body['type'] != 'message'

  message = body['message']

  # notice確認
  next if message['notice'] != false

  if message['body'] =~ /((http|https):\/\/\S+)\s*/ then
    url = URI.encode($1)
    host = URI.parse(url).host
    
    begin
      # IPアドレスだったら抜ける
      IPAddr.new(host)
      s.post_comment(message['channel_name'], ERROR_IPADDR_MSG)
      next
    rescue ArgumentError
    end
    
    # NGワードだったら抜ける
    if exist_ngword?(setting['ngword'], message['body']) then
      s.post_comment(message['channel_name'], ERROR_NGWORD_MSG)
      next
    end
  
    # 取得できないサイトだったら抜ける
    begin
      p url
      agent = Mechanize.new
      agent.get(url)
      p agent.page.title
      s.post_comment(message['channel_name'], TITLE_MSG + " " + agent.page.title)
    rescue
      s.post_comment(message['channel_name'], ERROR_SITE_MSG)
      next
    end
    
    # はてブする
    success, link = post_hatebu(setting["oauth"], url)
    if success then
      s.post_comment(message['channel_name'], SUCCESS_MSG + " " + link)
    end
  end
end
