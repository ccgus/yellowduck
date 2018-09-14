//
//  FJSTestStuff.m
//  yd
//
//  Created by August Mueller on 8/26/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import "FJSTestStuff.h"

#define debug NSLog

BOOL FJSTestStuffTestPassed;

@implementation FJSTestStuff

@end


void FJSMethodNoArgsNoReturn(void) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}


void FJSSingleArgument(id obj) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    FJSTestStuffTestPassed = YES;
}

id FJSMethodNoArgsIDReturn(void) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    FJSTestStuffTestPassed = YES;
    return @"FJSMethodNoArgsIDReturn Method Return Value";
}


NSString * FJSMethodStringArgStringReturn(NSString *s) {
    FJSTestStuffTestPassed = YES;
    return [NSString stringWithFormat:@"!!%@!!", s];
}

NSString * FJSMethodStringSringArgStringReturn(NSString *a, NSString *b) {
    FJSTestStuffTestPassed = YES;
    return [NSString stringWithFormat:@"++!!%@.%@!!", a, b];
}

void FJSMethodPleasePassNSNumber3(NSNumber *n) {
    FJSTestStuffTestPassed = [n isKindOfClass:[NSNumber class]] && [n integerValue] == 3;
}


void FJSMethodPleasePassSignedShortNumber3(short n) {
    FJSTestStuffTestPassed = n == 3;
}

void FJSMethodPleasePassUnsignedShortNumber3(unsigned short n) {
    FJSTestStuffTestPassed = n == 3;
}

void FJSMethodPleasePassSignedIntNumber3(int n) {
    FJSTestStuffTestPassed = n == 3;
}

void FJSMethodPleasePassUnsignedIntNumber3(uint n) {
    FJSTestStuffTestPassed = n == 3;
}

void FJSMethodPleasePassSignedLongNumber3(long n) {
    FJSTestStuffTestPassed = n == 3;
}

void FJSMethodPleasePassUnsignedLongNumber3(unsigned long n) {
    FJSTestStuffTestPassed = n == 3;
}

void FJSMethodPleasePassSignedLongLongNumber3(long long n) {
    FJSTestStuffTestPassed = n == 3;
}

void FJSMethodPleasePassUnsignedLongLongNumber3(unsigned long long n) {
    FJSTestStuffTestPassed = n == 3;
}

void FJSMethodPleasePassCCharM(char c) {
    FJSTestStuffTestPassed = c == 'm';
}

void FJSMethodPleasePassUnsignedCCharM(unsigned char c) {
    FJSTestStuffTestPassed = c == 'm';
}

NSDictionary * FJSMethodReturnNSDictionary(void) {
    return @{@"theKey": @(42)};
}
void FJSMethodCheckNSDictionary(NSDictionary *d) {
    
    NSNumber *n = [d objectForKey:@"theKey"];
    FJSTestStuffTestPassed = [n isKindOfClass:[NSNumber class]] && [n integerValue] == 42;
}


