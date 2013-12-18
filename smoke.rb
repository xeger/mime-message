#!/usr/bin/env ruby

$: << 'lib'

require 'pp'

require 'rubygems'
require 'ruby-debug'

require 'mime/message'

text = File.read('/tmp/mime1.txt')
msg  = MIME::Message.parse(text)

puts msg
