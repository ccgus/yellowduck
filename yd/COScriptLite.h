//
//  COScriptLite.h
//  yd
//
//  Created by August Mueller on 8/20/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define debug NSLog

@import JavaScriptCore;


NS_ASSUME_NONNULL_BEGIN

@protocol COScriptLiteJavaScriptMethods <JSExport>

+ (void)testClassMethod;

@end

@interface COScriptLite : NSObject <COScriptLiteJavaScriptMethods>

@property (strong) JSContext *jscContext;

- (id)evaluateScript:(NSString*)str;
- (id)evaluateScript:(NSString *)script withSourceURL:(NSURL *)sourceURL;

- (void)garbageCollect;

@end


NS_ASSUME_NONNULL_END
