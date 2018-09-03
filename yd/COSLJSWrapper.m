//
//  COSLJSWrapper.m
//  yd
//
//  Created by August Mueller on 8/21/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import "COSLJSWrapper.h"
#import "COSLFFI.h"

#define debug NSLog

@interface COSLJSWrapper ()

@property (weak) COScriptLite *cos;
@property (assign) Class class;
@property (assign) SEL instanceSelector;
@property (assign) SEL classSelector;
@property (assign) JSObjectRef nativeJSObj;

@end

@implementation COSLJSWrapper

- (void)dealloc {
    //NSLog(@"%s:%d", __FUNCTION__, __LINE__);
}

+ (instancetype)wrapperInCOS:(COScriptLite*)cos {
    COSLJSWrapper *cw = [[self alloc] init];
    [cw setCos:cos];
    return cw;
}

+ (instancetype)wrapperForJSObject:(nullable JSObjectRef)jso cos:(COScriptLite*)cos {
    
    if (!jso) {
        return nil;
    }
    
    
    if (JSValueIsObject([[cos jscContext] JSGlobalContextRef], jso)) {
        COSLJSWrapper *wr = (__bridge COSLJSWrapper *)(JSObjectGetPrivate(jso));
        if (wr) {
            return wr;
        }
    }
    
    COSLJSWrapper *native = [COSLJSWrapper new];
    [native setNativeJSObj:jso];
    [native setIsJSNative:YES];
    [native setCos:cos];
    
    return native;
}

+ (instancetype)wrapperWithSymbol:(COSLSymbol*)sym cos:(COScriptLite*)cos {
    
    COSLJSWrapper *cw = [[self alloc] init];
    [cw setSymbol:sym];
    [cw setCos:cos];
    
    return cw;
}

+ (instancetype)wrapperWithClass:(Class)c {
    COSLJSWrapper *cw = [[self alloc] init];
    [cw setClass:c];
    
    return cw;
}

+ (instancetype)wrapperWithInstance:(id)instance cos:(COScriptLite*)cos {
    COSLJSWrapper *cw = [[self alloc] init];
    [cw setInstance:instance];
    
    return cw;
    
}

+ (instancetype)wrapperWithInstanceMethod:(SEL)selector {
    COSLJSWrapper *cw = [[self alloc] init];
    [cw setInstanceSelector:selector];
    
    return cw;
}

+ (instancetype)wrapperWithClassMethod:(SEL)selector {
    COSLJSWrapper *cw = [[self alloc] init];
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
    return _instanceSelector != nil;
}

- (BOOL)isClassMethod {
    return _classSelector != nil;
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
    
    COSLJSWrapper *w = [COSLJSWrapper new];
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
        
        JSValueRef vr = [COSLJSWrapper nativeObjectToJSValue:_instance inJSContext:[[_cos jscContext] JSGlobalContextRef]];
        
        if (vr) {
            return vr;
        }
        
        return [_cos newJSValueForWrapper:self];
    }
    
    return nil;
}

- (void*)objectStorage {
    return &_instance;
}

- (ffi_type*)FFIType {
    
    if (_symbol) {
        
        char c = [[_symbol runtimeType] characterAtIndex:0];
        
        if (c) {
            return [COSLFFI ffiTypeAddressForTypeEncoding:c];
        }
    }
    
    debug(@"NO SYMBOL IN WRAPPER: %@", self);
    return &ffi_type_void;
}

- (nullable JSValueRef)toJSString {
    // TODO: check for numbers, etc, and convert them to the right JS type
    debug(@"_instance: %@", _instance);
    JSStringRef string = JSStringCreateWithCFString((__bridge CFStringRef)[_instance description]);
    JSValueRef value = JSValueMakeString([[_cos jscContext] JSGlobalContextRef], string);
    JSStringRelease(string);
    return value;
}

- (BOOL)pushJSValueToNativeType:(NSString*)type {
    
    _instance = [COSLJSWrapper nativeObjectFromJSValue:_nativeJSObj inJSContext:[[_cos jscContext] JSGlobalContextRef]];
    
    
    return _instance != nil;
}

+ (id)nativeObjectFromJSValue:(JSValueRef)jsValue inJSContext:(JSContextRef)context {
    
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
        
        if (strcmp([o objCType], @encode(BOOL)) == 0) {
            return JSValueMakeBoolean(context, [o boolValue]);
        }
        else {
            return JSValueMakeNumber(context, [o doubleValue]);
        }
    }
    
    
    return nil;
}

@end



