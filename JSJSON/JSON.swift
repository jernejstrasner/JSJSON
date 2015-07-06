//
//  JSJSON.swift
//  JSJSON
//
//  Created by Jernej Strasner on 12/23/14.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

protocol JSONValue {

    private func serialize() {

    }

}

//public enum JSValue {
//    case JSString(String)
//    case JSNumber(Int)
//    case JSNull
////    case JSArray([JSONValueEncoding])
//    case JSObject([String:JSONEncoding])
//}

//public protocol JSONEncoding {
//    func json() -> JSON
//}

//public protocol JSONValueEncoding {
//    func valueForJSON() -> JSValue
//}

//extension String: JSONEncoding {
//    public func json() -> JSON {
//        return JSON(self)
//    }
//}

//extension Int: JSONEncoding {
//    public func json() -> JSON {
//        return JSON(self)
//    }
//}

//public enum JSONValue {
//    case NullValue
//    case IntegerValue(Int)
//    case FloatValue(Float)
//    case StringValue(String)
//    case BoolValue(Bool)
////    case ArrayValue([JSONValue])
////    case ObjectValue([String:JSONValue])
//}

public class JSON {

//    let value: JSONValue
//
//    public init() {
//        self.value = JSONValue.NullValue
//    }
//
//    public init(_ value: Float) {
//        self.value = JSONValue.FloatValue(value)
//    }
//
//    public init(_ value: Int) {
//        self.value = JSONValue.IntegerValue(value)
//    }
//
//    public init(_ value: String) {
//        self.value = JSONValue.StringValue(value)
//    }
//
//    public init(_ value: Bool) {
//        self.value = JSONValue.BoolValue(value)
//    }

//    public convenience init<T>(_ value: T?) {
//        switch value {
//        case .None:
//            self.init()
//        case .Some(let v):
//            self.init(v)
//        }
//    }

//    public func encode() -> String {
//        switch value {
//        case .NullValue:
//            return "null"
//        case .BoolValue(let b):
//            return b ? "true" : "false"
//        case .FloatValue(let f):
//            return "\(f)"
//        case .IntegerValue(let i):
//            return "\(i)"
//        case .StringValue(let s):
//            return "\"" + reduce(s.unicodeScalars, ""){ "\($0)\($1.escape(asASCII: false))" } + "\""
//        case .ArrayValue(let a):
//            return "[" + ",".join(a.map{ JSON($0).encode() }) + "]"
//        case .ObjectValue(let o):
//            return "{" + ",".join(map(o){ "\"" + $0.0 + "\":" + JSON($0.1).encode() }) + "}"
//        }
//    }

    subscript(key: String) -> AnyObject! {
        return decodedValue.valueForKey(key)
    }

    subscript(index: Int) -> AnyObject {
        return decodedValue.objectAtIndex(index)
    }

    let decodedValue: AnyObject

    private init(object: AnyObject) {
        decodedValue = object
    }

    public class func decode(string: String) -> JSON! {
        // TODO: error checking
        let object: AnyObject? = NSJSONSerialization.JSONObjectWithData(string.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.AllowFragments, error: nil)
        switch object {
        case .None:
            return nil
        case .Some(let a) where a.isKindOfClass(NSArray) || a.isKindOfClass(NSDictionary):
            return JSON(object: a)
        default:
            fatalError("An illegal type was found!")
        }
    }

    enum JSONValue {
        case NullValue
        case NumberValue
        case StringValue(String)
        case BoolValue(Bool)
        case ArrayValue([JSONValue])
        case ObjectValue([String:JSONValue])
    }

    private class func convert(object: AnyObject) {
        let n = JSONNumber<Int64>(64)
    }

}

struct JSONNode<T> {
    let value: T!

    init() {
        value = nil
    }

    init(_ number: NSNumber) {
        let t = number.objCType
    }

    init(_ string: NSString) {

    }

    init(_ array: NSArray) {

    }

    init(_ dictionary: NSDictionary) {

    }
}

private struct JSONNumber<T> {
    let value: T
    init<U: IntegerType>(_ i: U) {
        value = unsafeBitCast(i, T.self)
    }

    init(_ number: NSNumber) {

    }
}

//extension JSON {
//
//    public convenience init(_ value: Int8) {
//        self.init(Int(value))
//    }
//
//    public convenience init(_ value: Int16) {
//        self.init(Int(value))
//    }
//
//    public convenience init(_ value: Int32) {
//        self.init(Int(value))
//    }
//
//    public convenience init(_ value: Int64) {
//        self.init(Int(value))
//    }
//
//    public convenience init(_ value: UInt) {
//        self.init(Int(value))
//    }
//
//    public convenience init(_ value: UInt8) {
//        self.init(Int(value))
//    }
//
//    public convenience init(_ value: UInt16) {
//        self.init(Int(value))
//    }
//
//    public convenience init(_ value: UInt32) {
//        self.init(Int(value))
//    }
//
//    public convenience init(_ value: UInt64) {
//        self.init(Int(value))
//    }
//
//}
