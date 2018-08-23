//
//  COSLFFI.m
//  yd
//
//  Created by August Mueller on 8/22/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import "COSLFFI.h"
#import "COSLJSWrapper.h"
#import "COScriptLite.h"

@interface COSLFFI ()
@property (weak) COSLJSWrapper *f;
@property (weak) COSLJSWrapper *caller;
@property (strong) NSArray *args;
@property (weak) COScriptLite *cos;
@end

@implementation COSLFFI


+ (instancetype)ffiWithFunction:(COSLJSWrapper*)f caller:(nullable COSLJSWrapper*)caller arguments:(NSArray*)args cos:(COScriptLite*)cos {
    
    COSLFFI *ffi = [COSLFFI new];
    [ffi setF:f];
    [ffi setCaller:caller];
    [ffi setArgs:args];
    [ffi setCos:cos];
    
    return ffi;
}

- (nullable COSLJSWrapper*)callFunction {
    
    COSLJSWrapper *ret = [COSLJSWrapper wrapperInCOS:_cos];
    
    return ret;
}

@end
