//
//  COSLTestStuff.m
//  yd
//
//  Created by August Mueller on 8/26/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import "COSLTestStuff.h"

#define debug NSLog

BOOL COSLTestStuffTestPassed;

@implementation COSLTestStuff

@end


void COSLMethodNoArgsNoReturn(void) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}


void COSLSingleArgument(id obj) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    COSLTestStuffTestPassed = YES;
}

id COSLMethodNoArgsIDReturn(void) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    COSLTestStuffTestPassed = YES;
    return @"COSLMethodNoArgsIDReturn Method Return Value";
}


NSString * COSLMethodStringArgStringReturn(NSString *s) {
    COSLTestStuffTestPassed = YES;
    return [NSString stringWithFormat:@"!!%@!!", s];
}

NSString * COSLMethodStringSringArgStringReturn(NSString *a, NSString *b) {
    COSLTestStuffTestPassed = YES;
    return [NSString stringWithFormat:@"++!!%@.%@!!", a, b];
}

void COSLMethodPleasePassNSNumber3(NSNumber *n) {
    COSLTestStuffTestPassed = [n isKindOfClass:[NSNumber class]] && [n integerValue] == 3;
}

NSDictionary * COSLMethodReturnNSDictionary(void) {
    return @{@"theKey": @(42)};
}
void COSLMethodCheckNSDictionary(NSDictionary *d) {
    
    NSNumber *n = [d objectForKey:@"theKey"];
    COSLTestStuffTestPassed = [n isKindOfClass:[NSNumber class]] && [n integerValue] == 42;
}


