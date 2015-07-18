//
//  JSONParser.swift
//  JSJSON
//
//  Created by Jernej Strasner on 12/29/14.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

import Foundation

public enum TokenValue {
    case Null
    case Number(Double)
    case Text(String)
    case Boolean(Bool)
    case Array([TokenValue])
    case Object([String:TokenValue])

    var isNull: Bool {
        if case .Null = self { return true }
        return false
    }

    var string: String? {
        if case .Text(let text) = self { return text }
        return nil
    }

    var number: Double? {
        if case .Number(let number) = self { return number }
        return nil
    }

    var bool: Bool? {
        if case .Boolean(let boolean) = self { return boolean }
        return nil
    }

    subscript(index: Int) -> TokenValue? {
        if case .Array(let array) = self where array.count > index { return array[index] }
        return nil
    }

    subscript(key: String) -> TokenValue? {
        if case .Object(let object) = self { return object[key] }
        return nil
    }

    var last: TokenValue? {
        if case .Array(let array) = self { return array.last }
        return nil
    }
}

extension TokenValue : CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .Null: return "Null"
        case .Boolean(let b): return "Boolean(\(b))"
        case .Number(let n): return "Number(\(n))"
        case .Text(let s): return "Text(\(s))"
        case .Array(let a): return "Array(\(a))"
        case .Object(let o): return "Object(\(o))"
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

    var isValueType: Bool {
        switch kind {
        case .Null, .Boolean, .Number, .String: return true
        default: return false
        }
    }

    func parseValue() throws -> TokenValue {
        switch kind {
        case .Null:
            return TokenValue.Null
        case .Boolean:
            switch pointer[0] {
            case 0x74: return TokenValue.Boolean(true)
            case 0x66: return TokenValue.Boolean(false)
            default: throw JSONParser.Error.InvalidBoolean
            }
        case .Number:
            var isFloatingPoint = false
            var isNegative = false

            // Check if we have a valid number and determine if it's a float and/or negative
            for var i = 0; i < length; i++ {
                switch pointer[i] {
                case 0x2d where i == 0 || isFloatingPoint:
                    isNegative = true
                case 0x2e, 0x45, 0x65 where i > 0:
                    isFloatingPoint = true
                case 0x2b where i > 0:
                    continue
                case 0x30...0x39:
                    continue
                default:
                    throw JSONParser.Error.InvalidNumber
                }
            }

            // Parse the number
            var number: Double
            if isFloatingPoint {
                number = strtod(pointer, nil)
            } else {
                if isNegative {
                    number = Double(strtoll(pointer, nil, 10))
                } else {
                    number = Double(strtoull(pointer, nil, 10))
                }
            }
            return TokenValue.Number(number)
        case .String:
            let string = try buildString()
            return TokenValue.Text(string)
        default:
            throw JSONParser.Error.NotAValueType
        }
    }

    func buildString() throws -> String {
        if let string = NSString(bytes: pointer, length: length, encoding: NSUTF8StringEncoding) as? String {
            return string
        }
        throw JSONParser.Error.InvalidString
    }

}

public struct JSONParser {

    enum Error : ErrorType {
        case StringInvalidHexCharacter
        case StringUnexpectedSymbol
        case UnexpectedCharacter
        case InvalidPrimitive
        case InvalidObject
        case InvalidString
        case InvalidNumber
        case InvalidBoolean
        case InvalidArray
        case UnexpectedRootNodeType
        case NotAValueType
    }
    
    private let json: UnsafePointer<Int8>
    private let length: Int

    init?(_ s: String) {
        if let data = s.dataUsingEncoding(NSUTF8StringEncoding) {
            self.init(bytes: UnsafePointer<Int8>(data.bytes), length: data.length)
        } else {
            return nil
        }
    }

    init(_ data: NSData) {
        self.init(bytes: UnsafePointer<Int8>(data.bytes), length: data.length)
    }

    init(bytes: UnsafePointer<Int8>, length: Int) {
        self.json = bytes
        self.length = length
    }

    func parse() throws -> TokenValue {
        var tokens = Array<Token>()
        var position = 0
        for ; position < length; position++ {
            let c = json[position]
            switch c {
            case 0x7b: // {
                tokens.append(Token(kind: .ObjectStart, pointer: json + position, length: 1))
            case 0x5b: // [
                tokens.append(Token(kind: .ArrayStart, pointer: json + position, length: 1))
            case 0x5d: // ]
                tokens.append(Token(kind: .ArrayEnd, pointer: json + position, length: 1))
            case 0x7d: // }
                tokens.append(Token(kind: .ObjectEnd, pointer: json + position, length: 1))
            case 0x9, 0x0d, 0x0a, 0x20: // \t, \r, \n, (space)
                // Blank space
                break
            case 0x22: // "
                let token = try parseString(&position)
                tokens.append(token)
            case 0x3a: // :
                tokens.append(Token(kind: .Colon, pointer: json + position, length: 1))
            case 0x2c: // ,
                tokens.append(Token(kind: .Comma, pointer: json + position, length: 1))
            case 0x2d, 0x30...0x39, 0x74, 0x66, 0x6e: // -, 0-9, t, f, n
                let token = try parsePrimitive(&position)
                tokens.append(token)
            default:
                throw Error.UnexpectedCharacter
            }
        }

        var stackLocation = 0
        if tokens.first?.kind == .ObjectStart {
            return try buildObject(&tokens, position: &stackLocation)
        } else if tokens.first?.kind == .ArrayStart {
            return try buildArray(&tokens, position: &stackLocation)
        } else {
            throw Error.UnexpectedRootNodeType
        }
    }

    private func buildObject(inout tokens: Array<Token>, inout position: Int) throws -> TokenValue {
        var object = [String:TokenValue]()
        position++ // Skip ObjectStart
        while position < tokens.count {
            // Key
            let keyToken = tokens[position]
            guard keyToken.kind == .String else {
                throw Error.InvalidObject
            }
            let key = try keyToken.buildString()
            // Colon
            guard tokens[++position].kind == .Colon else {
                throw Error.InvalidObject
            }
            // Value
            let valueToken = tokens[++position]
            if valueToken.isValueType {
                object[key] = try valueToken.parseValue()
            } else if valueToken.kind == .ArrayStart {
                object[key] = try buildArray(&tokens, position: &position)
            } else if valueToken.kind == .ObjectStart {
                object[key] = try buildObject(&tokens, position: &position)
            } else {
                throw Error.InvalidObject
            }
            // ObjectEnd or Comma
            let lastToken = tokens[++position]
            switch lastToken.kind {
            case .ObjectEnd: return TokenValue.Object(object)
            case .Comma: break
            default: throw Error.InvalidObject
            }
            ++position
        }
        // At the end of the stack but no ObjectEnd
        throw Error.InvalidObject
    }

    private func buildArray(inout tokens: Array<Token>, inout position: Int) throws -> TokenValue {
        var array = [TokenValue]()
        position++ // Skip ArrayStart
        while position < tokens.count {
            // Element
            let elementToken = tokens[position]
            if elementToken.isValueType {
                array.append(try elementToken.parseValue())
            } else if elementToken.kind == .ArrayStart {
                array.append(try buildArray(&tokens, position: &position))
            } else if elementToken.kind == .ObjectStart {
                array.append(try buildObject(&tokens, position: &position))
            } else {
                throw Error.InvalidArray
            }
            // ArrayEnd or Comma
            let lastToken = tokens[++position]
            switch lastToken.kind {
            case .ArrayEnd: return TokenValue.Array(array)
            case .Comma: break
            default: throw Error.InvalidArray
            }
            ++position
        }
        // At the end of the stack but no ArrayEnd
        throw Error.InvalidArray
    }

    private func parseString(inout position: Int) throws -> Token {
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
                    break
                case 0x75:
                    // Check for valid hex characters
                    position++
                    for var i = 0; i < 4 && position < length; i++, position++ {
                        switch json[position] {
                        case 0x30...0x39, 0x41...0x46, 0x61...0x66: break
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

    private func parsePrimitive(inout position: Int) throws -> Token {
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
                break
            }
        }

        // Error
        throw Error.InvalidPrimitive
    }

}
