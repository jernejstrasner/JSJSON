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

    func testNumbers() {
        XCTAssertEqual("1", toJSON(1))
        XCTAssertEqual("0", toJSON(0))
        XCTAssertEqual("8.3", toJSON(8.3))
        XCTAssertEqual("-772.1214842", toJSON(-772.1214842))
        XCTAssertEqual("3", toJSON(Int8(3)))
    }
    
    func testArray() {
        let a = [0, 8, 2, 1, 9, 0]
        XCTAssertEqual("[0,8,2,1,9,0]", a.toJSON())

        let b = [871.22, 9381.1123, -84812.1212, 2.398287733]
        XCTAssertEqual("[871.22,9381.1123,-84812.1212,2.398287733]", b.toJSON())
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
        XCTAssert(set.contains(a.toJSON()))
    }

    func testStruct() {
        let a = Person(name: "John", age: 32, children: nil)
        XCTAssertEqual("{\"name\":\"John\",\"age\":32,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":null}", toJSON(a))

        let b = Person(name: "George", age: 43, children: [
            Person(name: "Ann", age: 12, children: nil),
            Person(name: "Matt", age: 18, children: nil)
            ]
        )
        XCTAssertEqual("{\"name\":\"George\",\"age\":43,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":[{\"name\":\"Ann\",\"age\":12,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":null},{\"name\":\"Matt\",\"age\":18,\"factor\":99.1,\"address\":\"745 Homer Ave, Palo Alto 94301\",\"children\":null}]}", toJSON(b))
    }

    func testObjectiveC() {
        // Note: The following fails because boolean values are represented as NSNumber in ObjC.
        // The value thus gets serialized as an integer of 0 or 1.
        let a: NSNumber = true
        XCTAssertEqual("true", toJSON(a))

        // No idea why this fails and 2.3 works
        let b: NSNumber = 8.3
        XCTAssertEqual("8.3", toJSON(b))

        let c: NSNumber = 2.3
        XCTAssertEqual("2.3", toJSON(c))

        let d: NSArray = ["saf", 3, "asdasa", 8]
        XCTAssertEqual("[\"saf\",3,\"asdasa\",8]", toJSON(d))
    }

}
