//
//  JSON.swift
//  JSJSON
//
//  Created by Jernej Strasner on 7/7/15.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

func toJSON<T>(x: T) -> String {
    return reflect(x).extract()
}

extension CollectionType {

    func toJSON() -> String {
        return reflect(self).extract()
    }

}

private extension MirrorType {

    func map<T>(@noescape transform: (String, MirrorType) -> T) -> [T] {
        var array = [T]()
        for i in 0..<self.count {
            array.append(transform(self[i]))
        }
        return array
    }

    func extract() -> String {
        switch self.disposition {
        case .Optional:
            if self.count > 0 {
                return self[0].1.extract()
            }
            return "null"
        case .IndexContainer:
            return "[" + ",".join(self.map({ $1.extract() })) + "]"
        case .KeyContainer:
            var array = [String]()
            for i in 0..<self.count {
                let el = self[i].1
                guard let key = el[0].1.value as? String where el.disposition == .Tuple && el.count == 2 else {
                    break
                }
                array.append("\""+key+"\":"+el[1].1.extract())
            }
            return "{" + ",".join(array) + "}"
        case .Struct:
            return "{" + ",".join(self.map({ "\""+$0.0+"\":"+$1.extract() })) + "}"
        default:
            switch self.value {
            case is Int, is Int8, is Int16, is Int32, is Int64, is UInt, is UInt8, is UInt16, is UInt32, is UInt64, is Float, is Double:
                return String(self.value)
            case is String:
                return "\"" + (self.value as! String) + "\""
            default:
                break
            }
        }
        fatalError("Type not supported: \"\(self.valueType)\"")
    }
    
}
