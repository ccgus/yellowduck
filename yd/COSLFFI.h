//
//  COSLFFI.h
//  yd
//
//  Created by August Mueller on 8/22/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class COSLJSWrapper;
@class COScriptLite;

NS_ASSUME_NONNULL_BEGIN

@interface COSLFFI : NSObject

+ (instancetype)ffiWithFunction:(COSLJSWrapper*)f caller:(nullable COSLJSWrapper*)caller arguments:(NSArray*)args cos:(COScriptLite*)cos;

- (nullable COSLJSWrapper*)callFunction;


@end

NS_ASSUME_NONNULL_END