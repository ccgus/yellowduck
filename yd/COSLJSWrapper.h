//
//  COSLJSWrapper.h
//  yd
//
//  Created by August Mueller on 8/21/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COSLBridgeParser.h"

NS_ASSUME_NONNULL_BEGIN

@interface COSLJSWrapper : NSObject

+ (instancetype)wrapperWithSymbol:(COSLSymbol*)sym;

+ (instancetype)wrapperWithInstance:(id)instance;
+ (instancetype)wrapperWithClass:(Class)c;
+ (instancetype)wrapperWithInstanceMethod:(SEL)selector;
+ (instancetype)wrapperWithClassMethod:(SEL)selector;

- (BOOL)isClass;
- (BOOL)isInstance;
- (BOOL)isInstanceMethod;
- (BOOL)isClassMethod;

- (BOOL)isSymbol;
- (BOOL)isFunction;
- (void)callFunction;

- (BOOL)hasClassMethodNamed:(NSString*)m;

- (instancetype)wrapperForClassMethodNamed:(NSString*)m;

- (id)callMethod;

@end

NS_ASSUME_NONNULL_END
