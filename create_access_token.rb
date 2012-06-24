# encoding: utf-8
require 'rubygems'
require 'oauth'
require 'rexml/document'
require "uri"

print "input OAuth Consumer Key:"
consumer_key = STDIN.gets.chomp
print "input OAuth Consumer Secret"
consumer_secret = STDIN.gets.chomp

site = {
    :site => 'https://www.hatena.com',
    :request_token_path => '/oauth/initiate',
    :authorize_path     => '/oauth/authorize',
    :access_token_path  => '/oauth/token'
}
consumer = OAuth::Consumer.new(consumer_key, consumer_secret, site)

request_token = consumer.get_request_token({:oauth_callback => 'oob'}, {:scope => 'read_public,write_public'})
puts "token: " + request_token.token
puts "secret: " + request_token.secret
puts "authroze_url: " + request_token.authorize_url

puts "!! open web browser !!"

print "input verifier:"
verifier = STDIN.gets.chomp
token = request_token.token
secret = request_token.secret

puts "token: " + token
puts "secret: " + secret
puts "verifier: " + verifier

request_token = OAuth::RequestToken.new(consumer, token, secret)
access_token  = request_token.get_access_token(:oauth_verifier => verifier)

puts "!! == copy to yaml file == !!"
puts "oauth:"
puts "  consumer_key: #{consumer_key}"
puts "  consumer_secret: #{consumer_secret}"
puts "  access_token: #{access_token.token}"
puts "  access_token_secret: #{access_token.secret}"
