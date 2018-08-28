//
//  COSLTestStuff.m
//  yd
//
//  Created by August Mueller on 8/26/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import "COSLTestStuff.h"

#define debug NSLog

@implementation COSLTestStuff

@end


void COSLMethodNoArgsNoReturn(void) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}


void COSLSingleArgument(id obj) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}

id COSLMethodNoArgsIDReturn(void) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return @"COSLMethodNoArgsIDReturn Method Return Value";
}


NSString * COSLMethodStringArgStringReturn(NSString *s) {
    return [NSString stringWithFormat:@"!!%@!!", s];
}


