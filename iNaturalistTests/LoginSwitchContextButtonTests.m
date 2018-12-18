//
//  LoginSwitchContextButtonTests.m
//  iNaturalistTests
//
//  Created by Alex Shepard on 3/26/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LoginSwitchContextButton.h"

@interface LoginSwitchContextButtonTests : XCTestCase {
    LoginSwitchContextButton *button;
}
@end

@implementation LoginSwitchContextButtonTests

- (void)setUp {
    [super setUp];
    
    button = [[LoginSwitchContextButton alloc] init];
    
    // fake -awakeFromNib
    [button awakeFromNib];
}

- (void)tearDown {
    button = nil;
    
    [super tearDown];
}

- (void)testInitialState {
    XCTAssertNotNil(button.currentAttributedTitle.string, @"Initial title shouldn't be nil");
    XCTAssertTrue([button.currentAttributedTitle.string containsString:@"Account"], @"Initial title should contain the text 'Account' - ie it should be in Sign Up context. May fail if tests are run in non-english environment");
}

- (void)testSetContext {
    [button setContext:LoginContextSignup];
    XCTAssertTrue([button.currentAttributedTitle.string containsString:@"Account"], @"After setting context to signup, title should contain the text 'Account' - ie it should be in signup context. May fail if tests are run in non-english environment");

    [button setContext:LoginContextLogin];
    XCTAssertTrue([button.currentAttributedTitle.string containsString:@"Sign up"], @"After setting context to login, title should contain the text 'Sign up' - ie it should be in login context. May fail if tests are run in non-english environment");
}

@end
