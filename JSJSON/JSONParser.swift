//
//  JSONParser.swift
//  JSJSON
//
//  Created by Jernej Strasner on 12/29/14.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

import Foundation

struct Stack<T> : DebugPrintable {
    private var storage = [T]()

    mutating func push(el: T) {
//        logIndented(self.size, "PUSH \(_stdlib_getDemangledTypeName(el)): \(el)")
        storage.append(el)
    }

    mutating func pop() -> T! {
        if storage.count > 0 {
//            logIndented(self.size-1, "POP \(_stdlib_getDemangledTypeName(storage.last!))")
            return storage.removeLast()
        }
//        logIndented(0, "POP EMPTY")
        return nil
    }

    func peek() -> T! {
        return storage.last
    }

    var size: Int {
        return storage.count
    }

    var debugDescription: String {
        return storage.debugDescription
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

    let json: String.UnicodeScalarView
    var tokens: Stack<JSONValue>
    var position: String.UnicodeScalarView.Index

    init(_ s: String) {
        json = s.unicodeScalars
        position = json.startIndex
        tokens = Stack<JSONValue>()
    }

    public func parse() -> JSONValue? {
        for ; position < json.endIndex; position++ {
            let c = json[position]
            switch c {
            case "{":
                tokens.push(JObject())
            case "[":
                tokens.push(JArray())
            case "]", "}":
                switch c {
                case "}": assert(tokens.peek() is JObject, "Unmatched Object closing bracket!")
                case "]": assert(tokens.peek() is JArray, "Unmatched Array closing bracket!")
                default: break
                }
                let lastToken = tokens.pop()
                let parentToken = tokens.peek()
                // Check if we're done parsing
                if parentToken == nil {
                    return lastToken
                }
                // If not insert the token into the stack or parent token
                insertIntoStack(lastToken)
            case "\t", "\r", "\n", " ":
                // Blank space
                break
            case "\"":
                // String
                if let token = parseString() {
                    insertIntoStack(token)
                } else {
                    assertionFailure("Could not parse string!")
                }
            case ":":
                break
            case ",":
                // Next object in array
                break
            case "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "t", "f", "n":
                // Number
                if let primitive = parsePrimitive() {
                    var value: JSONValue?
                    switch c {
                    case "n":
                        value = "null"
                    case "t":
                        value = true
                    case "f":
                        value = false
                    default:
                        let nf = NSNumberFormatter()
                        if let i = nf.numberFromString(String(primitive)) {
                            value = Double(i.doubleValue)
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

    let hexCharacters: [UnicodeScalar] = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f","A","B","C","D","E","F"]

    private func parseString() -> String? {
        // Skip the opening "
        position++
        let start = position

        for ; position < json.endIndex; position++ {
            let c = json[position]
            // Check for end of string
            if c == "\"" {
                return String(json[start..<position])
            }

            // Check for escaped symbols
            if c == "\\" && position.successor() < json.endIndex {
                // Advance by one so we can switch on the symbol
                let c = json[++position]
                switch c {
                case "\"", "/", "\\", "b", "f", "r", "n", "t":
                    break;
                case "u":
                    // Check for valid hex characters
                    position++
                    for var i = 0; i < 4 && position < json.endIndex; i++, position++ {
                        if !contains(hexCharacters, json[position]) {
                            assertionFailure("Invalid HEX character: \(json[position])")
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

    private func parsePrimitive() -> String.UnicodeScalarView? {
        let start = position
        for ; position < json.endIndex; position++ {
            let c = json[position]
            if isTerminator(c) {
                return json[start..<position--]
            }
        }
        return nil
    }

    private func isTerminator(char: UnicodeScalar) -> Bool {
        switch char {
        case "\t", "\n", "\r", " ", ",", "]", "}": return true
        default: return false
        }
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

private func noop() {}
