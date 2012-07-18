//
//  BLXParser.m
//  BLXParser
//
//  Created by Luc Heinrich on 12/07/12.
//  Copyright (c) 2012 Telephasic Workshop. All rights reserved.
//

#import "BLXParser.h"

// ============================================================================

@interface BLXParser () <NSXMLParserDelegate>

@property (strong, nonatomic) NSXMLParser* parser;
@property (strong, nonatomic) NSMutableArray *stack;

- (void)_finishInitialization;
- (void)_registerHandler:(id)handler forEvent:(NSString *)name withKey:(NSString *)key;
- (id)_handlerForEvent:(NSString *)name;
- (void)_pushFrame;
- (void)_popFrame;

@end

static NSString *BLXParserFrameHandlersKey     = @"BLXParserFrameHandlersKey";
static NSString *BLXParserInheritedHandlersKey = @"BLXParserInheritedHandlersKey";
static NSString *BLXParserFrameContextKey      = @"BLXParserFrameContextKey";

static NSString *BLXParserTextEvent            = @"$${{TEXT_EVENT}}$$";
static NSString *BLXParserCDATAEvent           = @"$${{CDATA_EVENT}}$$";
static NSString *BLXParserContentEvent         = @"$${{CONTENT_EVENT}}$$";

// ============================================================================
#pragma mark -

@implementation BLXParser

// ----------------------------------------------------------------------------
#pragma mark Private properties

@synthesize parser = _parser;
@synthesize stack = _stack;

// ----------------------------------------------------------------------------
#pragma mark Lifecycle

+ (id)parserWithContentsOfURL:(NSURL *)url {
    return [[BLXParser alloc] initWithContentsOfURL:url];
}

- (id)initWithContentsOfURL:(NSURL *)url {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    [self _finishInitialization];
    
    return self;
}

+ (id)parserWithData:(NSData *)data {
    return [[BLXParser alloc] initWithData:data];
}

- (id)initWithData:(NSData *)data {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.parser = [[NSXMLParser alloc] initWithData:data];
    [self _finishInitialization];
    
    return self;
}

+ (id)parserWithStream:(NSInputStream *)stream {
    return [[BLXParser alloc] initWithStream:stream];
}

- (id)initWithStream:(NSInputStream *)stream {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.parser = [[NSXMLParser alloc] initWithStream:stream];
    [self _finishInitialization];
    
    return self;
}

- (void)_finishInitialization {
    self.parser.delegate = self;
    self.stack = [NSMutableArray array];
    [self _pushFrame];
}

// ----------------------------------------------------------------------------
#pragma mark Parsing handlers definition

- (void)on:(NSString *)tagName call:(BLXElementHandler)handler {
    [self _registerHandler:handler forEvent:tagName withKey:BLXParserFrameHandlersKey];
}

- (void)onText:(BLXTextHandler)handler {
    [self _registerHandler:handler forEvent:BLXParserTextEvent withKey:BLXParserFrameHandlersKey];
}

- (void)onTextOf:(NSString *)tagName call:(BLXTextHandler)handler {
    [self on:tagName call:^(NSDictionary *context) {
        [self onText:handler];
    }];
}

- (void)onCDATA:(BLXCDATAHandler)handler {
    [self _registerHandler:handler forEvent:BLXParserCDATAEvent withKey:BLXParserFrameHandlersKey];
}

- (void)onCDATAOf:(NSString *)tagName call:(BLXCDATAHandler)handler {
    [self on:tagName call:^(NSDictionary *context) {
        [self onCDATA:handler];
    }];
}

- (void)onContent:(BLXContentHandler)handler {
    [self _registerHandler:handler forEvent:BLXParserContentEvent withKey:BLXParserFrameHandlersKey];
}

- (void)onContentOf:(NSString *)tagName call:(BLXContentHandler)handler {
    [self on:tagName call:^(NSDictionary *context) {
        [self onContent:handler];
    }];
}

- (void)onAny:(NSString *)tagName call:(BLXElementHandler)handler {
    [self _registerHandler:handler forEvent:tagName withKey:BLXParserInheritedHandlersKey];
}

- (void)onTextOfAny:(NSString *)tagName call:(BLXTextHandler)handler {
    [self onAny:tagName call:^(NSDictionary *context) {
        [self onText:handler];
    }];
}

- (void)onCDATAOfAny:(NSString *)tagName call:(BLXCDATAHandler)handler {
    [self onAny:tagName call:^(NSDictionary *context) {
        [self onCDATA:handler];
    }];
}

- (void)onContentOfAny:(NSString *)tagName call:(BLXContentHandler)handler {
    [self onAny:tagName call:^(NSDictionary *context) {
        [self onContent:handler];
    }];
}

- (void)_registerHandler:(id)handler forEvent:(NSString *)name withKey:(NSString *)key {
    [[[self.stack lastObject] objectForKey:key] setObject:[handler copy] forKey:name];
}

- (id)_handlerForEvent:(NSString *)name {
    id handler = [[[self.stack lastObject] objectForKey:BLXParserFrameHandlersKey] objectForKey:name];
    if (handler == nil) {
        NSUInteger index = [self.stack indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(id frame, NSUInteger idx, BOOL *stop) {
            return (idx <= [self.stack count]-2) && ([[frame objectForKey:BLXParserInheritedHandlersKey] objectForKey:name] != nil);
        }];
        
        handler = index == NSNotFound ? nil : [[[self.stack objectAtIndex:index] objectForKey:BLXParserInheritedHandlersKey] objectForKey:name];
    }
    
    return handler;
}

// ----------------------------------------------------------------------------
#pragma mark Parsing

- (void)start {
    [self.parser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributes {
    BLXElementHandler handler = [self _handlerForEvent:elementName];    
    [self _pushFrame];

    if (handler != nil) {
        handler(attributes);
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    BLXTextHandler handler = [self _handlerForEvent:BLXParserTextEvent];
    if (handler != nil) {
        handler(string);
    }
    
    NSMutableDictionary *context = [[self.stack lastObject] objectForKey:BLXParserFrameContextKey];
    NSMutableString     *text    = [context objectForKey:BLXContextTextContentKey];

    [text appendString:string];
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    BLXCDATAHandler handler = [self _handlerForEvent:BLXParserCDATAEvent];
    if (handler != nil) {
        handler(CDATABlock);
    }

    NSMutableDictionary *context = [[self.stack lastObject] objectForKey:BLXParserFrameContextKey];
    NSMutableString     *text    = [context objectForKey:BLXContextTextContentKey];

    [text appendString:[[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding]];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName {
    BLXContentHandler textHandler = [self _handlerForEvent:BLXParserContentEvent];
    
    if (textHandler != nil) {
        NSMutableDictionary *context = [[self.stack lastObject] objectForKey:BLXParserFrameContextKey];
        NSMutableString     *text    = [context objectForKey:BLXContextTextContentKey];

        textHandler(text);
    }
    
    [self _popFrame];
}

// ----------------------------------------------------------------------------
#pragma mark Stack frames handling

- (void)_pushFrame {
    NSMutableDictionary *frame = [NSMutableDictionary dictionary];
    [frame setObject:[NSMutableDictionary dictionary] forKey:BLXParserFrameHandlersKey];
    [frame setObject:[NSMutableDictionary dictionary] forKey:BLXParserInheritedHandlersKey];
    
    NSMutableDictionary *context = [NSMutableDictionary dictionary];
    [frame setObject:context forKey:BLXParserFrameContextKey];
    [context setObject:[NSMutableString string] forKey:BLXContextTextContentKey];
    
    [self.stack addObject:frame];
}

- (void)_popFrame {
    [self.stack removeLastObject];
}

// ----------------------------------------------------------------------------

@end

// ============================================================================

NSString *BLXContextAttributesKey = @"BLXContextAttributesKey";
NSString *BLXContextTextContentKey = @"BLXContextTextContentKey";

// ============================================================================
