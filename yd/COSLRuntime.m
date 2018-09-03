//
//  COScript.m
//  yd
//
//  Created by August Mueller on 8/20/18.
//  Copyright © 2018 Flying Meat Inc. All rights reserved.
//
// I wish we could dynamically add the JSExport protocol to things at runtime, but it requires extended type info :(
// https://brandonevans.ca/post/text/dynamically-exporting-objective-c-classes-to/
//

#import "COSLRuntime.h"
#import "COSLJSWrapper.h"
#import "COSLJSWrapper.h"
#import "COSLBridgeParser.h"
#import "COSLFFI.h"
#import <objc/runtime.h>
#import <dlfcn.h>

@interface COSLRuntime () {
    
}


@property (weak) COSLRuntime *previousCoScript;

@end

#define COSLRuntimeLookupKey @"__cosRuntimeLookup__"

static COSLRuntime *COSLCurrentCOScriptLite;

static JSClassRef COSLGlobalClass = NULL;
static void COSL_initialize(JSContextRef ctx, JSObjectRef object);
static void COSL_finalize(JSObjectRef object);
JSValueRef COSL_getGlobalProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef *exception);
//static bool COSL_hasProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName);
static JSValueRef COSL_callAsFunction(JSContextRef ctx, JSObjectRef functionJS, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception);

@implementation COSLRuntime


+ (void)initialize {
    if (self == [COSLRuntime class]) {
        JSClassDefinition COSGlobalClassDefinition      = kJSClassDefinitionEmpty;
        COSGlobalClassDefinition.className              = "CocoaScriptLite";
        COSGlobalClassDefinition.getProperty            = COSL_getGlobalProperty;
        COSGlobalClassDefinition.initialize             = COSL_initialize;
        COSGlobalClassDefinition.finalize               = COSL_finalize;
        //COSGlobalClassDefinition.hasProperty            = COSL_hasProperty;
        COSGlobalClassDefinition.callAsFunction         = COSL_callAsFunction;
        COSLGlobalClass                                 = JSClassCreate(&COSGlobalClassDefinition);

    }
}


+ (COSLRuntime*)currentCOScriptLite {
    return COSLCurrentCOScriptLite;
}

+ (instancetype)runtimeInContext:(JSContextRef)context {
//
//    JSContext *ctx = [JSContext contextWithJSGlobalContextRef:context];
//    debug(@"ctx: '%@'", ctx);
//
//    return [[ctx objectForKeyedSubscript:COSLRuntimeLookupKey] toObject];
//
    
    JSValueRef exception = NULL;
    
    JSStringRef jsName = JSStringCreateWithUTF8CString([COSLRuntimeLookupKey UTF8String]);
    JSValueRef jsValue = JSObjectGetProperty(context, JSContextGetGlobalObject(context), jsName, &exception);
    JSStringRelease(jsName);
    
    if (exception != NULL) {
        FMAssert(NO);
        return NULL;
    }
    
    COSLJSWrapper *w = (__bridge COSLJSWrapper *)JSObjectGetPrivate((JSObjectRef)jsValue);
    
    return [w instance];
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self loadFrameworkAtPath:@"/System/Library/Frameworks/Foundation.framework"];
        [self loadFrameworkAtPath:@"/System/Library/Frameworks/AppKit.framework"];
        [self loadFrameworkAtPath:@"/System/Library/Frameworks/CoreImage.framework"];
    }
    return self;
}



- (void)pushAsCurrentCOSL {
    [self setPreviousCoScript:COSLCurrentCOScriptLite];
    COSLCurrentCOScriptLite = self;
}

- (void)popAsCurrentCOSL {
    COSLCurrentCOScriptLite = [self previousCoScript];
}

- (JSContext*)context {
    if (!_jscContext) {
        JSGlobalContextRef globalContext = JSGlobalContextCreate(COSLGlobalClass);
        _jscContext = [JSContext contextWithJSGlobalContextRef:globalContext];
        
        [_jscContext setExceptionHandler:^(JSContext *context, JSValue *exception) {
            debug(@"Exception: %@", exception);
        }];
        
        [self setRuntimeObject:self withName:COSLRuntimeLookupKey];
        
        FMAssert([self runtimeObjectWithName:COSLRuntimeLookupKey] == self);
        FMAssert([COSLRuntime runtimeInContext:[self contextRef]]  == self);
        
    }
    
    return _jscContext;
}

- (JSContextRef)contextRef {
    return [[self context] JSGlobalContextRef];
}

- (id)runtimeObjectWithName:(NSString *)name {
    
    JSValueRef exception = NULL;
    
    JSStringRef jsName = JSStringCreateWithUTF8CString([name UTF8String]);
    JSValueRef jsValue = JSObjectGetProperty([self contextRef], JSContextGetGlobalObject([self contextRef]), jsName, &exception);
    JSStringRelease(jsName);
    
    if (exception != NULL) {
        FMAssert(NO);
        return NULL;
    }
    
    COSLJSWrapper *w = (__bridge COSLJSWrapper *)JSObjectGetPrivate((JSObjectRef)jsValue);
    
    return [w instance];
}

- (JSValueRef)setRuntimeObject:(id)object withName:(NSString *)name {
    
    COSLJSWrapper *w = [COSLJSWrapper wrapperWithInstance:object runtime:self];
    
    JSValueRef jsValue = [self newJSValueForWrapper:w];
    
    // Set
    JSValueRef exception = NULL;
    JSStringRef jsName = JSStringCreateWithUTF8CString([name UTF8String]);
    JSObjectSetProperty([self contextRef], JSContextGetGlobalObject([self contextRef]), jsName, jsValue, kJSPropertyAttributeNone, &exception);
    JSStringRelease(jsName);
    
    if (exception != NULL) {
        FMAssert(NO);
        return NULL;
    }
    
    return jsValue;
}

- (void)garbageCollect {
    JSGarbageCollect([_jscContext JSGlobalContextRef]);
}

- (id)evaluateScript:(NSString *)script withSourceURL:(NSURL *)sourceURL {
    
    [self pushAsCurrentCOSL];
    
    @try {
        [[self context] evaluateScript:script withSourceURL:sourceURL];
    }
    @catch (NSException *exception) {
        debug(@"Exception: %@", exception);
    }
    @finally {
        ;
    }
    
    [self popAsCurrentCOSL];
}

- (id)evaluateScript:(NSString*)script {
    
    [self pushAsCurrentCOSL];
    
    @try {
        [[self context] evaluateScript:script];
    }
    @catch (NSException *exception) {
        debug(@"Exception: %@", exception);
    }
    @finally {
        ;
    }
    
    [self popAsCurrentCOSL];
    
    return nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    debug(@"aSelector: '%@'?", NSStringFromSelector(aSelector));
    
    return [super respondsToSelector:aSelector];
}

- (void)loadFrameworkAtPath:(NSString*)path {

    
    NSString *frameworkName = [[path lastPathComponent] stringByDeletingPathExtension];
    
    // Load the framework
    NSString *libPath = [path stringByAppendingPathComponent:frameworkName];
    void *address = dlopen([libPath UTF8String], RTLD_LAZY);
    if (!address) {
        NSLog(@"ERROR: Could not load framework dylib: %@, %@", frameworkName, libPath);
        return;
    }
    
    NSString *bridgeDylib = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"Resources/BridgeSupport/%@.dylib", frameworkName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:bridgeDylib]) {
        address = dlopen([libPath UTF8String], RTLD_LAZY);
        if (!address) {
            NSLog(@"ERROR: Could not load BridgeSupport dylib: %@, %@", frameworkName, bridgeDylib);
        }
    }

    NSString *bridgeXML = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"Resources/BridgeSupport/%@.bridgesupport", frameworkName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:bridgeXML]) {
        [[COSLBridgeParser sharedParser] parseBridgeFileAtPath:bridgeXML];
    }
}

+ (void)testClassMethod {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}

- (JSValueRef)newJSValueForWrapper:(COSLJSWrapper*)w {
    
    // This should only be called for non-js objects.
    FMAssert(![w isJSNative]);
    
    JSObjectRef r = JSObjectMake([[self jscContext] JSGlobalContextRef], COSLGlobalClass, (__bridge void *)(w));
    CFRetain((__bridge void *)w);
    
    return r;
}

@end

static void COSL_initialize(JSContextRef ctx, JSObjectRef object) {
    
    //debug(@"COSL_initialize: %@", [COSLJSWrapper wrapperForJSObject:object cos:[COScriptLite currentCOScriptLite]]);
    
    
//    debug(@"%s:%d", __FUNCTION__, __LINE__);
//    id private = (__bridge id)(JSObjectGetPrivate(object));
//    debug(@"private: '%@'", private);
//
//    if (private) {

//        CFRetain((__bridge CFTypeRef)private);

//        if (class_isMetaClass(object_getClass([private representedObject]))) {
//            debug(@"inited a global class object %@ - going to keep it protected", [private representedObject]);
//            JSValueProtect(ctx, [private JSObject]);
//        }
//    }


}

JSValueRef COSL_getGlobalProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef *exception) {
    NSString *propertyName = (NSString *)CFBridgingRelease(JSStringCopyCFString(kCFAllocatorDefault, propertyNameJS));
    if ([propertyName isEqualToString:COSLRuntimeLookupKey]) {
        return nil;
    }
    
    COSLRuntime *runtime = [COSLRuntime runtimeInContext:ctx];
    
    debug(@"propertyName: '%@' (%p)", propertyName, object);
    
    if ([propertyName isEqualToString:@"toString"] || [propertyName isEqualToString:@"Symbol.toStringTag"]/* || [propertyName isEqualToString:@"Symbol.toPrimitive"]*/) {
        COSLJSWrapper *w = [COSLJSWrapper wrapperForJSObject:object runtime:runtime];
        
        return [w toJSString];
    }
    
    
    COSLSymbol *sym = [COSLBridgeParser symbolForName:propertyName];
    if (sym) {
        
        
        if ([[sym symbolType] isEqualToString:@"function"]) {
            
            COSLJSWrapper *w = [COSLJSWrapper wrapperWithSymbol:sym runtime:runtime];
            
            return [runtime newJSValueForWrapper:w];
            
        }
        else if ([[sym symbolType] isEqualToString:@"class"]) {
            debug(@"class!");
        }
        else if ([[sym symbolType] isEqualToString:@"enum"]) {
            
            return JSValueMakeNumber(ctx, [[sym runtimeValue] doubleValue]);
            
            
        }
        else if ([[sym symbolType] isEqualToString:@"constant"]) {
            
            // Grab symbol
            void *dlsymbol = dlsym(RTLD_DEFAULT, [propertyName UTF8String]);
            assert(dlsymbol);
            
            assert([[sym runtimeType] hasPrefix:@"@"]);
            
            id o = (__bridge id)(*(void**)dlsymbol);
            COSLJSWrapper *w = [COSLJSWrapper wrapperWithInstance:o runtime:runtime];
            
            JSObjectRef r = JSObjectMake(ctx, COSLGlobalClass, (__bridge void *)(w));
            
            CFRetain((__bridge void *)w);
            
            return r;
            
        }
        
        
        
        
    }
    
    
    
    
    
//    Class objCClass = NSClassFromString(propertyName);
//    if (objCClass && ![propertyName isEqualToString:@"Object"] && ![propertyName isEqualToString:@"Function"]) {
//
//        COSLJSWrapper *w = [COSLJSWrapper wrapperWithClass:objCClass];
//
//        JSObjectRef r = JSObjectMake(ctx, COSLGlobalClass, (__bridge void *)(runtime));
//
//        JSObjectSetPrivate(r, (__bridge void *)(w));
//
//        CFRetain((__bridge void *)w);
//
//        return r;
//    }
//
//    if (existingWrap && [existingWrap isClass] && [existingWrap hasClassMethodNamed:propertyName]) {
//        debug(@"class lookup of something…");
//
//
//        COSLJSWrapper *w = [existingWrap wrapperForClassMethodNamed:propertyName];
//
//        JSObjectRef r = JSObjectMake(ctx, COSLGlobalClass, (__bridge void *)(runtime));
//
//        JSObjectSetPrivate(r, (__bridge void *)(w));
//
//        CFRetain((__bridge void *)w);
//
//        return r;
//    }
//
//
//
//    if ([propertyName isEqualToString:@"testClassMethod"]) {
//        debug(@"jfkldsajfklds %p", object);
//    }
    
    return nil;
}

//static bool COSL_hasProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS) {
//    NSString *propertyName = (NSString *)CFBridgingRelease(JSStringCopyCFString(NULL, propertyNameJS));
//    debug(@"propertyName: '%@'", propertyName);
//    debug(@"%s:%d", __FUNCTION__, __LINE__);
//    return NO;
//}

static JSValueRef COSL_callAsFunction(JSContextRef ctx, JSObjectRef functionJS, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception) {
    
    COSLRuntime *runtime = [COSLRuntime runtimeInContext:ctx];
    
    COSLJSWrapper *objectToCall = [COSLJSWrapper wrapperForJSObject:thisObject runtime:runtime];
    COSLJSWrapper *functionToCall = [COSLJSWrapper wrapperForJSObject:functionJS runtime:runtime];
    
    NSMutableArray *args = [NSMutableArray arrayWithCapacity:argumentCount];
    for (size_t idx = 0; idx < argumentCount; idx++) {
        COSLJSWrapper *arg = [COSLJSWrapper wrapperForJSObject:(JSObjectRef)arguments[idx] runtime:runtime];
        assert(arg);
        [args addObject:arg];
    }
    
    COSLFFI *ffi = [COSLFFI ffiWithFunction:functionToCall caller:objectToCall arguments:args cos:runtime];
    
    
    COSLJSWrapper *ret = [ffi callFunction];
    
    JSValueRef returnRef = [ret JSValue];
    
    return returnRef;
}

static void COSL_finalize(JSObjectRef object) {
    COSLJSWrapper *objectToCall = (__bridge COSLJSWrapper *)(JSObjectGetPrivate(object));
    
    if (objectToCall) {
        CFRelease((__bridge CFTypeRef)(objectToCall));
    }
}

void print(id s) {
    if (!s) {
        s = @"<null>";
    }
    
    printf("** %s\n", [[s description] UTF8String]);
}

/*
 
void COSL_exportClassJSExport(Class class) {
    // Create a protocol that inherits from JSExport and with all the public methods and properties of the class
 
    NSString *protocolName = [NSString stringWithFormat:@"%sJavaScriptMethods", class_getName(class)];
    Protocol *myProtocol = objc_allocateProtocol([protocolName UTF8String]);
 
    if (!myProtocol) { // We've already allocated it.
        return;
    }
 
    // Add the public methods of the class to the protocol
    unsigned int methodCount, classMethodCount, propertyCount;
    Method *methods, *classMethods;
    objc_property_t *properties;
 
    methods = class_copyMethodList(class, &methodCount);
//    for (NSUInteger methodIndex = 0; methodIndex < methodCount; ++methodIndex) {
//        Method method = methods[methodIndex];
//
////        if (method_getName(method) == @selector(init)) {
////            debug(@"skipping init");
////            continue;
////        }
//
//        //debug(@"instance: %@", NSStringFromSelector(method_getName(method)));
//        protocol_addMethodDescription(myProtocol, method_getName(method), method_getTypeEncoding(method), YES, YES);
//    }
 
    classMethods = class_copyMethodList(object_getClass(class), &classMethodCount);
    for (NSUInteger methodIndex = 0; methodIndex < classMethodCount; ++methodIndex) {
        Method method = classMethods[methodIndex];
 
        debug(@"class: %@", NSStringFromSelector(method_getName(method)));
        protocol_addMethodDescription(myProtocol, method_getName(method), method_getTypeEncoding(method), YES, NO);
    }
 
 
 
    properties = class_copyPropertyList(class, &propertyCount);
    for (NSUInteger propertyIndex = 0; propertyIndex < propertyCount; ++propertyIndex) {
        objc_property_t property = properties[propertyIndex];
 
        //debug(@"%s", property_getName(property));
 
        unsigned int attributeCount;
        objc_property_attribute_t *attributes = property_copyAttributeList(property, &attributeCount);
        protocol_addProperty(myProtocol, property_getName(property), attributes, attributeCount, YES, YES);
        free(attributes);
    }
 
    free(methods);
    free(classMethods);
    free(properties);
 
    protocol_addProtocol(myProtocol, objc_getProtocol("JSExport"));
 
    // Add the new protocol to the class
    objc_registerProtocol(myProtocol);
    class_addProtocol(class, myProtocol);
 
    assert(protocol_conformsToProtocol(myProtocol, objc_getProtocol("JSExport")));
 
    // forEachProtocolImplementingProtocol
//    debug(@"listing");
//    unsigned int outCount;
//    __unsafe_unretained Protocol **protocols = class_copyProtocolList(class, &outCount);
//    for (int i = 0; i < outCount; i++) {
//
//        Protocol *ptotocol = protocols[i];
//        const char * name = protocol_getName(ptotocol);
//        NSLog(@"ptotocol_name:%s - %d!", name, protocol_conformsToProtocol(ptotocol, objc_getProtocol("JSExport")));
//
//    }
 
//    Class superclass = class_getSuperclass(class);
//    if (superclass) {
//        COSL_exportClassJSExport(superclass);
//    }
}*/









