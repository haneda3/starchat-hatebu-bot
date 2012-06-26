# encoding: utf-8
require 'rubygems'
require 'daemons'

Daemons.run(File.dirname(__FILE__) + '/hatebubot.rb')

