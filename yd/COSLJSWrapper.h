//
//  COSLJSWrapper.h
//  yd
//
//  Created by August Mueller on 8/21/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <ffi/ffi.h>
#import "COSLBridgeParser.h"
#import "COScriptLite.h"

NS_ASSUME_NONNULL_BEGIN

@interface COSLJSWrapper : NSObject

@property (assign) BOOL isJSNative;
@property (strong) COSLSymbol *symbol;
@property (strong) id instance;

+ (instancetype)wrapperInCOS:(COScriptLite*)cos;
+ (instancetype)wrapperForJSObject:(nullable JSObjectRef)jso cos:(COScriptLite*)cos;
+ (instancetype)wrapperWithSymbol:(COSLSymbol*)sym cos:(COScriptLite*)cos;
+ (instancetype)wrapperWithInstance:(id)instance cos:(COScriptLite*)cos;

+ (instancetype)wrapperWithClass:(Class)c;
+ (instancetype)wrapperWithInstanceMethod:(SEL)selector;
+ (instancetype)wrapperWithClassMethod:(SEL)selector;

- (BOOL)isClass;
- (BOOL)isInstance;
- (BOOL)isInstanceMethod;
- (BOOL)isClassMethod;

- (BOOL)isSymbol;
- (BOOL)isFunction;

- (BOOL)hasClassMethodNamed:(NSString*)m;

- (instancetype)wrapperForClassMethodNamed:(NSString*)m;

- (nullable JSValueRef)JSValue;
- (nullable JSValueRef)toJSString;

- (void*)objectStorage;

- (ffi_type*)FFIType;

@end

NS_ASSUME_NONNULL_END
