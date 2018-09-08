//
//  COSLFFI.m
//  yd
//
//  Created by August Mueller on 8/22/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import "COSLFFI.h"
#import "COSLJSWrapper.h"
#import "COSLRuntime.h"
#import <objc/runtime.h>
#import <dlfcn.h>

@interface COSLFFI ()
@property (weak) COSLJSWrapper *f;
@property (weak) COSLJSWrapper *caller;
@property (strong) NSArray *args;
@property (weak) COSLRuntime *runtime;
@end

@implementation COSLFFI


+ (instancetype)ffiWithFunction:(COSLJSWrapper*)f caller:(nullable COSLJSWrapper*)caller arguments:(NSArray*)args cos:(COSLRuntime*)cos {
    
    COSLFFI *ffi = [COSLFFI new];
    [ffi setF:f];
    [ffi setCaller:caller];
    [ffi setArgs:args];
    [ffi setRuntime:cos];
    
    return ffi;
}

- (nullable COSLJSWrapper*)objcInvoke {
    assert([_caller instance]);
    COSLSymbol *functionSymbol = [_f symbol];
    assert(functionSymbol);
    NSString *methodName = [functionSymbol name];
    COSLJSWrapper *returnWrapper = nil;
    
    @try {
        
        SEL selector = NSSelectorFromString(methodName);
        
        id object = [_caller instance];
        
        NSMethodSignature *methodSignature = [object methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];

//        [invocation retainArguments]; // need to do this for release builds, because it seems ARC likes to let go of our strings early otherwise.
//
        [invocation setTarget:object];
        [invocation setSelector:selector];
        
        
        NSUInteger methodArgumentCount = [methodSignature numberOfArguments] - 2;
        if (methodArgumentCount != [_args count]) {
            NSString *reason = [NSString stringWithFormat:@"ObjC method %@ requires %lu %@, but JavaScript passed %zd %@", NSStringFromSelector(selector), methodArgumentCount, (methodArgumentCount == 1 ? @"argument" : @"arguments"), [_args count], ([_args count] == 1 ? @"argument" : @"arguments")];
            assert(NO);
//            NSException *e = [NSException exceptionWithName:MORuntimeException reason:reason userInfo:nil];
//            if (exception != NULL) {
//                *exception = [runtime JSValueForObject:e];
//            }
//            return NULL;
        }
        
    // TODO: set arguments.
        
        // Invoke
        [invocation invoke];
        
        const char * returnType = [methodSignature methodReturnType];
        JSValueRef returnValue = NULL;
        if (strcmp(returnType, @encode(void)) == 0) {
            returnValue = JSValueMakeUndefined([_runtime contextRef]);
            returnWrapper = [COSLJSWrapper wrapperForJSObject:(JSObjectRef)returnValue runtime:_runtime];
        }
        // id
        else if (strcmp(returnType, @encode(id)) == 0
                 || strcmp(returnType, @encode(Class)) == 0) {
            id object = nil;
            [invocation getReturnValue:&object];
            
            CFRetain((CFTypeRef)object);
            
            returnWrapper = [COSLJSWrapper wrapperWithInstance:object runtime:_runtime];
            
        }
        
    }
    @catch (NSException *e) {
        
        assert(NO);
        return NULL;
    }
    
    return returnWrapper;
}


- (nullable COSLJSWrapper*)callFunction {
    
    assert(_f);
    assert([_f isFunction] || [_f isClassMethod] || [_f isInstanceMethod]);
    
    if ([_f isClassMethod] || [_f isInstanceMethod]) {
        return [self objcInvoke];
    }
    
    COSLSymbol *functionSymbol = [_f symbol];
    assert(functionSymbol);
    
    NSString *functionName = [functionSymbol name];
    
    void *callAddress = dlsym(RTLD_DEFAULT, [functionName UTF8String]);

    assert(callAddress);
    
    COSLJSWrapper *returnWrapper = [functionSymbol returnValue] ? [COSLJSWrapper wrapperWithSymbol:[functionSymbol returnValue] runtime:_runtime] : nil;
    
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
                [arg pushJSValueToNativeType:[argSym runtimeType]];
                [arg setSymbol:argSym];
            }
            
            args[idx]   = [arg FFIType];
            values[idx] = [arg objectStorage];
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
    
    if (effectiveArgumentCount > 0) {
        free(args);
        free(values);
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


