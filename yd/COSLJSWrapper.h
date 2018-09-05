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
#import "COSLRuntime.h"

NS_ASSUME_NONNULL_BEGIN

@interface COSLJSWrapper : NSObject

@property (assign) BOOL isJSNative;
@property (strong) COSLSymbol *symbol;
@property (strong) id instance;

+ (instancetype)wrapperForJSObject:(nullable JSObjectRef)jso runtime:(COSLRuntime*)runtime;
+ (instancetype)wrapperWithSymbol:(COSLSymbol*)sym runtime:(COSLRuntime*)runtime;
+ (instancetype)wrapperWithInstance:(id)instance runtime:(COSLRuntime*)runtime;

+ (instancetype)wrapperWithClass:(Class)c;
+ (instancetype)wrapperWithInstanceMethod:(SEL)selector;
+ (instancetype)wrapperWithClassMethod:(SEL)selector;

- (BOOL)isClass;
- (BOOL)isInstance;

- (BOOL)isSymbol;
- (BOOL)isFunction;
- (BOOL)isInstanceMethod;
- (BOOL)isClassMethod;

- (BOOL)hasClassMethodNamed:(NSString*)m;

- (instancetype)wrapperForClassMethodNamed:(NSString*)m;

- (nullable JSValueRef)JSValue;
- (nullable JSValueRef)toJSString;

- (void*)objectStorage;
- (BOOL)pushJSValueToNativeType:(NSString*)type;

- (ffi_type*)FFIType;



@end

NS_ASSUME_NONNULL_END
