//
//  main.m
//  yd
//
//  Created by August Mueller on 8/20/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FJSRuntime.h"
#import "FJSBridgeParser.h"
#import "FJSTestStuff.h"
#import <objc/runtime.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        [[FJSBridgeParser sharedParser] parseBridgeFileAtPath:@"/Users/gus/Projects/yellowduck/bridgesupport/yd.bridgesupport"];
        
        FJSRuntime *runtime = [FJSRuntime new];
        
        //[cos evaluateScript:@"x = 10; log(x); print('Hello, World');"];
        
        [runtime evaluateScript:@"var c = FJSTestStuff.new(); FJSAssert(c != null);"];
        
        [runtime evaluateScript:@"print('Hello?');"];
        [runtime evaluateScript:@"print(FJSMethodReturnNSDictionary());"];
        
        FJSTestStuffTestPassed = NO;
        [runtime evaluateScript:@"FJSMethodCheckNSDictionary(FJSMethodReturnNSDictionary());"];
        assert(FJSTestStuffTestPassed);
        
        FJSTestStuffTestPassed = NO;
        [runtime evaluateScript:@"print(FJSMethodStringSringArgStringReturn('Hello', 'World'))"];
        assert(FJSTestStuffTestPassed);
        
        FJSTestStuffTestPassed = NO;
        [runtime evaluateScript:@"FJSMethodPleasePassNSNumber3(3);"];
        assert(FJSTestStuffTestPassed);
        
        
        
        //[cos evaluateScript:@"print(NSHomeDirectoryForUser('kirstin'));"];
        
        //[cos evaluateScript:@"s = NSUUID.allocWithZone(null).init(); print(s);"];
        
        //[cos evaluateScript:@"print(NSUserName())"];
        //[cos evaluateScript:@"print(NSFullUserName())"];
        //[cos evaluateScript:@"var s = COScriptLite.testClassMethod();"];
        //[cos evaluateScript:@"s = null;"];
        
        [runtime garbageCollect];
        
        printf("All done\n");
        
        //NSLog(@"%@", NSHomeDirectoryForUser(@"kirstin"));
        
    }
    return 0;
}
