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

@property (assign) Class class;
@property (assign) SEL instanceSelector;
@property (assign) SEL classSelector;
@property (strong) id instance;
@property (strong) COSLSymbol *symbol;

@end

@implementation COSLJSWrapper

- (void)dealloc {
    NSLog(@"%s:%d", __FUNCTION__, __LINE__);
}

+ (instancetype)wrapperWithSymbol:(COSLSymbol*)sym {
    
    COSLJSWrapper *cw = [[self alloc] init];
    [cw setSymbol:sym];
    
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

- (void)callFunction {
    
    debug(@"_symbol: '%@'", _symbol);
    
    #pragma message "FIXME: OH GOD I ACTUALLY HAVE TO DO THIS NOW UGH."
    
}

@end
