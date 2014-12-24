//
//  JSJSONTests.swift
//  JSJSONTests
//
//  Created by Jernej Strasner on 12/23/14.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

import UIKit
import XCTest
import JSJSON

struct Address: JSONEncoding {
    var street: String
    var city: String
    var zipCode: Int
    var country: String

    func jsonize() -> [String: JSValue] {
        return [
            "street": JSValue.JSString(street),
            "city": JSValue.JSString(city),
            "zipCode": JSValue.JSNumber(zipCode),
            "country": JSValue.JSString(country)
        ]
    }
}

struct Person: JSONEncoding {
    var name: String
    var email: String
    var address: Address
    var friends: [Person]

    func jsonize() -> [String : JSValue] {
        return [
            "name": JSValue.JSString(name),
            "email": JSValue.JSString(email),
            "address": JSValue.JSObject(address.jsonize()),
            "friends": JSValue.JSArray(friends.map{JSValue.JSObject($0.jsonize())})
        ]
    }
}

class JSJSONTests: XCTestCase {

    func testTypes() {
        var person = Person(
            name: "Jernej Strasner",
            email: "jernej.strasner@gmail.com",
            address: Address(
                street: "Sared 31d",
                city: "Izola",
                zipCode: 6310,
                country: "Slovenija"
            ),
            friends: [
                Person(
                    name: "Jernej Strasner",
                    email: "jernej.strasner@gmail.com",
                    address: Address(
                        street: "Sared 31d",
                        city: "Izola",
                        zipCode: 6310,
                        country: "Slovenija"
                    ),
                    friends: []
                )
            ]
        )
        let validJSON = "{\"address\":{\"city\":\"Izola\",\"zipCode\":6310,\"country\":\"Slovenija\",\"street\":\"Sared 31d\"},\"email\":\"jernej.strasner@gmail.com\",\"friends\":[{\"address\":{\"city\":\"Izola\",\"zipCode\":6310,\"country\":\"Slovenija\",\"street\":\"Sared 31d\"},\"email\":\"jernej.strasner@gmail.com\",\"friends\":[],\"name\":\"Jernej Strasner\"}],\"name\":\"Jernej Strasner\"}"
        let json = JSValue.JSObject(person.jsonize()).encode()
        debugPrintln(json)
        println(json)
        XCTAssert(validJSON == json)
    }

}
