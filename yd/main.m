//
//  main.m
//  yd
//
//  Created by August Mueller on 8/20/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COSLRuntime.h"
#import "COSLBridgeParser.h"
#import "COSLTestStuff.h"
#import <objc/runtime.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        [[COSLBridgeParser sharedParser] parseBridgeFileAtPath:@"/Users/gus/Projects/yellowduck/bridgesupport/yd.bridgesupport"];
        
        COSLRuntime *runtime = [COSLRuntime new];
        
        //[cos evaluateScript:@"x = 10; log(x); print('Hello, World');"];
        
        [runtime evaluateScript:@"var c = COSLTestStuff.new(); COSLAssert(c != null);"];
        
        [runtime evaluateScript:@"print('Hello?');"];
        [runtime evaluateScript:@"print(COSLMethodReturnNSDictionary());"];
        
        COSLTestStuffTestPassed = NO;
        [runtime evaluateScript:@"COSLMethodCheckNSDictionary(COSLMethodReturnNSDictionary());"];
        assert(COSLTestStuffTestPassed);
        
        COSLTestStuffTestPassed = NO;
        [runtime evaluateScript:@"print(COSLMethodStringSringArgStringReturn('Hello', 'World'))"];
        assert(COSLTestStuffTestPassed);
        
        COSLTestStuffTestPassed = NO;
        [runtime evaluateScript:@"COSLMethodPleasePassNSNumber3(3);"];
        assert(COSLTestStuffTestPassed);
        
        
        
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
