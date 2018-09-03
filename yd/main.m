//
//  main.m
//  yd
//
//  Created by August Mueller on 8/20/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COScriptLite.h"
#import "COSLBridgeParser.h"
#import "COSLTestStuff.h"
#import <objc/runtime.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        [[COSLBridgeParser sharedParser] parseBridgeFileAtPath:@"/Users/gus/Projects/yellowduck/bridgesupport/yd.bridgesupport"];
        
        COScriptLite *cos = [COScriptLite new];
        
        //[cos evaluateScript:@"x = 10; log(x); print('Hello, World');"];
        
        [cos evaluateScript:@"print(COSLMethodReturnNSDictionary());"];
        
        COSLTestStuffTestPassed = NO;
        [cos evaluateScript:@"COSLMethodCheckNSDictionary(COSLMethodReturnNSDictionary());"];
        assert(COSLTestStuffTestPassed);
        
        COSLTestStuffTestPassed = NO;
        [cos evaluateScript:@"print(COSLMethodStringSringArgStringReturn('Hello', 'World'))"];
        assert(COSLTestStuffTestPassed);
        
        COSLTestStuffTestPassed = NO;
        [cos evaluateScript:@"COSLMethodPleasePassNSNumber3(3);"];
        assert(COSLTestStuffTestPassed);
        
        
        //[cos evaluateScript:@"print(NSHomeDirectoryForUser('kirstin'));"];
        
        //[cos evaluateScript:@"s = NSUUID.allocWithZone(null).init(); print(s);"];
        
        //[cos evaluateScript:@"print(NSUserName())"];
        //[cos evaluateScript:@"print(NSFullUserName())"];
        //[cos evaluateScript:@"var s = COScriptLite.testClassMethod();"];
        //[cos evaluateScript:@"s = null;"];
        
        [cos garbageCollect];
        
        printf("All done\n");
        
        //NSLog(@"%@", NSHomeDirectoryForUser(@"kirstin"));
        
    }
    return 0;
}
