//
//  FJSFFI.m
//  yd
//
//  Created by August Mueller on 8/22/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import "FJSFFI.h"
#import "FJSValue.h"
#import "FJSRuntime.h"
#import "FJSUtil.h"
#import <objc/runtime.h>
#import <dlfcn.h>

@interface FJSFFI ()
@property (weak) FJSValue *f;
@property (weak) FJSValue *caller;
@property (strong) NSArray *args;
@property (weak) FJSRuntime *runtime;
@end

@implementation FJSFFI


+ (instancetype)ffiWithFunction:(FJSValue*)f caller:(nullable FJSValue*)caller arguments:(NSArray*)args cos:(FJSRuntime*)cos {
    
    FJSFFI *ffi = [FJSFFI new];
    [ffi setF:f];
    [ffi setCaller:caller];
    [ffi setArgs:args];
    [ffi setRuntime:cos];
    
    return ffi;
}

- (nullable FJSValue*)objcInvoke {
    assert([_caller cValue].value.pointerValue);
    FJSSymbol *functionSymbol = [_f symbol];
    assert(functionSymbol);
    NSString *methodName = [functionSymbol name];
    FJSValue *returnWrapper = nil;
    
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
            debug(@"reason: '%@'", reason);
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
        
        const char *returnType = [methodSignature methodReturnType];
        JSValueRef returnValue = NULL;
        if (FJSCharEquals(returnType, @encode(void))) {
            returnValue = JSValueMakeUndefined([_runtime contextRef]);
            returnWrapper = [FJSValue wrapperForJSObject:(JSObjectRef)returnValue runtime:_runtime];
        }
        // id
        else if (FJSCharEquals(returnType, @encode(id)) || FJSCharEquals(returnType, @encode(Class))) {
            id object = nil;
            [invocation getReturnValue:&object];
            
            CFRetain((CFTypeRef)object);
            
            FMAssert(_runtime);
            
            returnWrapper = [FJSValue wrapperWithInstance:object runtime:_runtime];
            
        }
        
    }
    @catch (NSException *e) {
        
        assert(NO);
        return NULL;
    }
    
    return returnWrapper;
}


- (nullable FJSValue*)callFunction {
    
    assert(_f);
    assert([_f isFunction] || [_f isClassMethod] || [_f isInstanceMethod]);
    
    if ([_f isClassMethod] || [_f isInstanceMethod]) {
        return [self objcInvoke];
    }
    
    FJSSymbol *functionSymbol = [_f symbol];
    assert(functionSymbol);
    
    NSString *functionName = [functionSymbol name];
    
    void *callAddress = dlsym(RTLD_DEFAULT, [functionName UTF8String]);

    assert(callAddress);
    FMAssert(_runtime);
    
    FJSValue *returnValue = [functionSymbol returnValue] ? [FJSValue wrapperWithSymbol:[functionSymbol returnValue] runtime:_runtime] : nil;
    
    // Prepare ffi
    ffi_cif cif;
    ffi_type** ffiArgs = NULL;
    void** ffiValues = NULL;
    
    // Build the arguments
    unsigned int effectiveArgumentCount = (unsigned int)[_args count];

    if (effectiveArgumentCount > 0) {
        ffiArgs = malloc(sizeof(ffi_type *) * effectiveArgumentCount);
        ffiValues = malloc(sizeof(void *) * effectiveArgumentCount);
        
        
        for (NSInteger idx = 0; idx < [_args count]; idx++) {
            FJSValue *arg = [_args objectAtIndex:idx];
            FJSSymbol *argSym = [[[_f symbol] arguments] objectAtIndex:idx];
            
            assert(argSym);
            
            if ([arg isJSNative]) {
                // Convert this to the argSymTupe?
                [arg pushJSValueToNativeType:[argSym runtimeType]];
                [arg setSymbol:argSym];
            }
            
            ffiArgs[idx]   = [arg FFITypeWithHint:[argSym runtimeType]];
            ffiValues[idx] = [arg objectStorage];
        }
    }
    
    ffi_type *returnType = returnValue ? [returnValue FFIType] : &ffi_type_void;
    
    ffi_status prep_status = ffi_prep_cif(&cif, FFI_DEFAULT_ABI, effectiveArgumentCount, returnType, ffiArgs);
    
    // Call
    if (prep_status == FFI_OK) {
        void *returnStorage = [returnValue objectStorage];
        
        @try {
            ffi_call(&cif, callAddress, returnStorage, ffiValues);
            
            [returnValue retainReturnValue];
            
        }
        @catch (NSException *e) {
            debug(@"shit: %@", e);
            returnValue = nil;
        }
    }
    
    if (effectiveArgumentCount > 0) {
        free(ffiArgs);
        free(ffiValues);
    }
    
    return returnValue;
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


