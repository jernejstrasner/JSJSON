//
//  JSONParser.swift
//  JSJSON
//
//  Created by Jernej Strasner on 12/29/14.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

import Foundation

private struct Stack<T> {

    private(set) var items = [T]()

    mutating func push(el: T) {
        items.append(el)
    }

    mutating func pop() -> T? {
        if items.count > 0 {
            return items.removeLast()
        }
        return nil
    }

    func peek() -> T? {
        return items.last
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
extension Array : JSONValue {}
extension Dictionary : JSONValue {}

public enum TokenValue {
    case Null
    case N(Double)
    case S(String)
    case B(Bool)
    case A([TokenValue])
    case O([String:TokenValue])

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

struct Token {

    enum Kind {
        case ObjectStart, ArrayStart, Null, Boolean, Number, String, Colon, Comma, ObjectEnd, ArrayEnd
    }

    let kind: Kind
    var pointer: UnsafePointer<Int8>
    var length: Int

    init(kind: Kind, pointer: UnsafePointer<Int8>, length: Int = 0) {
        self.kind = kind
        self.pointer = pointer
        self.length = length
    }

}

public class JSONParser {

    enum Error : ErrorType {
        case UnmatchedObjectClosingBracket
        case UnmatchedArrayClosingBracket
        case StringInvalidHexCharacter
        case StringUnexpectedSymbol
        case InvalidPrimitive
        case UnexpectedCharacter
    }
    
    private let json: UnsafePointer<Int8>
    private let length: Int
    private var position = 0
    private var tokens = Stack<Token>()

    convenience init?(_ s: String) {
        if let data = s.dataUsingEncoding(NSUTF8StringEncoding) {
            self.init(bytes: UnsafePointer<Int8>(data.bytes), length: data.length)
        } else {
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

    func parse() throws {
        for ; position < length; position++ {
            let c = json[position]
            switch c {
            case 0x7b: // {
                tokens.push(Token(kind: .ObjectStart, pointer: json + position, length: 1))
            case 0x5b: // [
                tokens.push(Token(kind: .ArrayStart, pointer: json + position, length: 1))
            case 0x5d: // ]
                tokens.push(Token(kind: .ArrayEnd, pointer: json + position, length: 1))
            case 0x7d: // }
                tokens.push(Token(kind: .ObjectEnd, pointer: json + position, length: 1))
            case 0x9, 0x0d, 0x0a, 0x20: // \t, \r, \n, (space)
                // Blank space
                break
            case 0x22: // "
                let token = try parseString()
                tokens.push(token)
            case 0x3a: // :
                tokens.push(Token(kind: .Colon, pointer: json + position, length: 1))
            case 0x2c: // ,
                tokens.push(Token(kind: .Comma, pointer: json + position, length: 1))
            case 0x2d, 0x30...0x39, 0x74, 0x66, 0x6e: // -, 0-9, t, f, n
                let token = try parsePrimitive()
                tokens.push(token)
            default:
                throw Error.UnexpectedCharacter
            }
        }
    }

    private func parseString() throws -> Token {
        // Skip the opening "
        position++
        let start = position

        for ; position < length; position++ {
            let c = json[position]
            // Check for end of string
            if c == 0x22 {
                return Token(kind: .String, pointer: json+start, length: position-start)
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
                        default: throw Error.StringInvalidHexCharacter
                        }
                    }
                    position--
                default:
                    throw Error.StringUnexpectedSymbol
                }
            }
        }
        // Zero length string
        return Token(kind: .String, pointer: json+start, length: 0)
    }

//    case 0x2d, 0x30...0x39, 0x74, 0x66, 0x6e: // -, 0-9, t, f, n

//    case 0x6e:  value = "null"
//    case 0x74:  value = true
//    case 0x66:  value = false
//    default:    value = convertToNumber(primitive)

    private func parsePrimitive() throws -> Token {
        // Get the type
        var kind: Token.Kind
        switch json[position] {
        case 0x6e: kind = .Null
        case 0x74, 0x66: kind = .Boolean
        default: kind = .Number
        }

        // Get the value
        let start = position
        for ; position < length; position++ {
            switch json[position] {
            case 0x9, 0x0d, 0x0a, 0x20, 0x2c, 0x7d, 0x5d:
                return Token(kind: kind, pointer: json+start, length: (position--)-start)
            default:
                continue
            }
        }

        // Error
        throw Error.InvalidPrimitive
    }

//    private func convertToString(a: ValueToken) throws -> String {
//        if let (s, l) = a, let string = NSString(bytes: s, length: l, encoding: NSUTF8StringEncoding) as? String {
//            return string
//        }
//        return nil
//    }

//    func convertToNumber(a: Pointer?) -> Double? {
//        if let (s, l) = a {
//
//            var isFloatingPoint = false
//            var isNegative = false
//
//            // Check if we have a valid number and determine if it's a float and/or negative
//            for var i = 0; i < l; i++ {
//                switch s[i] {
//                case 0x2d where i == 0 || isFloatingPoint:
//                    isNegative = true
//                case 0x2e, 0x45, 0x65 where i > 0:
//                    isFloatingPoint = true
//                case 0x2b where i > 0:
//                    continue
//                case 0x30...0x39:
//                    continue
//                default:
//                    fatalError("Invalid number!")
//                }
//            }
//
//            // Parse the number
//            var number: Double
//            if isFloatingPoint {
//                number = strtod(s, nil)
//            } else {
//                if isNegative {
//                    number = Double(strtoll(s, nil, 10))
//                } else {
//                    number = Double(strtoull(s, nil, 10))
//                }
//            }
//            return number
//        }
//        return nil
//    }

}

// MARK: Debugging Utilities

private func *(left: Character, right: Int) -> String {
    return (0..<right).reduce("") { "\($0.0)\(left)" }
}

private func logIndented<T>(x: Int, s: T) {
    let tabs = ">" * x
    print("\(tabs)\(s)")
}
