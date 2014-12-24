//
//  JSJSON.swift
//  JSJSON
//
//  Created by Jernej Strasner on 12/23/14.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

public enum JSValue {
    case JSString(String)
    case JSNumber(Int)
    case JSNull
    case JSArray([JSValue])
    case JSObject([String:JSValue])

    public func encode() -> String {
        switch self {
        case .JSNull:
            return "null"
        case .JSNumber(let n):
            return "\(n)"
        case .JSString(let s):
            return "\"" + reduce(s.unicodeScalars, ""){ "\($0)\($1.escape(asASCII: false))" } + "\""
        case .JSArray(let a):
            return "[" + ",".join(a.map{ $0.encode() }) + "]"
        case .JSObject(let o):
            return "{" + ",".join(map(o){ "\"" + $0.0 + "\":" + $0.1.encode() }) + "}"
        }
    }
}

public protocol JSONEncoding {
    func jsonize() -> [String: JSValue]
}

//public class JSON: DebugPrintable {
//
//    let value: JSValue
//
//    public init(_ string: String) {
//        value = JSValue.JSString(string)
//    }
//
//    public init(_ number: Int) {
//        value = JSValue.JSNumber(number)
//    }
//
//    public var debugDescription: String {
//        get {
//            if let s = self.encode() {
//                return s
//            }
//            return "null"
//        }
//    }
//}
