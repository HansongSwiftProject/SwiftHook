//
//  InstanceAfterTests.m
//  AspectsTests
//
//  Created by Yanni Wang on 4/10/19.
//  Copyright © 2019 Yanni. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Aspects.h"
#import "TestObjects/TestObject.h"

@interface InstanceAfterTests : XCTestCase

@end

@implementation InstanceAfterTests

- (void)testTriggered
{
    NSError *error = nil;
    TestObject *obj = [[TestObject alloc] init];
    __block BOOL triggered = NO;
    
    [obj aspect_hookSelector:@selector(methodWithExecuted:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info){
        triggered = YES;
    } error:&error];
    XCTAssert(error == nil);
    
    XCTAssert(triggered == NO);
    [obj methodWithExecuted:NULL];
    XCTAssert(triggered == YES);
}

- (void)testOrder
{
    NSError *error = nil;
    TestObject *obj = [[TestObject alloc] init];
    __block BOOL executed = NO;
    
    [obj aspect_hookSelector:@selector(methodWithExecuted:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info){
        XCTAssert(executed == YES);
    } error:&error];
    XCTAssert(error == nil);
    
    [obj methodWithExecuted:&executed];
    XCTAssert(executed == YES);
}

@end