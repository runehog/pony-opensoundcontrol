// OpenSoundControl 1.0 parsing and generation.

type OSCData is (I32 | F32 | OSCTimeTag val | String val | Array[U8] val)

class OSCParseError
  let description: String

  new iso create(description': String) =>
    description = description'

type OSCParseResult is (OSCMessage | OSCBundle | OSCParseError)

primitive OSC
  fun parse(packet: Array[U8] val): OSCParseResult =>
    try
      match packet(0)
      | '/' =>
        parse_message(packet)
      | '#' =>
        parse_bundle(packet)
      else
        OSCParseError("unexpected start byte")
      end
    else
      OSCParseError("malformed OSC packet")
    end

  // Implements OSC's round-to-32-bit-boundary pattern.
  fun pad_four(value: USize): USize =>
    (value + 3) and not 0x03

  fun parse_message(packet: Array[U8] val): OSCParseResult ? =>
    // Calculate address extent & parse address.
    let addr_size = packet.find(0)
    let addr_array: Array[U8] val = recover packet.slice(1, addr_size) end
    let addr_string: String val = recover String.from_array(addr_array) end
    let address: OSCAddress val = recover OSCAddress(addr_string) end

    // Calculate type-tag list extent and argument count.
    var type_tag_offset = packet.find(',', addr_size) + 1
    let type_tag_end = packet.find(0, type_tag_offset)
    let arg_count = type_tag_end - type_tag_offset
    if arg_count == 0 then
      recover val
        OSCMessage(address, recover val Array[OSCData]() end)
      end
    else
      // Find start of arg data (first non-NULL char after type_tag_end).
      try
        recover val
          var arg_offset = pad_four(type_tag_end + 1)

          let args_val: Array[OSCData] val = recover val
            let args: Array[OSCData] = Array[OSCData](arg_count)
            repeat
              let t: U8 = packet(type_tag_offset)
              type_tag_offset = type_tag_offset + 1
              match t
              | 'i' =>
                let int_val: I32 =
                  (packet(arg_offset  ).i32() << 24) or
                  (packet(arg_offset+1).i32() << 16) or
                  (packet(arg_offset+2).i32() <<  8) or
                  (packet(arg_offset+3).i32()      )
                arg_offset = arg_offset + 4
                args.push(recover val I32(int_val) end)
              | 'f' =>
                let int_val: U32 =
                  (packet(arg_offset  ).u32() << 24) or
                  (packet(arg_offset+1).u32() << 16) or
                  (packet(arg_offset+2).u32() <<  8) or
                  (packet(arg_offset+3).u32()      )
                arg_offset = arg_offset + 4
                args.push(recover val F32.from_bits(int_val) end)
              | 't' =>
                let timetag_val: OSCTimeTag val = recover val
                  OSCTimeTag(
                    (packet(arg_offset  ).u32() << 24) or
                    (packet(arg_offset+1).u32() << 16) or
                    (packet(arg_offset+2).u32() <<  8) or
                    (packet(arg_offset+3).u32()      ),
                    (packet(arg_offset+4).u32() << 24) or
                    (packet(arg_offset+5).u32() << 16) or
                    (packet(arg_offset+6).u32() <<  8) or
                    (packet(arg_offset+7).u32()      ))
                end
                arg_offset = arg_offset + 8
                args.push(timetag_val)
              | 's' =>
                // Calculate string arg extent and copy it.
                let arg_end = packet.find(0, arg_offset)
                let arg_array: Array[U8] val = recover
                  packet.slice(arg_offset, arg_end)
                end
                arg_offset = pad_four(arg_end)
                let string_arg: String val = recover String.from_array(arg_array) end
                args.push(string_arg)
              | 'b' =>
                // Calculate blob arg extent and copy it.
                let blobsize_val: USize =
                  (packet(arg_offset  ).usize() << 24) or
                  (packet(arg_offset+1).usize() << 16) or
                  (packet(arg_offset+2).usize() <<  8) or
                  (packet(arg_offset+3).usize()      )
                let blob_arg: Array[U8] val = recover
                  packet.slice(arg_offset + 4, arg_offset + 4 + blobsize_val)
                end
                if blob_arg.size() != blobsize_val then
                  error
                end
                // Skip to end of blob, including any padding bytes.
                let blobsize_val_padded = pad_four(blobsize_val)
                arg_offset = arg_offset + 4 + blobsize_val_padded
                args.push(blob_arg)
              else
                return OSCParseError("unsupported type char " + t.string())
              end
            until type_tag_offset == type_tag_end end
            args
          end
          OSCMessage(address, args_val)
        end
      else
        OSCParseError("truncated OSC packet")
      end
    end

  fun parse_bundle(packet: Array[U8] val): OSCParseResult =>
    OSCParseError("not implemented")

class val OSCTimeTag is (Stringable & Equatable[OSCTimeTag])
  let seconds: U32
  let fraction: U32

  new create(seconds': U32, fraction': U32) =>
    seconds = seconds'
    fraction = fraction'

  new create_from_time(time': F64) =>
    seconds = time'.floor().u32()
    fraction = ((time' - time'.floor()) * U32.max_value().f64()).u32()

  fun box time(): F64 =>
    seconds.f64() + (fraction.f64() / U32.max_value().f64())

  fun box string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let time': F64 = time()
    recover
      let time_str: String val = recover time'.string() end
      let result: String ref = String()
      result.append("OSCTimeTag(time=")
      result.append(time_str)
      result.append(")")
      result
    end

  fun box eq(that: OSCTimeTag box): Bool =>
    (seconds == that.seconds) and (fraction == that.fraction)

class val OSCMessage is Stringable
  let address: OSCAddress val
  let args: Array[OSCData] val

  new create(address': OSCAddress, args': Array[OSCData] val) =>
    address = address'
    args = args'

  fun box string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let address': OSCAddress = address
    let args': Array[OSCData] val = args
    recover
      let result: String ref = String()
      result.append("OSCMessage(addr=\"/")
      result.append(address'.string())
      result.append("\", args=[")
      for i in args'.keys() do
        try
          let arg: OSCData box = args'(i)
          match arg
          | let i32_arg: I32 box =>
            result.append("i32:")
            result.append(i32_arg.string())
          | let f32_arg: F32 box =>
            result.append("f32:")
            result.append(f32_arg.string())
          | let string_arg: String box =>
            result.append("str:")
            result.append(string_arg)
          | let blob_arg: Array[U8] box =>
            result.append("blob:#")
            result.append(blob_arg.size().string())
          else
            result.append("???")
          end
        end
        if i < (args'.size() - 1) then
          result.append(", ")
        end
      end
      result.append("])")
      result
    end

class val OSCBundle
  let time: OSCTimeTag
  let elements: Array[(OSCMessage | OSCBundle)]

  new create(time': OSCTimeTag, elements': Array[(OSCMessage | OSCBundle)]) =>
    time = time'
    elements = elements'

class val OSCAddress is (Stringable & Equatable[OSCAddress])
  let elements: Array[String]

  new create(address: String) =>
    let elements': Array[String] = address.split("/")
    elements = Array[String]()
    for element in elements'.values() do
      if element.size() > 0 then
        elements.push(element)
      end
    end

  new from_array(elements': Array[String]) =>
    elements = elements'

  fun box eq(that: OSCAddress box): Bool =>
    try
      for i in elements.keys() do
        if elements(i) != that.elements(i) then
          return false
        end
      end
      true
    else
      false
    end

  fun box string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let result: String iso = recover String() end
    for i in elements.keys() do
      try
        result.append(elements(i))
      end
      if i < (elements.size() - 1) then
        result.append("/")
      end
    end
    result
