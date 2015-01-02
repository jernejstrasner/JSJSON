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
        var el = tail
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

public class JObject : JSONValue, DebugPrintable {
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

public class JArray : JSONValue, DebugPrintable {
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

public class JSONParser {

    let json: ContiguousArray<UInt8>
    private var tokens: Stack<JSONValue>
    private var position: Int

    init(_ s: String) {
        json = s.nulTerminatedUTF8
        position = json.startIndex
        tokens = Stack<JSONValue>()
    }

    public func parse() -> JSONValue? {
        for ; position < json.endIndex; position++ {
            let c = json[position]
            switch c {
            case 0x7b: // {
                tokens.push(JObject())
            case 0x5b: // [
                tokens.push(JArray())
            case 0x7d, 0x5d: // }, ]
                switch c {
                case 0x7d: assert(tokens.peek() is JObject, "Unmatched Object closing bracket!")
                default: assert(tokens.peek() is JArray, "Unmatched Array closing bracket!")
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
                    default:
                        if let s = convertToString(primitive) {
                            value = NSNumberFormatter().numberFromString(s)?.doubleValue
                        }
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

    private func parseString() -> Slice<UInt8>? {
        // Skip the opening "
        position++
        let start = position

        for ; position < json.endIndex; position++ {
            let c = json[position]
            // Check for end of string
            if c == 0x22 {
                return json[start..<position]
            }

            // Check for escaped symbols
            if c == 0x5c && position+1 < json.endIndex {
                // Advance by one so we can switch on the symbol
                let c = json[++position]
                switch c {
                case 0x22, 0x2f, 0x5c, 0x62, 0x66, 0x72, 0x6e, 0x74:
                    break;
                case 0x75:
                    // Check for valid hex characters
                    position++
                    for var i = 0; i < 4 && position < json.endIndex; i++, position++ {
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

    private func parsePrimitive() -> Slice<UInt8>? {
        let start = position
        for ; position < json.endIndex; position++ {
            switch json[position] {
            case 0x9, 0x0d, 0x0a, 0x20, 0x2c, 0x7d, 0x5d:
                return json[start..<position--]
            default: continue
            }
        }
        return nil
    }

    private func convertToString(a: Slice<UInt8>?) -> String! {
        if a != nil {
//            return a!.withUnsafeBufferPointer {
//                String.fromCString(UnsafeMutablePointer($0.baseAddress))
//            }!
//            return a!.reduce(""){"\($0)\(String(UnicodeScalar($1)))"}
            return "122"
        }
        return nil
    }
}

// MARK: Debugging Utilities

private func *(left: Character, right: Int) -> String {
    return reduce(0..<right, "") { "\($0.0)\(left)" }
}

private func logIndented<T>(x: Int, s: T) {
    let tabs = ">" * x
    println("\(tabs)\(s)")
}
