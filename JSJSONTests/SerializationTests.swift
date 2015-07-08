//
//  SerializationTests.swift
//  JSJSON
//
//  Created by Jernej Strasner on 7/7/15.
//  Copyright © 2015 Jernej Strasner. All rights reserved.
//

import XCTest

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
        print()
    }

    var children: [Person]?
}

class SerializationTests: XCTestCase {

    func testErrors() {
        XCTAssertThrows(try toJSON(NSData()))
        XCTAssertNoThrow(try toJSON(999))
    }

    func testNumbers() {
        XCTAssertNoThrowEqual("1", try toJSON(1))
        XCTAssertNoThrowEqual("0", try toJSON(0))
        XCTAssertNoThrowEqual("8.3", try toJSON(8.3))
        XCTAssertNoThrowEqual("-772.1214842", try toJSON(-772.1214842))
        XCTAssertNoThrowEqual("3", try toJSON(Int8(3)))
    }

    func testString() {
        XCTAssertNoThrowEqual("\"test\"", try toJSON("test"))
        XCTAssertNoThrowEqual("\"emoji😄\"", try toJSON("emoji😄"))
    }
    
    func testArray() {
        let a = [0, 8, 2, 1, 9, 0]
        XCTAssertNoThrowEqual("[0,8,2,1,9,0]", try a.toJSON())

        let b = [871.22, 9381.1123, -84812.1212, 2.398287733]
        XCTAssertNoThrowEqual("[871.22,9381.1123,-84812.1212,2.398287733]", try b.toJSON())
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
        XCTAssertNoThrowValidateValue(try a.toJSON()) { set.contains($0) }
    }

    func testStruct() {
        let a = Person(name: "John", age: 32, children: nil)
        XCTAssertNoThrowEqual("{\"name\":\"John\",\"age\":32,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":null}", try toJSON(a))

        let b = Person(name: "George", age: 43, children: [
            Person(name: "Ann", age: 12, children: nil),
            Person(name: "Matt", age: 18, children: nil)
            ]
        )
        XCTAssertNoThrowEqual("{\"name\":\"George\",\"age\":43,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":[{\"name\":\"Ann\",\"age\":12,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":null},{\"name\":\"Matt\",\"age\":18,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":null}]}", try toJSON(b))
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
