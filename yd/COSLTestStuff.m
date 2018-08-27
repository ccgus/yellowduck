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


void COSLSingleMethod(void) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}


void COSLSingleArgument(id obj) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}

id COSLReturnObject(void) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return @"COSLReturnObject Method Return Value";
}
