//
//  JSON.swift
//  JSJSON
//
//  Created by Jernej Strasner on 7/7/15.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

enum JSONError : ErrorType {
    case TypeNotSupported(Any.Type)
}

func toJSON<T>(x: T) throws -> String {
    return try reflect(x).extract()
}

extension CollectionType {

    func toJSON() throws -> String {
        return try reflect(self).extract()
    }

}

private extension MirrorType {

    func mapChildren<T>(@noescape transform: (String, MirrorType) throws -> T) throws -> [T] {
        var array = [T]()
        for i in 0..<self.count {
            try array.append(transform(self[i]))
        }
        return array
    }

    func extract() throws -> String {
        switch self.disposition {
        case .Optional:
            guard self.count > 0 else {
                return "null"
            }
            return try self[0].1.extract()
        case .IndexContainer:
            return "[" + ",".join(try self.mapChildren{ try $1.extract() }) + "]"
        case .KeyContainer:
            let array = try self.mapChildren { name, el -> String in
                guard let key = el[0].1.value as? String where el.disposition == .Tuple && el.count == 2 else {
                    throw JSONError.TypeNotSupported(self.valueType)
                }
                return try "\""+key+"\":"+el[1].1.extract()
            }
            return "{" + ",".join(array) + "}"
        case .Struct:
            return "{" + ",".join(try self.mapChildren({ try "\""+$0.0+"\":"+$1.extract() })) + "}"
        default:
            switch self.value {
            case is Int, is Int8, is Int16, is Int32, is Int64, is UInt, is UInt8, is UInt16, is UInt32, is UInt64, is Float, is Double:
                return String(self.value)
            case is String:
                return "\"" + (self.value as! String) + "\""
            default:
                throw JSONError.TypeNotSupported(self.valueType)
            }
        }
    }
    
}
