#!/usr/bin/env ruby

$: << 'lib'

require 'pp'

require 'rubygems'
require 'ruby-debug'

require 'mime/message'

text = File.read('/tmp/mime1.txt')
msg  = MIME::Message.parse(text)

text2 = [
  "Content-Type: multipart/mixed; boundary=hello bob",
  "",
  "--hello bob",
  "Content-Type: application/smarm",
  "",
  "May the odds be ever in your favor!",
  "--hello bob",
  "",
  "This is a very fine string, one of the best!",
  "I know of none finer.",
  "--hello bob--"
]
msg2 = MIME::Message.parse(text2)

puts msg
puts '--------------'
puts msg2
