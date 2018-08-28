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
#import <objc/runtime.h>
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
    
    COSLSymbol *functionSymbol = [_f symbol];
    assert(functionSymbol);
    
    NSString *functionName = [functionSymbol name];
    
    void *callAddress = dlsym(RTLD_DEFAULT, [functionName UTF8String]);

    assert(callAddress);
    
    COSLJSWrapper *returnWrapper = [functionSymbol returnValue] ? [COSLJSWrapper wrapperWithSymbol:[functionSymbol returnValue] cos:_cos] : nil;
    
    BOOL objCCall = NO;
    
    // Prepare ffi
    ffi_cif cif;
    ffi_type** args = NULL;
    void** values = NULL;
    
    
    // Build the arguments
    unsigned int effectiveArgumentCount = (unsigned int)[_args count];
    if (objCCall) {
        effectiveArgumentCount += 2;
    }

    if (effectiveArgumentCount > 0) {
        args = malloc(sizeof(ffi_type *) * effectiveArgumentCount);
        values = malloc(sizeof(void *) * effectiveArgumentCount);
        
        
        for (NSInteger idx = 0; idx < [_args count]; idx++) {
            COSLJSWrapper *arg = [_args objectAtIndex:idx];
            COSLSymbol *argSym = [[[_f symbol] arguments] objectAtIndex:idx];
            
            assert(argSym);
            
            if ([arg isJSNative]) {
                // Convert this to the argSymTupe?
            }
            
            //args[idx] = [arg FFIType];
            //values[j] = [arg storage];
            idx++;
        }
        
        
    }
    
    ffi_type *returnType = returnWrapper ? [returnWrapper FFIType] : &ffi_type_void;
    
    ffi_status prep_status = ffi_prep_cif(&cif, FFI_DEFAULT_ABI, effectiveArgumentCount, returnType, args);
    
    // Call
    if (prep_status == FFI_OK) {
        void *returnStorage = [returnWrapper objectStorage];
        
        @try {
            ffi_call(&cif, callAddress, returnStorage, values);
            
            
            if (returnWrapper) {
                
                if ([returnWrapper instance]) {
                    
                    // Yes, this only works for objc types. I'm building things up here…
                    // Also, I'm in a pizza coma right now zzzzzzz
                    CFRetain((CFTypeRef)[returnWrapper instance]);
                }
                else {
                    debug(@"got a void return on a function that was supposed to return a value.");
                }
            }
            
            
        }
        @catch (NSException *e) {
            debug(@"shit: %@", e);
            if (effectiveArgumentCount > 0) {
                free(args);
                free(values);
            }
            
            return NULL;
        }
    }
    
    return returnWrapper;
}

+ (ffi_type *)ffiTypeAddressForTypeEncoding:(char)encoding {
    switch (encoding) {
        case _C_ID:
        case _C_CLASS:
        case _C_SEL:
        case _C_PTR:
        case _C_CHARPTR:    return &ffi_type_pointer;
        case _C_CHR:        return &ffi_type_sint8;
        case _C_UCHR:       return &ffi_type_uint8;
        case _C_SHT:        return &ffi_type_sint16;
        case _C_USHT:       return &ffi_type_uint16;
        case _C_INT:
        case _C_LNG:        return &ffi_type_sint32;
        case _C_UINT:
        case _C_ULNG:       return &ffi_type_uint32;
        case _C_LNG_LNG:    return &ffi_type_sint64;
        case _C_ULNG_LNG:   return &ffi_type_uint64;
        case _C_FLT:        return &ffi_type_float;
        case _C_DBL:        return &ffi_type_double;
        case _C_BOOL:       return &ffi_type_sint8;
        case _C_VOID:       return &ffi_type_void;
    }
    return nil;
}

@end


