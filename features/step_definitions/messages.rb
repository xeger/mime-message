Given /^a MIME text:$/ do |text|
  @text = text
end

When /^I parse the text$/ do
  @message = nil
  begin
    @message   = MIME::Message.parse(@text)
    @exception = nil
  rescue Exception => e
    @exception = e
  end
end

Then /^parsing (succeeds|fails)$/ do |outcome|
  case outcome
  when 'succeeds'
    expect {
      raise @exception if @exception
    }.not_to raise_exception
    @message.should_not be_nil
  when 'fails'
    expect {
      raise @exception if @exception
    }.to raise_exception
    @message.should be_nil
  end
end

Then /^the message has ([0-9]+) parts$/ do |n|
  @message.body.should be_a(Array)
  @message.body.size.should == Integer(n)
end

Then /^the message's (\w+) is "(.*)"$/ do |attr, value|
  attr = attr.to_sym
  value = Number(value) if value =~ /[0-9.]+/

  @message.should respond_to(attr)
  @message.__send__(attr).should == value
end

Then /^the message's (\w+) includes a line like "(.*)"$/ do |attr, substring|
  attr = attr.to_sym

  @message.should respond_to(attr)
  value = @message.__send__(attr)
  value.should be_a(Array)
  value.detect { |x| x.include?(substring) }.should_not be_nil
end

Then /^the ([0-9]+)(st|nd|rd|th) part's ([A-Za-z0-9-]+) header is "([^"]*)"$/ do |ordinal, _, header, value|
  ordinal = Integer(ordinal) - 1

  @message.body.should be_a(Array)
  @message.body.size.should >= ordinal
  part = @message.body[ordinal]

  header = part.headers.detect { |h| h.name == header }
  header.should_not be_nil
  header.value.should == value
end

Then /^the ([0-9]+)(st|nd|rd|th) part's ([A-Za-z0-9-]+) header is "([^"]*)" with parameters "([^"]*)"$/ do |ordinal, _, name, value, params|
  ordinal = Integer(ordinal) - 1
  params = params.split(';').inject({}) { |h, e| k, v = e.split('=') ; h[k] = v ; h }

  @message.body.should be_a(Array)
  @message.body.size.should >= ordinal
  part = @message.body[ordinal]

  header = part.headers[name]
  header.should_not be_nil
  header.value_without_parameters.should == value

  params.each_pair do |k, v|
    header.parameters.should have_key(k)
    header.parameters[k].should == v
  end
end

Then /^the ([0-9]+)(st|nd|rd|th) part includes a line like "(.*)"$/ do |ordinal, _, substring|
  ordinal = Integer(ordinal) - 1

  @message.body.should be_a(Array)
  @message.body.size.should >= ordinal
  part = @message.body[ordinal]

  part.body.detect { |x| x.include?(substring) }.should_not be_nil
end

Then /^the ([0-9]+)(st|nd|rd|th) part (ends|doesn't end) with a linebreak$/ do |ordinal, _, expect_crlf|
  ordinal     = Integer(ordinal) - 1
  expect_crlf = (expect_crlf == "ends")

  @message.body.should be_a(Array)
  @message.body.size.should >= ordinal
  part = @message.body[ordinal]

  if expect_crlf
    part.body.last.should end_with("\r\n")
  else
    part.body.last.should_not end_with("\r\n")
  end
end
