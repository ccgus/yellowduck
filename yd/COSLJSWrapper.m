//
//  COSLJSWrapper.m
//  yd
//
//  Created by August Mueller on 8/21/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import "COSLJSWrapper.h"

#define debug NSLog

@interface COSLJSWrapper ()

@property (weak) COScriptLite *cos;
@property (assign) Class class;
@property (assign) SEL instanceSelector;
@property (assign) SEL classSelector;

@end

@implementation COSLJSWrapper

- (void)dealloc {
    NSLog(@"%s:%d", __FUNCTION__, __LINE__);
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
    
    COSLJSWrapper *wr = (__bridge COSLJSWrapper *)(JSObjectGetPrivate(jso));
    if (wr) {
        return wr;
    }
    
    return nil;
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

+ (instancetype)wrapperWithInstance:(id)instance {
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
    
    debug(@"_symbol: '%@'", _symbol);
    
    JSStringRef string = JSStringCreateWithCFString((__bridge CFStringRef)[_instance description]);
    JSValueRef value = JSValueMakeString([[_cos jscContext] JSGlobalContextRef], string);
    JSStringRelease(string);
    return value;
}

- (void*)objectStorage {
    return &_instance;
}

@end
