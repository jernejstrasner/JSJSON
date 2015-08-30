//
//  SerializationTests.swift
//  JSJSON
//
//  Created by Jernej Strasner on 7/7/15.
//  Copyright © 2015 Jernej Strasner. All rights reserved.
//

import XCTest
import JSON

struct Person {
    var name: String
    var age: Int
    let factor = 99.1

    var year: Int {
        return 2015-age
    }

    let address: String = {
        var s = ""
        s += "745 Homer Ave"
        s += ", Palo Alto 94301"
        return s
        }()

    func whatever() {
        print("")
    }

    var children: [Person]?
}

class SerializationTests: XCTestCase {

    func testErrors() {
        AssertThrows(try JSON.serialize(NSData()))
        AssertNoThrow(try JSON.serialize(999))
    }

    func testNumbers() {
        AssertNoThrowValidateValue(try JSON.serialize(1)) { $0 == "1" }
        AssertNoThrowValidateValue(try JSON.serialize(1)) { $0 == "1" }
        AssertNoThrowValidateValue(try JSON.serialize(0)) { $0 == "0" }
        AssertNoThrowValidateValue(try JSON.serialize(8.3)) { $0 == "8.3" }
        AssertNoThrowValidateValue(try JSON.serialize(-772.1214842)) { $0 == "-772.1214842" }
        AssertNoThrowValidateValue(try JSON.serialize(Int8(3))) { $0 == "3" }
    }

    func testString() {
        AssertNoThrowValidateValue(try JSON.serialize("test")) { $0 == "\"test\"" }
        AssertNoThrowValidateValue(try JSON.serialize("emoji😄")) { $0 == "\"emoji😄\"" }
    }
    
    func testArray() {
        let a = [0, 8, 2, 1, 9, 0]
        AssertNoThrowValidateValue(try JSON.serialize(a)) { $0 == "[0,8,2,1,9,0]" }

        let b = [871.22, 9381.1123, -84812.1212, 2.398287733]
        AssertNoThrowValidateValue(try JSON.serialize(b)) { $0 == "[871.22,9381.1123,-84812.1212,2.398287733]" }
    }

    func testDictionary() {
        let a = [
            "a": 9,
            "b": 922,
            "c": 813
        ]
        let set: Set<String> = [
            "{\"a\":9,\"b\":922,\"c\":813}",
            "{\"a\":9,\"c\":813,\"b\":922}",
            "{\"b\":922,\"a\":9,\"c\":813}",
            "{\"b\":922,\"c\":813,\"a\":9}",
            "{\"c\":813,\"b\":922,\"a\":9}",
            "{\"c\":813,\"a\":9,\"b\":922}",
        ]
        AssertNoThrowValidateValue(try JSON.serialize(a)) { set.contains($0) }
    }

    func testStruct() {
        let a = Person(name: "John", age: 32, children: nil)
        AssertNoThrowValidateValue(try JSON.serialize(a)) { $0 == "{\"name\":\"John\",\"age\":32,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":null}" }

        let b = Person(name: "George", age: 43, children: [
            Person(name: "Ann", age: 12, children: nil),
            Person(name: "Matt", age: 18, children: nil)
            ]
        )
        AssertNoThrowValidateValue(try JSON.serialize(b)) { $0 == "{\"name\":\"George\",\"age\":43,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":[{\"name\":\"Ann\",\"age\":12,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":null},{\"name\":\"Matt\",\"age\":18,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":null}]}" }
    }

//    // Not supporting ObjC objects, here just for testing how much support we get for free
//    func testObjectiveC() {
//        // Note: The following fails because boolean values are represented as NSNumber in ObjC.
//        // The value thus gets serialized as an integer of 0 or 1.
//        let a = NSNumber(bool: true)
//        XCTAssertEqual("true", toJSON(a))
//
//        // You can't use use the literal convertible feature if you want to maintain precison.
//        // Not sure about the reason yet.
//        // let b: NSNumber = 8.3
//        let b = NSNumber(float: 8.3)
//        XCTAssertEqual("8.3", toJSON(b))
//
//        let c = NSNumber(int: 881)
//        XCTAssertEqual("881", toJSON(c))
//
//        let d: NSArray = ["saf", 3, "asdasa", 8]
//        XCTAssertEqual("[\"saf\",3,\"asdasa\",8]", toJSON(d))
//
//        let e: NSDictionary = ["a": 3, "b": "test", "c": 9.11]
//        let eSet: Set<String> = [
//            "{\"a\":3,\"c\":9.11,\"b\":\"test\"}",
//            "{\"a\":3,\"b\":\"test\",\"c\":9.11}",
//            "{\"b\":\"test\",\"a\":3,\"c\":9.11}",
//            "{\"b\":\"test\",\"c\":9.11,\"a\":3}",
//            "{\"c\":9.11,\"a\":3,\"b\":\"test\"}",
//            "{\"c\":9.11,\"b\":\"test\",\"a\":3}"
//        ]
//        let eJSON = toJSON(e)
//        XCTAssert(eSet.contains(eJSON), eJSON)
//    }

}
