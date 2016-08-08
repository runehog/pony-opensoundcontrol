use "collections"
use "debug"
use "ponytest"

primitive Helper
  fun assert_sequence_matches(
    h: TestHelper, seq: Array[ByteSeq] val, to_match: Array[U8] val) ? =>
    var match_offset: USize = 0
    for array in seq.values() do
      // for char in array.values() do
      //   h.assert_true(to_match(match_offset) == char,
      //                 "at offset " + match_offset.string() + " expect " +
      //                 to_match(match_offset).string() + " got " +
      //                 char.string())
      //   match_offset = match_offset + 1
      // end
      match array
      | let string_val: String =>
        for char in string_val.values() do
          h.assert_true(to_match(match_offset) == char,
                        "at offset " + match_offset.string() + " expect " +
                        to_match(match_offset).string() + " got " +
                        char.string())
          match_offset = match_offset + 1
        end
      | let blob_val: Array[U8] val =>
        for char in blob_val.values() do
          h.assert_true(to_match(match_offset) == char,
                        "at offset " + match_offset.string() + " expect " +
                        to_match(match_offset).string() + " got " +
                        char.string())
          match_offset = match_offset + 1
        end
      end
    end

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestParseEmptyMessage)
    test(_TestParseMessageWithZeroInFirstValue)
    test(_TestParseMessageWithStringAndInt)
    test(_TestParseMessageWithEveryKindOfArgument)
    test(_TestParseMessageWithTruncatedIntArgument)
    test(_TestParseMessageWithTruncatedFloatArgument)
    test(_TestParseMessageWithTruncatedStringArgument)
    test(_TestParseMessageWithTruncatedBlobArgumentSize)
    test(_TestParseMessageWithTruncatedBlobArgumentPayload)
    test(_TestGenerateEmptyMessage)
    test(_TestGenerateMessageWith3Ints)
    test(_TestGenerateMessageWithEveryKindOfArgument)

class iso _TestParseEmptyMessage is UnitTest
  fun name(): String => "parse OSC message with no payload"

  fun apply(h: TestHelper) =>
    Debug.out("_TestParseEmptyMessage")
    let to_parse: Array[U8] val = recover Array[U8]
      .push('/')
      .push('a')
      .push(0)
      .push(0)
      .push(',')
      .push(0)
      .push(0)
      .push(0)
    end
    let expected_addr: OSCAddress val = recover
      let expected_addr_elements: Array[String] = Array[String val]()
          .push("a")
      OSCAddress.from_array(expected_addr_elements)
    end
    let result: OSCParseResult = OSC.parse(to_parse)
    match result
    | let message: OSCMessage =>
      h.log("got message: " + message.string())
      h.assert_eq[OSCAddress](message.address, expected_addr)
    | let err: OSCParseError =>
      h.fail("parse error: " + err.description)
    end

class iso _TestParseMessageWithZeroInFirstValue is UnitTest
  fun name(): String => "parse OSC message with a zero-value argument"

  fun apply(h: TestHelper) ? =>
    Debug.out("_TestParseMessageWithZeroInFirstValue")
    let to_parse: Array[U8] val = recover Array[U8]
      .push('/')
      .push('a')
      .push(0)
      .push(0)
      .push(',')
      .push('i')
      .push('i')
      .push('i')
      .push(0)
      .push(0)
      .push(0)
      .push(0)
      .push(0)
      .push(0)
      .push(0)
      .push(0)
      .push(0)
      .push(0)
      .push(0)
      .push(1)
      .push(0)
      .push(0)
      .push(0)
      .push(2)
    end
    let expected_addr: OSCAddress val = recover
      let expected_addr_elements: Array[String] = Array[String val]()
          .push("a")
      OSCAddress.from_array(expected_addr_elements)
    end
    let result: OSCParseResult = OSC.parse(to_parse)
    match result
    | let message: OSCMessage =>
      h.log("got message: " + message.string())
      h.assert_eq[OSCAddress](message.address, expected_addr)
      // Arg 0: I32 == 0, 1 == 1, 2 == 2
      match message.args(0)
      | let i32_val: I32 =>
        h.assert_eq[I32](i32_val, I32(0))
      else
        h.fail("Expected arg 0 to be an I32")
      end
      match message.args(1)
      | let i32_val: I32 =>
        h.assert_eq[I32](i32_val, I32(1))
      else
        h.fail("Expected arg 1 to be an I32")
      end
      match message.args(2)
      | let i32_val: I32 =>
        h.assert_eq[I32](i32_val, I32(2))
      else
        h.fail("Expected arg 2 to be an I32")
      end

    | let err: OSCParseError =>
      h.fail("parse error: " + err.description)
    end

class iso _TestParseMessageWithStringAndInt is UnitTest
  fun name(): String => "parse OSC message with a string and an int"

  fun apply(h: TestHelper) ? =>
    Debug.out("_TestParseMessageWithStringAndInt")
    let to_parse: Array[U8] val = recover Array[U8]
      .push('/')
      .push('a')
      .push(0)
      .push(0)
      .push(',')
      .push('s')
      .push('i')
      .push(0)
      .push('a')
      .push('b')
      .push('c')
      .push('d')
      .push('e')
      .push('f')
      .push('g')
      .push('h')
      .push(0)
      .push(0)
      .push(0)
      .push(0)
      .push(0x01)
      .push(0x02)
      .push(0x03)
      .push(0x04)
    end
    let expected_addr: OSCAddress val = recover
      let expected_addr_elements: Array[String] = Array[String val]()
          .push("a")
      OSCAddress.from_array(expected_addr_elements)
    end
    let result: OSCParseResult = OSC.parse(to_parse)
    match result
    | let message: OSCMessage =>
      h.log("got message: " + message.string())
      h.assert_eq[OSCAddress](message.address, expected_addr)
      // Arg 0: string == "abcdefgh"
      match message.args(0)
      | let string_val: String =>
        h.assert_eq[String](string_val, "abcdefgh")
      else
        h.fail("Expected arg 0 to be a string")
      end
      match message.args(1)
      | let i32_val: I32 =>
        h.assert_eq[I32](i32_val, I32(0x01020304))
      else
        h.fail("Expected arg 1 to be an I32")
      end
    end

class iso _TestParseMessageWithEveryKindOfArgument is UnitTest
  fun name(): String => "parse OSC message with every kind of argument"

  fun apply(h: TestHelper) ? =>
    Debug.out("_TestParseMessageWithEveryKindOfArgument")
    let to_parse: Array[U8] val = recover
      Array[U8]()
        .push('/')    // addr                 0
        .push('a')
        .push('/')
        .push('b')
        .push('/')
        .push('p')
        .push('o')
        .push('n')
        .push('i')                          //8
        .push('e')
        .push('s')
        .push('1')
        .push(0)
        .push(0)      // addr padding
        .push(0)
        .push(0)
        .push(',')                          //16
        .push('s')
        .push('i')
        .push('b')
        .push('f')
        .push('t')
        .push(0)
        .push(0)      // arg-list padding
        .push('a')    // str data             24
        .push(0)
        .push(0)
        .push(0)
        .push(0x10)   // i32 data
        .push(0x20)
        .push(0x30)
        .push(0x40)
        .push(0x00)   // blob size            32
        .push(0x00)
        .push(0x00)
        .push(0x07)
        .push(6)      // blob data
        .push(5)
        .push(4)
        .push(3)
        .push(2)                            //40
        .push(1)
        .push(0)
        .push(0)      // blob padding
        .push(0x3f)   // f32 data: 1.0
        .push(0x80)
        .push(0x00)
        .push(0x00)
        .push(0x00)   // timetag data: 0.0    48
        .push(0x00)
        .push(0x00)
        .push(0x00)
        .push(0x00)
        .push(0x00)
        .push(0x00)
        .push(0x00)
      end
    let expected_addr: OSCAddress val = recover
      let expected_addr_elements: Array[String] = Array[String val]()
          .push("a")
          .push("b")
          .push("ponies1")
      OSCAddress.from_array(expected_addr_elements)
    end
    let result: OSCParseResult = OSC.parse(to_parse)
    match result
    | let message: OSCMessage =>
      h.log("got message: " + message.string())
      h.assert_eq[OSCAddress](message.address, expected_addr)
      h.assert_eq[USize](message.args.size(), 5)
      // Arg 0: string
      match message.args(0)
      | let string_val: String val =>
        h.assert_eq[String](string_val, "a")
      else
        h.fail("Expected args(0) to be a String")
      end
      // Arg 1: I32
      match message.args(1)
      | let i32_val: I32 =>
        h.assert_eq[I32](i32_val, I32(0x10203040))
      else
        h.fail("Expected args(1) to be an I32")
      end
      // Arg 2: blob
      match message.args(2)
      | let array_val: Array[U8] val =>
        h.assert_eq[USize](array_val.size(), 7)
        h.assert_eq[U8](array_val(0), 6)
        h.assert_eq[U8](array_val(1), 5)
        h.assert_eq[U8](array_val(2), 4)
        h.assert_eq[U8](array_val(3), 3)
        h.assert_eq[U8](array_val(4), 2)
        h.assert_eq[U8](array_val(5), 1)
        h.assert_eq[U8](array_val(6), 0)
      else
        h.fail("Expected args(2) to be an Array[U8]")
      end
      // Arg 3: F32
      match message.args(3)
      | let f32_val: F32 =>
        h.assert_eq[F32](f32_val, F32(1.0))
      else
        h.fail("Expected args(3) to be an F32")
      end
      // Arg 4: OSCTimeTag
      match message.args(4)
      | let timetag_val: OSCTimeTag val =>
        h.assert_eq[U32](timetag_val.seconds, U32(0))
        h.assert_eq[U32](timetag_val.fraction, U32(0))
      else
        h.fail("Expected args(4) to be a timetag")
      end
    | let err: OSCParseError =>
      h.fail("parse error: " + err.description)
    end

class iso _TestParseMessageWithTruncatedIntArgument is UnitTest
  fun name(): String => "parse OSC message with truncated I32 argument"

  fun apply(h: TestHelper) =>
    Debug.out("_TestParseMessageWithTruncatedIntArgument")
    let to_parse: Array[U8] val = recover
      Array[U8]()
        .push('/')
        .push('a')
        .push(0)
        .push(0)
        .push(',')
        .push('i')
        .push(0)
        .push(0)
        // int should be here
      end
    let result: OSCParseResult = OSC.parse(to_parse)
    match result
    | let message: OSCMessage =>
      h.fail("expected parse error! got OSCMessage: " + message.string())
    | let err: OSCParseError =>
      h.log("got OSCParseError :)")
    end

class iso _TestParseMessageWithTruncatedFloatArgument is UnitTest
  fun name(): String => "parse OSC message with truncated F32 argument"

  fun apply(h: TestHelper) =>
    Debug.out("_TestParseMessageWithTruncatedFloatArgument")
    let to_parse: Array[U8] val = recover
      Array[U8]()
        .push('/')
        .push('a')
        .push(0)
        .push(0)
        .push(',')
        .push('f')
        .push(0)
        .push(0)
        // float should be here
      end
    let result: OSCParseResult = OSC.parse(to_parse)
    match result
    | let message: OSCMessage =>
      h.fail("expected parse error! got OSCMessage: " + message.string())
    | let err: OSCParseError =>
      h.log("got OSCParseError :)")
    end

class iso _TestParseMessageWithTruncatedStringArgument is UnitTest
  fun name(): String => "parse OSC message with truncated String argument"

  fun apply(h: TestHelper) =>
    Debug.out("_TestParseMessageWithTruncatedStringArgument")
    let to_parse: Array[U8] val = recover
      Array[U8]()
        .push('/')
        .push('a')
        .push(0)
        .push(0)
        .push(',')
        .push('s')
        .push(0)
        .push(0)
        // string should be here
      end
    let result: OSCParseResult = OSC.parse(to_parse)
    match result
    | let message: OSCMessage =>
      h.fail("expected parse error! got OSCMessage: " + message.string())
    | let err: OSCParseError =>
      h.log("got OSCParseError :)")
    end

class iso _TestParseMessageWithTruncatedBlobArgumentSize is UnitTest
  fun name(): String => "parse OSC message with truncated Array[U8] size"

  fun apply(h: TestHelper) =>
    Debug.out("_TestParseMessageWithTruncatedBlobArgumentSize")
    let to_parse: Array[U8] val = recover
      Array[U8]()
        .push('/')
        .push('a')
        .push(0)
        .push(0)
        .push(',')
        .push('b')
        .push(0)
        .push(0)
        // blob size should be here
      end
    let result: OSCParseResult = OSC.parse(to_parse)
    match result
    | let message: OSCMessage =>
      h.fail("expected parse error! got OSCMessage: " + message.string())
    | let err: OSCParseError =>
      h.log("got OSCParseError :)")
    end

class iso _TestParseMessageWithTruncatedBlobArgumentPayload is UnitTest
  fun name(): String => "parse OSC message with truncated Array[U8] payload"

  fun apply(h: TestHelper) =>
    Debug.out("_TestParseMessageWithTruncatedBlobArgumentPayload")
    let to_parse: Array[U8] val = recover
      Array[U8]()
        .push('/')
        .push('a')
        .push(0)
        .push(0)
        .push(',')
        .push('b')
        .push(0)
        .push(0)
        .push(0x00)
        .push(0x00)
        .push(0x00)
        .push(0x03)
        // blob data should be here
        .push(0xaa)
      end
    let result: OSCParseResult = OSC.parse(to_parse)
    match result
    | let message: OSCMessage =>
      h.fail("expected parse error! got OSCMessage: " + message.string())
    | let err: OSCParseError =>
      h.log("got OSCParseError :)")
    end

class iso _TestGenerateEmptyMessage is UnitTest
  fun name(): String => "generate empty OSC message and verify"

  fun apply(h: TestHelper) ? =>
    Debug.out("_TestGenerateEmptyMessage")
    let to_match: Array[U8] val = recover
      Array[U8]()
        .push('/')
        .push('a')
        .push(0)
        .push(0)
        .push(',')
        .push(0)
        .push(0)
        .push(0)
      end
    let address: OSCAddress val = recover OSCAddress("a") end
    let args: Array[OSCData] val = recover Array[OSCData] end
    let message: OSCMessage val = recover OSCMessage(address, args) end
    let result: Array[ByteSeq] val = recover message.binary() end

    Helper.assert_sequence_matches(h, result, to_match)

class iso _TestGenerateMessageWith3Ints is UnitTest
  fun name(): String => "generate OSC message with 3 int args and verify"

  fun apply(h: TestHelper) ? =>
    Debug.out("_TestGenerateMessageWith3Ints")
    let to_match: Array[U8] val = recover Array[U8]
      .push('/')
      .push('a')
      .push(0)
      .push(0)
      .push(',')
      .push('i')
      .push('i')
      .push('i')
      .push(0)
      .push(0)
      .push(0)
      .push(0)
      .push(0x01)
      .push(0x02)
      .push(0x03)
      .push(0x04)
      .push(0x11)
      .push(0x12)
      .push(0x13)
      .push(0x14)
      .push(0x21)
      .push(0x22)
      .push(0x23)
      .push(0x24)
    end
    let address: OSCAddress val = recover OSCAddress("a") end
    let args: Array[OSCData] val = recover
      let a: Array[OSCData] iso = recover iso Array[OSCData] end
      a.push(I32(0x01020304))
      a.push(I32(0x11121314))
      a.push(I32(0x21222324))
      consume a
    end
    let message: OSCMessage val = recover OSCMessage(address, args) end
    try
      let result: Array[ByteSeq] val = recover message.binary() end

      try
        Helper.assert_sequence_matches(h, result, to_match)
      else
        h.log("assert_sequence_matches blew up")
        error
      end
    else
      h.log("binary blew up")
      error
    end

class iso _TestGenerateMessageWithEveryKindOfArgument is UnitTest
  fun name(): String => "generate OSC message with many args and verify"

  fun apply(h: TestHelper) ? =>
    Debug.out("_TestGenerateEmptyMessage")
    let to_match: Array[U8] val = recover Array[U8]
      .push('/')    // addr                 0
      .push('a')
      .push('/')
      .push('b')
      .push('/')
      .push('p')
      .push('o')
      .push('n')
      .push('i')                          //8
      .push('e')
      .push('s')
      .push('1')
      .push(0)
      .push(0)      // addr padding
      .push(0)
      .push(0)
      .push(',')                          //16
      .push('s')
      .push('i')
      .push('b')
      .push('f')
      .push('t')
      .push(0)
      .push(0)      // arg-list padding
      .push('a')    // str data             24
      .push(0)
      .push(0)
      .push(0)
      .push(0x10)   // i32 data
      .push(0x20)
      .push(0x30)
      .push(0x40)
      .push(0x00)   // blob size            32
      .push(0x00)
      .push(0x00)
      .push(0x07)
      .push(6)      // blob data
      .push(5)
      .push(4)
      .push(3)
      .push(2)                            //40
      .push(1)
      .push(0)
      .push(0)      // blob padding
      .push(0x3f)   // f32 data: 1.0
      .push(0x80)
      .push(0x00)
      .push(0x00)
      .push(0x00)   // timetag data: 0.0    48
      .push(0x00)
      .push(0x00)
      .push(0x00)
      .push(0x00)
      .push(0x00)
      .push(0x00)
      .push(0x00)
    end
    let address: OSCAddress val = recover OSCAddress("a/b/ponies1") end
    let args: Array[OSCData] val = recover
      let a: Array[OSCData] iso = recover iso Array[OSCData] end
      a.push(recover val "a" end)
      a.push(I32(0x10203040))
      a.push(recover val [6, 5, 4, 3, 2, 1, 0] end)
      a.push(F32(1.0))
      a.push(recover val OSCTimeTag(0, 0) end)
      consume a
    end
    let message: OSCMessage val = recover OSCMessage(address, args) end

    try
      let result: Array[ByteSeq] val = recover message.binary() end

      try
        Helper.assert_sequence_matches(h, result, to_match)
      else
        h.log("assert_sequence_matches blew up")
        error
      end
    else
      h.log("binary blew up")
      error
    end
