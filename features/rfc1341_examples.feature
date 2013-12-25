Feature: RFC1341 examples
  In order to ensure interoperability
  We can parse all of the examples given in RFC1341
  So we know we implemented according to the spec

  Scenario: common syntax (section 7.2)
    Given a MIME text:
    """
    From: Nathaniel Borenstein <nsb@bellcore.com>
    To:  Ned Freed <ned@innosoft.com>
    Subject: Sample message
    MIME-Version: 1.0
    Content-type: multipart/mixed; boundary="simple
     boundary"

    This is the preamble.  It is to be ignored, though it
    is a handy place for mail composers to include an
    explanatory note to non-MIME compliant readers.
    --simple boundary

    This is implicitly typed plain ASCII text.
    It does NOT end with a linebreak.
    --simple boundary
    Content-type: text/plain; charset=us-ascii

    This is explicitly typed plain ASCII text.
    It DOES end with a linebreak.

    --simple boundary--
    This is the epilogue.  It is also to be ignored.
    """
    When I parse the text
    Then parsing succeeds
    And the message's preamble includes a line like "This is the preamble."
    And the message has 2 parts
    And the 1st part doesn't end with a linebreak
    And the 2nd part ends with a linebreak
    And the message's epilogue includes a line like "This is the epilogue."

  Scenario: complex example (appendix C)
    Given a MIME text:
    """
    MIME-Version: 1.0
    From: Nathaniel Borenstein <nsb@bellcore.com>
    Subject: A multipart example
    Content-Type: multipart/mixed;
        boundary=unique-boundary-1

    This is the preamble area of a multipart message.
    Mail readers that understand multipart format
    should ignore this preamble.
    If you are reading this text, you might want to
    consider changing to a mail reader that understands
    how to properly display multipart messages.
    --unique-boundary-1

    ...Some text appears here...
    [Note that the preceding blank line means
    no header fields were given and this is text,
    with charset US ASCII.  It could have been
    done with explicit typing as in the next part.]

    --unique-boundary-1
    Content-type: text/plain; charset=US-ASCII

    This could have been part of the previous part,
    but illustrates explicit versus implicit
    typing of body parts.

    --unique-boundary-1
    Content-Type: multipart/parallel;
        boundary=unique-boundary-2


    --unique-boundary-2
    Content-Type: audio/basic
    Content-Transfer-Encoding: base64

    ... base64-encoded 8000 Hz single-channel
       u-law-format audio data goes here....

    --unique-boundary-2
    Content-Type: image/gif
    Content-Transfer-Encoding: Base64
    """
    When Tony wants to debug
    When I parse the text
    Then parsing succeeds
    And the message's preamble includes a line like "ignore this preamble"
    And the message has 3 parts
    # @todo add some default header values, e.g. content type, in messages where none is provided
    #And the 1st part's Content-Type header is "text/plain"
    And the 1st part includes a line like "this is text"
    And the 2nd part's Content-Type header is "text/plain" with parameters "charset=US-ASCII"
    And the 2nd part includes a line like "This could have been"
    And the 3rd part's Content-Type header is "multipart/parallel" with parameters "boundary=unique-boundary-2"


