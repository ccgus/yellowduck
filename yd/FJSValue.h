//
//  FJSJSWrapper.h
//  yd
//
//  Created by August Mueller on 8/21/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <ffi/ffi.h>
#import "FJSBridgeParser.h"
#import "FJSRuntime.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    NSInteger type;
    union {
        char charValue;
        unsigned char ucharValue;
        short shortValue;
        int intValue;
        int uintValue;
        long longValue;
        long long longlongValue;
        float floatValue;
        double doubleValue;
        BOOL boolValue;
        SEL selectorValue;
        void *pointerValue;
        void *structLocation;
        char *cStringLocation;
    } value;
} FJSObjCValue;

@interface FJSValue : NSObject

@property (assign) BOOL isJSNative;
@property (strong) FJSSymbol *symbol;
@property (strong) id instance;
@property (assign) FJSObjCValue cValue;


+ (instancetype)wrapperForJSObject:(nullable JSObjectRef)jso runtime:(FJSRuntime*)runtime;
+ (instancetype)wrapperWithSymbol:(FJSSymbol*)sym runtime:(FJSRuntime*)runtime;
+ (instancetype)wrapperWithInstance:(id)instance runtime:(FJSRuntime*)runtime;
+ (instancetype)wrapperWithClass:(Class)c runtime:(FJSRuntime*)runtime;

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
- (ffi_type*)FFITypeWithHint:(nullable NSString*)typeEncoding;


@end

NS_ASSUME_NONNULL_END
