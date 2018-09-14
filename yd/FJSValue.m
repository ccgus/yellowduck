//
//  FJSJSWrapper.m
//  yd
//
//  Created by August Mueller on 8/21/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import "FJSValue.h"
#import "FJSFFI.h"
#import "FJSUtil.h"

#import <objc/runtime.h>

#define debug NSLog
#define DEBUG

@interface FJSValue ()

@property (weak) FJSRuntime *runtime;
@property (assign) Class class;
@property (assign) SEL instanceSelector;
@property (assign) SEL classSelector;
@property (assign) JSObjectRef nativeJSObj;

@end

@implementation FJSValue

- (void)dealloc {
    //NSLog(@"%s:%d", __FUNCTION__, __LINE__);
}


+ (instancetype)wrapperForJSObject:(nullable JSObjectRef)jso runtime:(FJSRuntime*)runtime {
    
    if (!jso) {
        return nil;
    }
    
    if (JSValueIsObject([[runtime jscContext] JSGlobalContextRef], jso)) {
        FJSValue *wr = (__bridge FJSValue *)(JSObjectGetPrivate(jso));
        if (wr) {
            return wr;
        }
    }
    
    FJSValue *native = [FJSValue new];
    [native setNativeJSObj:jso];
    [native setIsJSNative:YES];
    [native setRuntime:runtime];
    
    return native;
}

+ (instancetype)wrapperWithSymbol:(FJSSymbol*)sym runtime:(FJSRuntime*)runtime {
    
    FJSValue *cw = [[self alloc] init];
    [cw setSymbol:sym];
    [cw setRuntime:runtime];
    
    return cw;
}

+ (instancetype)wrapperWithClass:(Class)c runtime:(FJSRuntime*)runtime {
    FJSValue *cw = [[self alloc] init];
    [cw setClass:c];
    [cw setRuntime:runtime];
    
    return cw;
}

+ (instancetype)wrapperWithInstance:(id)instance runtime:(FJSRuntime*)runtime {
    FJSValue *cw = [[self alloc] init];
    [cw setInstance:instance];
    [cw setRuntime:runtime];
    
    return cw;
    
}

+ (instancetype)wrapperWithInstanceMethod:(SEL)selector {
    FJSValue *cw = [[self alloc] init];
    [cw setInstanceSelector:selector];
    
    return cw;
}

+ (instancetype)wrapperWithClassMethod:(SEL)selector {
    FJSValue *cw = [[self alloc] init];
    [cw setClassSelector:selector];
    
    return cw;
    
}

- (BOOL)isClass {
    return _class != nil;
}

- (BOOL)isInstance {
    return _instance != nil;
}
    
- (BOOL)isInstanceMethod {
    return [[_symbol symbolType] isEqualToString:@"method"];
}

- (BOOL)isClassMethod {
    return [[_symbol symbolType] isEqualToString:@"method"] && [_symbol isClassMethod];
}

- (BOOL)isSymbol {
    return _symbol != nil;
}

- (BOOL)isFunction {
    return [[_symbol symbolType] isEqualToString:@"function"];
}

- (BOOL)hasClassMethodNamed:(NSString*)m {
    return [_class respondsToSelector:NSSelectorFromString(m)];
}

- (instancetype)wrapperForClassMethodNamed:(NSString*)m {
    
    assert(_class);
    
    FJSValue *w = [FJSValue new];
    [w setClassSelector:NSSelectorFromString(m)];
    [w setClass:_class];
    
    return w;
}

- (id)callMethod {
    
    return nil;
}

- (nullable JSValueRef)JSValue {
    
    if (_nativeJSObj) {
        return _nativeJSObj;
    }
    
    if (_instance) {
        
        JSValueRef vr = [FJSValue nativeObjectToJSValue:_instance inJSContext:[[_runtime jscContext] JSGlobalContextRef]];
        
        if (vr) {
            return vr;
        }
        
        FMAssert(_runtime);
        
        vr = [_runtime newJSValueForWrapper:self];
        
        FMAssert(vr);
        return vr;
    }
    
    return nil;
}

- (void*)objectStorage {
    
    if (_cValue.type) {
        return &_cValue.value;
    }
    
    return &_instance;
}

- (ffi_type*)FFIType {
    return [self FFITypeWithHint:nil];
}

- (ffi_type*)FFITypeWithHint:(nullable NSString*)typeEncoding {
    
    if (_symbol) {
        
        char c = [[_symbol runtimeType] characterAtIndex:0];
        
        if (c) {
            return [FJSFFI ffiTypeAddressForTypeEncoding:c];
        }
    }
    
    if ([typeEncoding isEqualToString:@"@"]) {
        return &ffi_type_pointer;
    }
    
    debug(@"NO SYMBOL IN WRAPPER: %@", self);
    
    if (_instance) {
        return &ffi_type_pointer;
    }
    
    return &ffi_type_void;
}

- (nullable JSValueRef)toJSString {
    // TODO: check for numbers, etc, and convert them to the right JS type
    debug(@"_instance: %@", _instance);
    JSStringRef string = JSStringCreateWithCFString((__bridge CFStringRef)[_instance description]);
    JSValueRef value = JSValueMakeString([[_runtime jscContext] JSGlobalContextRef], string);
    JSStringRelease(string);
    return value;
}

- (BOOL)pushJSValueToNativeType:(NSString*)type {
    
    if ([type isEqualToString:@"B"]) {
        _cValue.type = _C_BOOL;
        _cValue.value.boolValue = [[FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]] boolValue];
        return YES;
    }
    
    if ([type isEqualToString:@"s"]) {
        _cValue.type = _C_SHT;
        _cValue.value.shortValue = [[FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]] shortValue];
        return YES;
    }
    
    if ([type isEqualToString:@"S"]) {
        _cValue.type = _C_USHT;
        _cValue.value.ushortValue = [[FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]] unsignedShortValue];
        return YES;
    }
    
    if ([type isEqualToString:@"c"]) {
        _cValue.type = _C_CHR;
        _cValue.value.charValue = [[FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]] charValue];
        return YES;
    }
    
    if ([type isEqualToString:@"C"]) {
        _cValue.type = _C_UCHR;
        _cValue.value.ucharValue = [[FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]] unsignedCharValue];
        return YES;
    }
    
    if ([type isEqualToString:@"i"]) {
        _cValue.type = _C_INT;
        _cValue.value.intValue = [[FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]] intValue];
        return YES;
    }
    
    if ([type isEqualToString:@"I"]) {
        _cValue.type = _C_UINT;
        _cValue.value.uintValue = [[FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]] unsignedIntValue];
        return YES;
    }
    
    if ([type isEqualToString:@"l"]) {
        _cValue.type = _C_LNG;
        _cValue.value.longValue = [[FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]] longValue];
        return YES;
    }
    
    if ([type isEqualToString:@"L"]) {
        _cValue.type = _C_ULNG;
        _cValue.value.unsignedLongValue = [[FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]] unsignedLongValue];
        return YES;
    }
    
    if ([type isEqualToString:@"q"]) {
        _cValue.type = _C_LNG_LNG;
        _cValue.value.longLongValue = [[FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]] longLongValue];
        return YES;
    }
    
    if ([type isEqualToString:@"Q"]) {
        _cValue.type = _C_ULNG_LNG;
        _cValue.value.unsignedLongLongValue = [[FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]] unsignedLongLongValue];
        return YES;
    }
    
    _instance = [FJSValue nativeObjectFromJSValue:_nativeJSObj ofType:type inJSContext:[[_runtime jscContext] JSGlobalContextRef]];
    
    
    return _instance != nil;
}

+ (id)nativeObjectFromJSValue:(JSValueRef)jsValue ofType:(NSString*)typeEncoding inJSContext:(JSContextRef)context {
    
    debug(@"typeEncoding: '%@'", typeEncoding);
    
    if ([typeEncoding isEqualToString:@"@"]) {
        if (JSValueIsString(context, jsValue)) {
            JSStringRef resultStringJS = JSValueToStringCopy(context, jsValue, NULL);
            id o = (NSString *)CFBridgingRelease(JSStringCopyCFString(kCFAllocatorDefault, resultStringJS));
            JSStringRelease(resultStringJS);
            return o;
        }
        
        
        if (JSValueIsNumber(context, jsValue)) {
            double v = JSValueToNumber(context, jsValue, NULL);
            return @(v);
        }
        
        if (JSValueIsBoolean(context, jsValue)) {
            bool v = JSValueToBoolean(context, jsValue);
            return @(v);
        }
        
    }
    
    if ([typeEncoding isEqualToString:@"B"]) {
        bool v = JSValueToBoolean(context, jsValue);
        return @(v);
    }
    
    if ([typeEncoding isEqualToString:@"s"]) {
        short v = JSValueToNumber(context, jsValue, NULL);
        return @(v);
    }
    
    if ([typeEncoding isEqualToString:@"S"]) {
        unsigned short v = JSValueToNumber(context, jsValue, NULL);
        return @(v);
    }
    
    if ([typeEncoding isEqualToString:@"i"]) {
        int v = JSValueToNumber(context, jsValue, NULL);
        return @(v);
    }
    
    if ([typeEncoding isEqualToString:@"I"]) {
        uint v = JSValueToNumber(context, jsValue, NULL);
        return @(v);
    }
    
    
    if ([typeEncoding isEqualToString:@"l"]) {
        long v = JSValueToNumber(context, jsValue, NULL);
        return @(v);
    }
    
    if ([typeEncoding isEqualToString:@"L"]) {
        unsigned long v = JSValueToNumber(context, jsValue, NULL);
        return @(v);
    }
    
    
    if ([typeEncoding isEqualToString:@"q"]) {
        long long v = JSValueToNumber(context, jsValue, NULL);
        return @(v);
    }
    
    if ([typeEncoding isEqualToString:@"Q"]) {
        unsigned long long v = JSValueToNumber(context, jsValue, NULL);
        return @(v);
    }
    
    if ([typeEncoding isEqualToString:@"c"]) { // _C_CHR
        
        NSString *f = [self nativeObjectFromJSValue:jsValue ofType:@"@" inJSContext:context];
        if ([f length]) {
            char c = [f UTF8String][0];
            NSNumber *n = @(c);
            FMAssert(FJSCharEquals([n objCType], @encode(char)));
            return n;
        }
        
        return nil;
    }
    
    if ([typeEncoding isEqualToString:@"C"]) { // _C_UCHR
        
        NSString *f = [self nativeObjectFromJSValue:jsValue ofType:@"@" inJSContext:context];
        if ([f length]) {
            char c = [f UTF8String][0];
            NSNumber *n = @(c);
            FMAssert(FJSCharEquals([n objCType], @encode(char)));
#ifdef DEBUG
            
//            printf("@encode(short) %s, %s, %c, %lu\n", @encode(short), [[NSNumber numberWithShort:'a'] objCType], _C_SHT, sizeof(short));
//            printf("@encode(char) %s, %s, %c, %lu\n",     @encode(char),  [[NSNumber numberWithChar:'a'] objCType], _C_CHR, sizeof(char));
//            printf("@encode(unsigned char) %s, %s, %c, %lu\n", @encode(unsigned char), [[NSNumber numberWithUnsignedChar:'a'] objCType], _C_UCHR, sizeof(unsigned char));
            
            // NSNumber stores shorts and unsigned chars the same. Really!
            FMAssert(@encode(unsigned char) != @encode(short));
            FMAssert(@encode(unsigned char) == @encode(unsigned char));
            FMAssert([[NSNumber numberWithUnsignedChar:'a'] objCType] == [[NSNumber numberWithShort:'a'] objCType]);
            FMAssert([[NSNumber numberWithUnsignedChar:'a'] isEqualToNumber:[NSNumber numberWithShort:'a']]);
#endif
            return n;
        }
        
        return nil;
    }
    
    assert(NO);
    
    return nil;
}

+ (JSValueRef)nativeObjectToJSValue:(id)o inJSContext:(JSContextRef)context {
    
    if ([o isKindOfClass:[NSString class]]) {
        
        JSStringRef string = JSStringCreateWithCFString((__bridge CFStringRef)o);
        JSValueRef value = JSValueMakeString(context, string);
        JSStringRelease(string);
        return value;
    }
    
    else if ([o isKindOfClass:[NSNumber class]]) {
        
        if (FJSCharEquals([o objCType], @encode(BOOL))) {
            return JSValueMakeBoolean(context, [o boolValue]);
        }
        else {
            return JSValueMakeNumber(context, [o doubleValue]);
        }
    }
    
    
    return nil;
}


#pragma mark -
#pragma mark Type Encodings Stolen from Mocha

/*
 * __alignOf__ returns 8 for double, but its struct align is 4
 * use dummy structures to get struct alignment, each having a byte as first element
 */
typedef struct { char a; void* b; } struct_C_ID;
typedef struct { char a; char b; } struct_C_CHR;
typedef struct { char a; short b; } struct_C_SHT;
typedef struct { char a; int b; } struct_C_INT;
typedef struct { char a; long b; } struct_C_LNG;
typedef struct { char a; long long b; } struct_C_LNG_LNG;
typedef struct { char a; float b; } struct_C_FLT;
typedef struct { char a; double b; } struct_C_DBL;
typedef struct { char a; BOOL b; } struct_C_BOOL;

+ (BOOL)getAlignment:(size_t *)alignmentPtr ofTypeEncoding:(char)encoding {
    BOOL success = YES;
    size_t alignment = 0;
    switch (encoding) {
        case _C_ID:         alignment = offsetof(struct_C_ID, b); break;
        case _C_CLASS:      alignment = offsetof(struct_C_ID, b); break;
        case _C_SEL:        alignment = offsetof(struct_C_ID, b); break;
        case _C_CHR:        alignment = offsetof(struct_C_CHR, b); break;
        case _C_UCHR:       alignment = offsetof(struct_C_CHR, b); break;
        case _C_SHT:        alignment = offsetof(struct_C_SHT, b); break;
        case _C_USHT:       alignment = offsetof(struct_C_SHT, b); break;
        case _C_INT:        alignment = offsetof(struct_C_INT, b); break;
        case _C_UINT:       alignment = offsetof(struct_C_INT, b); break;
        case _C_LNG:        alignment = offsetof(struct_C_LNG, b); break;
        case _C_ULNG:       alignment = offsetof(struct_C_LNG, b); break;
        case _C_LNG_LNG:    alignment = offsetof(struct_C_LNG_LNG, b); break;
        case _C_ULNG_LNG:   alignment = offsetof(struct_C_LNG_LNG, b); break;
        case _C_FLT:        alignment = offsetof(struct_C_FLT, b); break;
        case _C_DBL:        alignment = offsetof(struct_C_DBL, b); break;
        case _C_BOOL:       alignment = offsetof(struct_C_BOOL, b); break;
        case _C_PTR:        alignment = offsetof(struct_C_ID, b); break;
        case _C_CHARPTR:    alignment = offsetof(struct_C_ID, b); break;
        default:            success = NO; break;
    }
    if (success && alignmentPtr != NULL) {
        *alignmentPtr = alignment;
    }
    return success;
}

+ (BOOL)getSize:(size_t *)sizePtr ofTypeEncoding:(char)encoding {
    BOOL success = YES;
    size_t size = 0;
    switch (encoding) {
        case _C_ID:         size = sizeof(id); break;
        case _C_CLASS:      size = sizeof(Class); break;
        case _C_SEL:        size = sizeof(SEL); break;
        case _C_PTR:        size = sizeof(void*); break;
        case _C_CHARPTR:    size = sizeof(char*); break;
        case _C_CHR:        size = sizeof(char); break;
        case _C_UCHR:       size = sizeof(unsigned char); break;
        case _C_SHT:        size = sizeof(short); break;
        case _C_USHT:       size = sizeof(unsigned short); break;
        case _C_INT:        size = sizeof(int); break;
        case _C_LNG:        size = sizeof(long); break;
        case _C_UINT:       size = sizeof(unsigned int); break;
        case _C_ULNG:       size = sizeof(unsigned long); break;
        case _C_LNG_LNG:    size = sizeof(long long); break;
        case _C_ULNG_LNG:   size = sizeof(unsigned long long); break;
        case _C_FLT:        size = sizeof(float); break;
        case _C_DBL:        size = sizeof(double); break;
        case _C_BOOL:       size = sizeof(bool); break;
        case _C_VOID:       size = sizeof(void); break;
        default:            success = NO; break;
    }
    if (success && sizePtr != NULL) {
        *sizePtr = size;
    }
    return success;
}

+ (ffi_type *)ffiTypeForTypeEncoding:(char)encoding {
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
    return NULL;
}

+ (NSString *)descriptionOfTypeEncoding:(char)encoding {
    switch (encoding) {
        case _C_ID:         return @"id";
        case _C_CLASS:      return @"Class";
        case _C_SEL:        return @"SEL";
        case _C_PTR:        return @"void*";
        case _C_CHARPTR:    return @"char*";
        case _C_CHR:        return @"char";
        case _C_UCHR:       return @"unsigned char";
        case _C_SHT:        return @"short";
        case _C_USHT:       return @"unsigned short";
        case _C_INT:        return @"int";
        case _C_LNG:        return @"long";
        case _C_UINT:       return @"unsigned int";
        case _C_ULNG:       return @"unsigned long";
        case _C_LNG_LNG:    return @"long long";
        case _C_ULNG_LNG:   return @"unsigned long long";
        case _C_FLT:        return @"float";
        case _C_DBL:        return @"double";
        case _C_BOOL:       return @"bool";
        case _C_VOID:       return @"void";
        case _C_UNDEF:      return @"(unknown)";
    }
    return nil;
}

+ (NSString *)descriptionOfTypeEncoding:(char)typeEncoding fullTypeEncoding:(NSString *)fullTypeEncoding {
    switch (typeEncoding) {
        case _C_VOID:       return @"void";
        case _C_ID:         return @"id";
        case _C_CLASS:      return @"Class";
        case _C_CHR:        return @"char";
        case _C_UCHR:       return @"unsigned char";
        case _C_SHT:        return @"short";
        case _C_USHT:       return @"unsigned short";
        case _C_INT:        return @"int";
        case _C_UINT:       return @"unsigned int";
        case _C_LNG:        return @"long";
        case _C_ULNG:       return @"unsigned long";
        case _C_LNG_LNG:    return @"long long";
        case _C_ULNG_LNG:   return @"unsigned long long";
        case _C_FLT:        return @"float";
        case _C_DBL:        return @"double";
        case _C_STRUCT_B: {
            FMAssert(NO);
            //return [MOFunctionArgument structureTypeEncodingDescription:fullTypeEncoding];
        }
        case _C_SEL:        return @"selector";
        case _C_CHARPTR:    return @"char*";
        case _C_BOOL:       return @"bool";
        case _C_PTR:        return @"void*";
        case _C_UNDEF:      return @"(unknown)";
    }
    return nil;
}




@end



