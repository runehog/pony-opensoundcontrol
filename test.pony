use "collections"
use "ponytest"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestParseEmptyMessage)
    test(_TestParseMessageWithEveryKindOfArgument)
    test(_TestParseMessageWithTruncatedIntArgument)
    test(_TestParseMessageWithTruncatedFloatArgument)
    test(_TestParseMessageWithTruncatedStringArgument)
    test(_TestParseMessageWithTruncatedBlobArgumentSize)
    test(_TestParseMessageWithTruncatedBlobArgumentPayload)

class iso _TestParseEmptyMessage is UnitTest
  fun name(): String => "parse OSC message with no payload"

  fun apply(h: TestHelper) =>
    let to_parse: Array[U8] val = recover
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

class iso _TestParseMessageWithEveryKindOfArgument is UnitTest
  fun name(): String => "parse OSC message with every kind of argument"

  fun apply(h: TestHelper) ? =>
    let to_parse: Array[U8] val = recover
      Array[U8]()
        .push('/')    // addr
        .push('a')
        .push('/')
        .push('b')
        .push('/')
        .push('p')
        .push('o')
        .push('n')
        .push('i')
        .push('e')
        .push('s')
        .push('1')
        .push(0)
        .push(0)      // addr padding
        .push(0)
        .push(0)
        .push(',')
        .push('s')
        .push('i')
        .push('b')
        .push('f')
        .push(0)
        .push(0)      // arg-list padding
        .push(0)
        .push('a')    // str data
        .push(0)
        .push(0)
        .push(0)
        .push(0x10)   // i32 data
        .push(0x20)
        .push(0x30)
        .push(0x40)
        .push(0x00)   // blob size
        .push(0x00)
        .push(0x00)
        .push(0x07)
        .push(6)      // blob data
        .push(5)
        .push(4)
        .push(3)
        .push(2)
        .push(1)
        .push(0)
        .push(0)      // blob padding
        .push(0x3f)   // f32 data: 1.0
        .push(0x80)
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
      h.assert_eq[USize](message.args.size(), 4)
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
      h.log("bits for expected value: " + F32(1.0).bits().string())
      match message.args(3)
      | let f32_val: F32 =>
        h.assert_eq[F32](f32_val, F32(1.0))
      else
        h.fail("Expected args(3) to be an F32")
      end
    | let err: OSCParseError =>
      h.fail("parse error: " + err.description)
    end

class iso _TestParseMessageWithTruncatedIntArgument is UnitTest
  fun name(): String => "parse OSC message with truncated I32 argument"

  fun apply(h: TestHelper) =>
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