//
//  ParametersCheckingTests.swift
//  SwiftHookTests
//
//  Created by Yanni Wang on 20/5/20.
//  Copyright © 2020 Yanni. All rights reserved.
//

import XCTest
@testable import SwiftHook

private let retainSelector = NSSelectorFromString("retain")
private let releaseSelector = NSSelectorFromString("release")
private let autoreleaseSelector = NSSelectorFromString("autorelease")
private let blacklistSelectors = [retainSelector, releaseSelector, autoreleaseSelector]

// TODO: 移除了很多 SignatureTests 里的 testcase，检查是否需要更全面的 ParametersCheckingTests？
// TODO: 更丰富的ParametersCheckingTests， 应该包含所有的SwiftHookError的类型
class ParametersCheckingTests: XCTestCase {
    
    func testCanNotHookClassWithObjectAPI() {
        do {
            try hookBefore(object: randomTestClass(), selector: randomSelector(), closure: {
            })
            XCTFail()
        } catch SwiftHookError.canNotHookClassWithObjectAPI {
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookAfter(object: randomTestClass(), selector: randomSelector(), closure: {
            })
            XCTFail()
        } catch SwiftHookError.canNotHookClassWithObjectAPI {
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookInstead(object: randomTestClass(), selector: randomSelector(), closure: {
            })
            XCTFail()
        } catch SwiftHookError.canNotHookClassWithObjectAPI {
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testUnsupportHookPureSwiftObjectDealloc() {
        do {
            try hookBefore(object: TestObject(), selector: deallocSelector, closure: {
            })
            XCTFail()
        } catch SwiftHookError.unsupport(value: let value) {
            XCTAssertEqual(value, .pureSwiftObjectDealloc)
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookAfter(object: TestObject(), selector: deallocSelector, closure: {
            })
            XCTFail()
        } catch SwiftHookError.unsupport(value: let value) {
            XCTAssertEqual(value, .pureSwiftObjectDealloc)
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookInstead(object: TestObject(), selector: deallocSelector, closure: {
            })
            XCTFail()
        } catch SwiftHookError.unsupport(value: let value) {
            XCTAssertEqual(value, .pureSwiftObjectDealloc)
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookBefore(targetClass: TestObject.self, selector: deallocSelector, closure: {
            })
            XCTFail()
        } catch SwiftHookError.unsupport(value: let value) {
            XCTAssertEqual(value, .pureSwiftObjectDealloc)
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookAfter(targetClass: TestObject.self, selector: deallocSelector, closure: {
            })
            XCTFail()
        } catch SwiftHookError.unsupport(value: let value) {
            XCTAssertEqual(value, .pureSwiftObjectDealloc)
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookInstead(targetClass: TestObject.self, selector: deallocSelector, closure: {
            })
            XCTFail()
        } catch SwiftHookError.unsupport(value: let value) {
            XCTAssertEqual(value, .pureSwiftObjectDealloc)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testNoRespondSelector() {
        do {
            try hookBefore(targetClass: randomTestClass(), selector: #selector(NSArray.object(at:)), closure: {})
            XCTFail()
        } catch SwiftHookError.noRespondSelector {
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookClassMethodAfter(targetClass: TestObject.self, selector: #selector(TestObject.noArgsNoReturnFunc), closure: {})
            XCTFail()
        } catch SwiftHookError.noRespondSelector {
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookInstead(object: TestObject(), selector: #selector(TestObject.classMethodNoArgsNoReturnFunc), closure: {})
            XCTFail()
        } catch SwiftHookError.noRespondSelector {
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testMissingSignature() {
        do {
            try hookBefore(targetClass: randomTestClass(), selector: #selector(TestObject.noArgsNoReturnFunc), closure: NSObject())
            XCTFail()
        } catch SwiftHookError.missingSignature {
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookClassMethodAfter(targetClass: TestObject.self, selector: #selector(TestObject.classMethodNoArgsNoReturnFunc), closure: 1)
            XCTFail()
        } catch SwiftHookError.missingSignature {
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookInstead(object: TestObject(), selector: #selector(TestObject.noArgsNoReturnFunc), closure: {} as AnyObject)
            XCTFail()
        } catch SwiftHookError.missingSignature {
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testIncompatibleClosureSignature() {
        do {
            try hookBefore(targetClass: TestObject.self, selector: #selector(TestObject.sumFunc(a:b:)), closure: { _, _ in
                return 1
                } as @convention(block) (Int, Int) -> Int as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {
            XCTAssertEqual(description, "For `befor` and `after` mode. The return type of the hook closure mush be `void`. But it's `q`")
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookAfter(object: TestObject(), selector: #selector(TestObject.sumFunc(a:b:)), closure: { _, _ in
                } as @convention(block) (Int, Double) -> Void as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {
            XCTAssertEqual(description, "For `befor` and `after` mode. The parameters type of the hook closure must be the same as method's. The closure parameters type is `qd`. But the method parameters type is `@:qq`. They are not the same.")
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookAfter(object: TestObject(), selector: #selector(TestObject.testStructSignature(point:rect:)), closure: ({_, _ in
                } as @convention(block) (CGPoint, Double) -> Void) as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {
            XCTAssertEqual(description, "For `befor` and `after` mode. The parameters type of the hook closure must be the same as method's. The closure parameters type is `{CGPoint=dd}d`. But the method parameters type is `@:{CGPoint=dd}{CGRect={CGPoint=dd}{CGSize=dd}}`. They are not the same.")
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookInstead(targetClass: TestObject.self, selector: #selector(TestObject.sumFunc(a:b:)), closure: { _, _ in
                } as @convention(block) (Int, Int) -> Void as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {
            XCTAssertEqual(description, "For `instead` mode. The number of hook closure parameters should be equal to the number of method parameters + 1 (The first parameter is the `original` closure. The rest is the same as method's). The hook closure parameters number is 2. The method parameters number is 4.")
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testBlacklist() {
        for selector in blacklistSelectors {
            do {
                let object = ObjectiveCTestObject()
                try hookBefore(object: object, selector: selector) {
                }
                XCTFail()
            } catch SwiftHookError.unsupport(value: let value) {
                XCTAssertEqual(value, .blacklist)
            } catch {
                XCTAssertNil(error)
            }
            
            do {
                try hookBefore(targetClass: ObjectiveCTestObject.self, selector: selector) {
                }
                XCTFail()
            } catch SwiftHookError.unsupport(value: let value) {
                XCTAssertEqual(value, .blacklist)
            } catch {
                XCTAssertNil(error)
            }
        }
    }
    
    func testHookInsteadOriginalClosureParametersWrong() {
        do {
            try hookInstead(targetClass: TestObject.self, selector: #selector(TestObject.sumFunc(a:b:)), closure: { original, a, b in
                let result = original(a, b)
                return Int(result)
                } as @convention(block) ((Int, Int) -> Double, Int, Int) -> Int as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {
            XCTAssertEqual(description, "For `instead` mode. The number of hook closure parameters should be equal to the number of method parameters + 1 (The first parameter is the `original` closure. The rest is the same as method's). The hook closure parameters number is 3. The method parameters number is 4.")
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookInstead(targetClass: TestObject.self, selector: #selector(TestObject.sumFunc(a:b:)), closure: { original, _, b in
                let result = original(NSObject.init(), b)
                return Int(result)
                } as @convention(block) ((NSObject, Int) -> Int, Int, Int) -> Int as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {
            XCTAssertEqual(description, "For `instead` mode. The number of hook closure parameters should be equal to the number of method parameters + 1 (The first parameter is the `original` closure. The rest is the same as method's). The hook closure parameters number is 3. The method parameters number is 4.")
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookInstead(targetClass: TestObject.self, selector: #selector(TestObject.sumFunc(a:b:)), closure: { original, a, b in
                let result = original(a, b, 100)
                return Int(result)
                } as @convention(block) ((Int, Int, Int) -> Int, Int, Int) -> Int as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {
            XCTAssertEqual(description, "For `instead` mode. The number of hook closure parameters should be equal to the number of method parameters + 1 (The first parameter is the `original` closure. The rest is the same as method's). The hook closure parameters number is 3. The method parameters number is 4.")
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookInstead(targetClass: TestObject.self, selector: #selector(TestObject.sumFunc(a:b:)), closure: { original, a, _ in
                let result = original(a)
                return Int(result)
                } as @convention(block) ((Int) -> Int, Int, Int) -> Int as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {
            XCTAssertEqual(description, "For `instead` mode. The number of hook closure parameters should be equal to the number of method parameters + 1 (The first parameter is the `original` closure. The rest is the same as method's). The hook closure parameters number is 3. The method parameters number is 4.")
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func test_Hook_Dealloc_With_Object_And_Selector() {
        do {
            try hookBefore(targetClass: ObjectiveCTestObject.self, selector: deallocSelector, closure: { original, o, s in
                original(o, s)
                } as @convention(block) ((AnyObject, Selector) -> Void, AnyObject, Selector) -> Void as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {
            // TODO: 这里的``其实应该换个描述，因为hook的是dealloc方法
            XCTAssertEqual(description, "For `befor` and `after` mode. The parameters type of the hook closure must be the same as method's. The closure parameters type is `@?@:`. But the method parameters type is ``. They are not the same.")
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookAfter(object: ObjectiveCTestObject(), selector: deallocSelector, closure: { original, o, s in
                original(o, s)
                } as @convention(block) ((AnyObject, Selector) -> Void, AnyObject, Selector) -> Void as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {// TODO: 这里的``其实应该换个描述，因为hook的是dealloc方法
            XCTAssertEqual(description, "For `befor` and `after` mode. The parameters type of the hook closure must be the same as method's. The closure parameters type is `@?@:`. But the method parameters type is ``. They are not the same.")
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookInstead(targetClass: ObjectiveCTestObject.self, selector: deallocSelector, closure: { original, o, s in
                original(o, s)
                } as @convention(block) ((AnyObject, Selector) -> Void, AnyObject, Selector) -> Void as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {
            XCTAssertEqual(description, "For `instead` mode. The number of hook closure parameters should be equal to the number of method parameters + 1 (The first parameter is the `original` closure. The rest is the same as method's). The hook closure parameters number is 3. The method parameters number is 0.")
        } catch {
            XCTAssertNil(error)
        }
        do {
            try hookInstead(object: ObjectiveCTestObject(), selector: deallocSelector, closure: { original, o, s in
                original(o, s)
                } as @convention(block) ((AnyObject, Selector) -> Void, AnyObject, Selector) -> Void as AnyObject)
            XCTFail()
        } catch SwiftHookError.incompatibleClosureSignature(description: let description) {
            XCTAssertEqual(description, "For `instead` mode. The number of hook closure parameters should be equal to the number of method parameters + 1 (The first parameter is the `original` closure. The rest is the same as method's). The hook closure parameters number is 3. The method parameters number is 0.")
        } catch {
            XCTAssertNil(error)
        }
    }
}
