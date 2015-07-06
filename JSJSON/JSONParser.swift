//
//  JSONParser.swift
//  JSJSON
//
//  Created by Jernej Strasner on 12/29/14.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

import Foundation

private class StackNode<T> {
    let value: T
    var previous: StackNode?

    init(_ v: T) {
        value = v
    }
}

private struct Stack<T> {
    private var tail: StackNode<T>!

    init() {}

    mutating func push(el: T) {
//        logIndented(self.size, "PUSH \(_stdlib_getDemangledTypeName(el)): \(el)")
        if tail == nil {
            tail = StackNode(el)
        } else {
            let prev = tail
            tail = StackNode(el)
            tail.previous = prev
        }
    }

    mutating func pop() -> T! {
        let el = tail
        if el != nil {
//          logIndented(self.size-1, "POP \(_stdlib_getDemangledTypeName(storage.last!))")
            tail = el.previous
        }
        return el?.value
    }

    func peek() -> T! {
        return tail?.value
    }
}

public class JObject : JSONValue, CustomDebugStringConvertible {
    private var storage = [String : JSONValue]()

    public subscript(key: String) -> JSONValue! {
        get {
            return storage[key]
        }
        set {
            storage[key] = newValue
        }
    }

    public var debugDescription: String {
        return storage.debugDescription
    }
}

public class JArray : JSONValue, CustomDebugStringConvertible {
    private var storage = [JSONValue]()

    public subscript(index: Int) -> JSONValue! {
        if index < storage.count && index >= 0 {
            return storage[index]
        }
        return nil
    }

    func append(value: JSONValue) {
        storage.append(value)
    }

    public var debugDescription: String {
        return storage.debugDescription
    }
}

public protocol JSONValue {}
extension Bool : JSONValue {}
extension Int : JSONValue {}
extension Int8 : JSONValue {}
extension Int16 : JSONValue {}
extension Int32 : JSONValue {}
extension Int64 : JSONValue {}
extension UInt : JSONValue {}
extension UInt8 : JSONValue {}
extension UInt16 : JSONValue {}
extension UInt32 : JSONValue {}
extension UInt64 : JSONValue {}
extension Float : JSONValue {}
extension Double : JSONValue {}
extension String : JSONValue {}

public enum TokenValue {
    case Null
    case N(Double)
    case S(String)
    case B(Bool)
    case A([TokenValue])
    case O([String:TokenValue])

//    init(_ value: JSONValue?) {
//        switch value {
//        case .None: self = .Null
//        case .Some(let s as String): self = .S(s)
//        case .Some(let b as Bool): self = .B(b)
//        }
//    }

    var isNull: Bool {
        switch self {
        case .Null: return true
        default: return false
        }
    }

    var string: String? {
        switch self {
        case .S(let s): return s
        default: return nil
        }
    }

    var number: Double? {
        switch self {
        case .N(let d): return d
        default: return nil
        }
    }

    var bool: Bool? {
        switch self {
        case .B(let b): return b
        default: return nil
        }
    }

    subscript(index: Int) -> TokenValue? {
        switch self {
        case .A(let a) where a.count > index: return a[index]
        default: return nil
        }
    }

    subscript(key: String) -> TokenValue? {
        switch self {
        case .O(let o): return o[key]
        default: return nil
        }
    }
}

enum TokenType {
    case Null, Boolean, Number, String, Object, Array
}

class Token {
    let type: TokenType
    var pointer = UnsafePointer<Int8>(nil)
    var length = 0

    init(_ type: TokenType) {
        self.type = type
    }
}

public class JSONParser {

    private let json: UnsafePointer<Int8>
    private let length: Int
    private var position = 0
    private var tokens = Stack<Token>()

    convenience init?(_ s: String) {
        if let data = s.dataUsingEncoding(NSUTF8StringEncoding) {
            self.init(bytes: UnsafePointer<Int8>(data.bytes), length: data.length)
        } else {
            self.init()
            return nil
        }
    }

    convenience init(_ data: NSData) {
        self.init(bytes: UnsafePointer<Int8>(data.bytes), length: data.length)
    }

    init(bytes: UnsafePointer<Int8>, length: Int) {
        self.json = bytes
        self.length = length
    }

    private init() {
        json = UnsafePointer<Int8>(nil)
        length = 0
    }

    public func parse() -> JSONValue? {
        for ; position < length; position++ {
            let c = json[position]
            switch c {
            case 0x7b: // {
                var token = Token(.Object)
                token.pointer = json + position
                tokens.push(token)
            case 0x5b: // [
                var token = Token(.Array)
                token.pointer = json + position
                tokens.push(token)
            case 0x5d:
                
            case 0x7d, 0x5d: // }, ]
                switch c {
                case 0x7d: assert(tokens.peek().type == .Object, "Unmatched Object closing bracket!")
                default: assert(tokens.peek().type == .Array, "Unmatched Array closing bracket!")
                }
                let lastToken = tokens.pop()
                let parentToken = tokens.peek()
                // Check if we're done parsing
                if parentToken == nil {
                    return lastToken
                }
                // If not insert the token into the stack or parent token
                insertIntoStack(lastToken)
            case 0x9, 0x0d, 0x0a, 0x20: // \t, \r, \n, (space)
                // Blank space
                break
            case 0x22: // "
                // String
                if let token = parseString() {
                    if let tok = convertToString(token) {
                        insertIntoStack(tok)
                    } else {
                        assertionFailure("Could not parse string!")
                    }
                } else {
                    assertionFailure("Could not parse string!")
                }
            case 0x3a: // :
                break
            case 0x2c: // ,
                // Next object in array
                break
            case 0x2d, 0x30...0x39, 0x74, 0x66, 0x6e: // -, 0-9, t, f, n
                // Number
                if let primitive = parsePrimitive() {
                    var value: JSONValue?
                    switch c {
                    case 0x6e:  value = "null"
                    case 0x74:  value = true
                    case 0x66:  value = false
                    default:    value = convertToNumber(primitive)
                    }
                    if let v = value {
                        insertIntoStack(v)
                    } else {
                        assertionFailure("Could not parse primitive!")
                    }
                } else {
                    assertionFailure("Could not parse primitive!")
                }
            default:
                // Unexpected character
                assertionFailure("Unexpected character!")
            }
        }
        return nil
    }

    private func insertIntoStack(val: JSONValue) {
        switch tokens.peek() {
        case let a as JArray:
            a.append(val)
        case let o as JObject:
            tokens.push(val)
        case let s as String:
            tokens.pop()
            if let o = tokens.peek() as? JObject {
                o[s] = val
            } else {
                assertionFailure("Something that shouldn't be is on the tokens stack!")
            }
        default:
            assertionFailure("Something that shouldn't be is on the tokens stack!")
        }
    }

    private func parseString() -> (UnsafePointer<Int8>, Int)? {
        // Skip the opening "
        position++
        let start = position

        for ; position < length; position++ {
            let c = json[position]
            // Check for end of string
            if c == 0x22 {
                return (json+start, position-start)
            }

            // Check for escaped symbols
            if c == 0x5c && position+1 < length {
                // Advance by one so we can switch on the symbol
                let c = json[++position]
                switch c {
                case 0x22, 0x2f, 0x5c, 0x62, 0x66, 0x72, 0x6e, 0x74:
                    break;
                case 0x75:
                    // Check for valid hex characters
                    position++
                    for var i = 0; i < 4 && position < length; i++, position++ {
                        switch json[position] {
                        case 0x30...0x39, 0x41...0x46, 0x61...0x66: continue
                        default: assertionFailure("Invalid HEX character: \(json[position])")
                        }
                    }
                    position--
                default:
                    assertionFailure("Unexpected symbol: \(c)")
                }
            }
        }
        return nil
    }

    private func parsePrimitive() -> (UnsafePointer<Int8>, Int)? {
        let start = position
        for ; position < length; position++ {
            switch json[position] {
            case 0x9, 0x0d, 0x0a, 0x20, 0x2c, 0x7d, 0x5d:
                return (json+start, (position--)-start)
            default: continue
            }
        }
        return nil
    }

    private func convertToString(a: (UnsafePointer<Int8>, Int)?) -> String? {
        if let (s, l) = a {
            return NSString(bytes: s, length: l, encoding: NSUTF8StringEncoding)
        }
        return nil
    }

    func convertToNumber(a: (UnsafePointer<Int8>, Int)?) -> Double? {
        if let (s, l) = a {
//            var ss = ""
//            for var i = 0; i < l; i++ {
//                ss.append(UnicodeScalar(numericCast(s[i]) as UInt8))
//            }
//            print("\(l) \(s) -> \(ss)")

            var isFloatingPoint = false
            var isNegative = false

            // Check if we have a valid number and determine if it's a float and/or negative
            for var i = 0; i < l; i++ {
                switch s[i] {
                case 0x2d where i == 0 || isFloatingPoint:
                    isNegative = true
                case 0x2e, 0x45, 0x65 where i > 0:
                    isFloatingPoint = true
                case 0x2b where i > 0:
                    continue
                case 0x30...0x39:
                    continue
                default:
                    fatalError("Invalid number!")
                }
            }

            // Parse the number
            var number: Double
            if isFloatingPoint {
                number = strtod(s, nil)
            } else {
                if isNegative {
                    number = Double(strtoll(s, nil, 10))
                } else {
                    number = Double(strtoull(s, nil, 10))
                }
            }
//            println(" = \(number)")
            return number
        }
        return nil
    }

}

// MARK: Debugging Utilities

private func *(left: Character, right: Int) -> String {
    return (0..<right).reduce("") { "\($0.0)\(left)" }
}

private func logIndented<T>(x: Int, s: T) {
    let tabs = ">" * x
    print("\(tabs)\(s)")
}
