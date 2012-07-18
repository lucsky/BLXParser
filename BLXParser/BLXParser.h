//
//  BLXParser.h
//  BLXParser
//
//  Created by Luc Heinrich on 12/07/12.
//  Copyright (c) 2012 Telephasic Workshop. All rights reserved.
//

#import <Foundation/Foundation.h>

// ============================================================================

typedef void (^BLXElementHandler)(NSDictionary *attributes);
typedef void (^BLXTextHandler)(NSString *text);
typedef void (^BLXCDATAHandler)(NSData *CDATABlock);
typedef void (^BLXContentHandler)(NSString *content);

// ----------------------------------------------------------------------------

@interface BLXParser : NSObject 

// Parser creation and initialization

+ (id)parserWithContentsOfURL:(NSURL *)url;
- (id)initWithContentsOfURL:(NSURL *)url;

+ (id)parserWithData:(NSData *)data;
- (id)initWithData:(NSData *)data;

+ (id)parserWithStream:(NSInputStream *)stream;
- (id)initWithStream:(NSInputStream *)stream;

// Handler definitions

- (void)on:(NSString *)tagName call:(BLXElementHandler)handler;

- (void)onText:(BLXTextHandler)handler;
- (void)onTextOf:(NSString *)tagName call:(BLXTextHandler)handler;
- (void)onCDATA:(BLXCDATAHandler)handler;
- (void)onCDATAOf:(NSString *)tagName call:(BLXCDATAHandler)handler;
- (void)onContent:(BLXContentHandler)handler;
- (void)onContentOf:(NSString *)tagName call:(BLXContentHandler)handler;

- (void)onAny:(NSString *)tagName call:(BLXElementHandler)handler;

- (void)onTextOfAny:(NSString *)tagName call:(BLXTextHandler)handler;
- (void)onCDATAOfAny:(NSString *)tagName call:(BLXCDATAHandler)handler;
- (void)onContentOfAny:(NSString *)tagName call:(BLXContentHandler)handler;

// Parsing

- (void)start;

@end

// ============================================================================

extern NSString *BLXContextAttributesKey;
extern NSString *BLXContextTextContentKey;

// ============================================================================
