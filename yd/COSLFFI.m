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
#import <ffi/ffi.h>
#import <dlfcn.h>

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
    
    assert(_f);
    assert([_f isFunction]);
    
    NSString *functionName = [[_f symbol] name];
    
    void *callAddress = dlsym(RTLD_DEFAULT, [functionName UTF8String]);

    assert(callAddress);
    
    COSLJSWrapper *ret = [COSLJSWrapper wrapperInCOS:_cos];
    
    BOOL objCCall = NO;
    BOOL blockCall = NO;
    
    // Prepare ffi
    ffi_cif cif;
    ffi_type** args = NULL;
    void** values = NULL;
    
    
    // Build the arguments
    unsigned int effectiveArgumentCount = (unsigned int)[_args count];
    if (objCCall) {
        effectiveArgumentCount += 2;
    }
    if (blockCall) {
        effectiveArgumentCount += 1;
    }
    
    if (effectiveArgumentCount > 0) {
        args = malloc(sizeof(ffi_type *) * effectiveArgumentCount);
        values = malloc(sizeof(void *) * effectiveArgumentCount);
    }
    fffffffff not tonight
    ffi_status prep_status = ffi_prep_cif(&cif, FFI_DEFAULT_ABI, effectiveArgumentCount, &ffi_type_pointer, args);
    
    // Call
    if (prep_status == FFI_OK) {
        void *storage = [ret objectStorage];
        
        @try {
            ffi_call(&cif, callAddress, storage, values);
            CFRetain((CFTypeRef)[ret instance]);
        }
        @catch (NSException *e) {
//            if (effectiveArgumentCount > 0) {
//                free(args);
//                free(values);
//            }
//            if (exception != NULL) {
//                *exception = [runtime JSValueForObject:e];
//            }
//            return NULL;
        }
    }
    
    return ret;
}

@end
