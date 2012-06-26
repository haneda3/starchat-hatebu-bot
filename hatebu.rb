# encoding: utf-8
require 'rubygems'
require 'oauth'
require 'rexml/document'
require 'yaml'

def post_hatebu(oauth_def, url)
  consumer = OAuth::Consumer.new(oauth_def['consumer_key'], oauth_def['consumer_secret'], {:site => 'http://b.hatena.ne.jp'})
  token = OAuth::AccessToken.new(consumer, oauth_def['access_token'], oauth_def['access_token_secret'])
  res = token.get('/atom')
  if Net::HTTPSuccess === res then
  else
    return false
  end

  doc = REXML::Document.new res.body
  post_url = REXML::XPath.first(doc, "//link[@rel='service.post']/@href").to_s

  doc = REXML::Document.new
  entry = doc.add_element("entry", {"xmlns" => "http://purl.org/atom/ns#"})
  #entry.add_element("title").add_text("dummy")
  entry.add_element("link", {"rel" => "related", "type" => "text/html", "href" => url})
  #entry.add_element("summary", {"type" => "text/plain"}).add_text("dummy")

  res = token.post(post_url, doc, {'Content-Type'=>'application/xml'})
  if Net::HTTPCreated === res then
  else
    return false
  end
  
  link_url = REXML::XPath.first(REXML::Document.new(res.body), "//link[@rel='alternate']/@href").to_s
  return true, link_url
end

setting = YAML.load_file(File.dirname(__FILE__) + '/config.yaml')
post_hatebu(setting["oauth"], "http://www.google.com/")
