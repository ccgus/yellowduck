//
//  main.m
//  yd
//
//  Created by August Mueller on 8/20/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COScriptLite.h"
#import <objc/runtime.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        COScriptLite *cos = [COScriptLite new];
        
        //[cos evaluateScript:@"x = 10; log(x); print('Hello, World');"];
        
        
        //[cos evaluateScript:@"print(NSUUID);"];
        
        //[cos evaluateScript:@"s = NSUUID.allocWithZone(null).init(); print(s);"];
        
        [cos evaluateScript:@"print(NSUserName())"];
        [cos evaluateScript:@"print(NSFullUserName())"];
        //[cos evaluateScript:@"var s = COScriptLite.testClassMethod();"];
        //[cos evaluateScript:@"s = null;"];
        
        [cos garbageCollect];
        
        printf("All done\n");
        
    }
    return 0;
}
