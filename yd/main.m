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


const char *_protocol_getMethodTypeEncoding(Protocol *, SEL, BOOL isRequiredMethod, BOOL isInstanceMethod);

@protocol Tester <NSObject>
@required
- (BOOL)testDictionary:(NSDictionary *)dictionary error:(NSError **)error;
- (void)nothing;
@end




int main(int argc, const char * argv[]) {
    @autoreleasepool {
        struct objc_method_description description = protocol_getMethodDescription(@protocol(Tester), @selector(testDictionary:error:), YES, YES);
        NSLog(@"%s", description.types);
        // Outputs c32@0:8@16^@24
        
        const char *descriptionString = _protocol_getMethodTypeEncoding(@protocol(Tester), @selector(testDictionary:error:), YES, YES);
        NSLog(@"%s", descriptionString);
        
        
        descriptionString = _protocol_getMethodTypeEncoding(@protocol(Tester), @selector(nothing), YES, YES);
        NSLog(@"%s", descriptionString);
        
        
        // Outputs c32@0:8@"NSDictionary"16^@24

        /*
        Protocol *protocol = objc_getProtocol("COScriptLiteJavaScriptMethods");
        assert(protocol);
        
        struct objc_method_description methodDescr = protocol_getMethodDescription(protocol, @selector(testClassMethod), YES, NO);
         */
        //assert(methodDescr);
        
        //Protocol * __unsafe_unretained * protocolList = objc_copyProtocolList(<#unsigned int * _Nullable outCount#>)
        
        
        COScriptLite *cos = [COScriptLite new];
        
        //[cos evaluateScript:@"x = 10; log(x); print('Hello, World');"];
        
        
        //[cos evaluateScript:@"print(NSUUID);"];
        
        //[cos evaluateScript:@"s = NSUUID.allocWithZone(null).init(); print(s);"];
        
        //[cos evaluateScript:@"print(NSUserName())"];
        [cos evaluateScript:@"var s = COScriptLite.testClassMethod();"];
        [cos evaluateScript:@"s = null;"];
        
        [cos garbageCollect];
        
        
        //const char *protocolName = class_getName([COScriptLite class]);
        //Protocol *protocol = objc_allocateProtocol(protocolName);
        //protocol_addProtocol(protocol, objc_getProtocol("JSExport"));

        
        
        
        
        
        
        
        printf("All done\n");
        
    }
    return 0;
}
