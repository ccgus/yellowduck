//
//  COSLBridgeParser.h
//  yd
//
//  Created by August Mueller on 8/21/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class COSLSymbol;

@interface COSLBridgeParser : NSObject <NSXMLParserDelegate>

@property (strong) NSMutableDictionary *symbols;

+ (instancetype)sharedParser;

- (void)parseBridgeFileAtPath:(NSString*)bridgePath;

+ (COSLSymbol*)symbolForName:(NSString*)name;

@end


@interface COSLSymbol : NSObject {
    
}

@property (strong) NSString *symbolType;
@property (strong) NSString *name;
@property (strong) NSString *runtimeType;
@property (strong) NSString *runtimeValue;
@property (assign) SEL selector;
@property (strong) NSMutableArray *arguments;
@property (strong) NSMutableArray *classMethods;
@property (strong) NSMutableArray *instanceMethods;
@property (strong) COSLSymbol *returnValue;
@property (assign) BOOL isClassMethod;

- (void)addArgument:(COSLSymbol*)sym;

- (void)addClassMethod:(COSLSymbol*)sym;
- (void)addInstanceMethod:(COSLSymbol*)sym;

- (COSLSymbol*)classMethodNamed:(NSString*)name;
- (COSLSymbol*)instanceMethodNamed:(NSString*)name;

@end

NS_ASSUME_NONNULL_END
