//
//  BLXParserTests.m
//  BLXParserTests
//
//  Created by Luc Heinrich on 12/07/12.
//  Copyright (c) 2012 Telephasic Workshop. All rights reserved.
//

#import "BLXParserTests.h"
#import "BLXParser.h"

// ============================================================================

@implementation BLXParserTests

// ----------------------------------------------------------------------------
#pragma mark Parsing from different sources

- (void)testParseWithURL {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test1"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];

    STAssertNotNil(parser, @"BLXParser instance creation with NSURL failed");
    [self _parseWithParser:parser];
}

- (void)testParseWithData {
    NSData    *data   = [NSData dataWithContentsOfFile:[self _pathToTestFileNamed:@"test1"]];
    BLXParser *parser = [BLXParser parserWithData:data];

    STAssertNotNil(parser, @"BLXParser instance creation with NSData failed");
    [self _parseWithParser:parser];
}

- (void)testParseWithStream {
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:[self _pathToTestFileNamed:@"test1"]];
    BLXParser     *parser = [BLXParser parserWithStream:stream];

    STAssertNotNil(parser, @"BLXParser instance creation with NSInputStream failed");
    [self _parseWithParser:parser];
}

- (void)_parseWithParser:(BLXParser *)parser {
    [parser on:@"contacts" call:^(NSDictionary *attributes) {
        STAssertNotNil(attributes, @"Attributes not present");
    }];
}

// ----------------------------------------------------------------------------
#pragma mark Simple parsing

- (void)testSimpleParsing {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test1"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];

    // Parse data

    __block NSMutableDictionary *root = nil;
    
    [parser on:@"root" call:^(NSDictionary *attributes) {
        root = [NSMutableDictionary dictionary];
        [root setObject:[attributes objectForKey:@"attr1"] forKey:@"attr1"];
        [root setObject:[attributes objectForKey:@"attr2"] forKey:@"attr2"];
        
        NSMutableArray *list = [NSMutableArray array];
        [root setObject:list forKey:@"list"];

        [parser on:@"node" call:^(NSDictionary *attributes) {
            NSMutableDictionary *node = [NSMutableDictionary dictionary];
            [node setObject:[attributes objectForKey:@"attr1"] forKey:@"attr1"];
            [node setObject:[attributes objectForKey:@"attr2"] forKey:@"attr2"];
            
            [list addObject:node];
        }];
    }];

    [parser start];

    // Check parsed data
    
    STAssertNotNil(root, @"Parsing error");
    STAssertEquals([root count], (NSUInteger)3, @"Incorrect number of root attributes");
    STAssertEqualObjects([root objectForKey:@"attr1"], @"root.attr1", @"Incorrect attribute");
    STAssertEqualObjects([root objectForKey:@"attr2"], @"root.attr2", @"Incorrect attribute");
    
    NSArray *list = [root objectForKey:@"list"];
    STAssertEquals([list count], (NSUInteger)3, @"Incorrect number of nodes");
    
    NSDictionary *node = [list objectAtIndex:0];
    STAssertEquals([node count], (NSUInteger)2, @"Incorrect number of node attributes");
    STAssertEqualObjects([node objectForKey:@"attr1"], @"node1.attr1", @"Incorrect node attribute");
    STAssertEqualObjects([node objectForKey:@"attr2"], @"node1.attr2", @"Incorrect node attribute");

    node = [list objectAtIndex:1];
    STAssertEquals([node count], (NSUInteger)2, @"Incorrect number of contact attributes");
    STAssertEqualObjects([node objectForKey:@"attr1"], @"node2.attr1", @"Incorrect node attribute");
    STAssertEqualObjects([node objectForKey:@"attr2"], @"node2.attr2", @"Incorrect node attribute");

    node = [list objectAtIndex:2];
    STAssertEquals([node count], (NSUInteger)2, @"Incorrect number of contact attributes");
    STAssertEqualObjects([node objectForKey:@"attr1"], @"node3.attr1", @"Incorrect node attribute");
    STAssertEqualObjects([node objectForKey:@"attr2"], @"node3.attr2", @"Incorrect node attribute");
}

// ----------------------------------------------------------------------------
#pragma mark Simple text content parsing

- (void)testSimpleTextParsing {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test2"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];
    
    // Parse data
    
    __block NSMutableArray *nodes = nil;
    
    [parser on:@"root" call:^(NSDictionary *attributes) {
        nodes = [NSMutableArray array];
        [parser on:@"node" call:^(NSDictionary *attributes) {
            [parser onText:^(NSString *text) {
                [nodes addObject:text];
            }];
        }];
    }];
    
    [parser start];
    
    // Check parsed data
    
    STAssertNotNil(nodes, @"Error when parsing nodes");
    STAssertEquals([nodes count], (NSUInteger)3, @"Incorrect number of nodes");
    STAssertEqualObjects([nodes objectAtIndex:0], @"text content 1", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:1], @"text content 2", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:2], @"text content 3", @"Incorrect node content");
}

- (void)testSimpleCDATAParsing {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test3"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];
    
    // Parse data
    
    __block NSMutableArray *nodes = nil;
    
    [parser on:@"root" call:^(NSDictionary *attributes) {
        nodes = [NSMutableArray array];
        [parser on:@"node" call:^(NSDictionary *attributes) {
            [parser onCDATA:^(NSData *CDATABlock) {
                [nodes addObject:[[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding]];
            }];
        }];
    }];
    
    [parser start];
    
    // Check parsed data
    
    STAssertNotNil(nodes, @"Error when parsing nodes");
    STAssertEquals([nodes count], (NSUInteger)3, @"Incorrect number of nodes");
    STAssertEqualObjects([nodes objectAtIndex:0], @"CDATA content 1", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:1], @"CDATA content 2", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:2], @"CDATA content 3", @"Incorrect node content");
}

- (void)testSimpleAggregatedContentParsing {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test4"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];

    // Parse data
    
    __block NSMutableArray *nodes = nil;

    [parser on:@"root" call:^(NSDictionary *attributes) {
        nodes = [NSMutableArray array];
        [parser on:@"node" call:^(NSDictionary *attributes) {
            [parser onContent:^(NSString *text) {
                [nodes addObject:text];
            }];
        }];
    }];
        
    [parser start];
    
    // Check parsed data

    STAssertNotNil(nodes, @"Error when parsing nodes");
    STAssertEquals([nodes count], (NSUInteger)3, @"Incorrect number of nodes");
    STAssertEqualObjects([nodes objectAtIndex:0], @"aggregated content 1", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:1], @"aggregated content 2", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:2], @"aggregated content 3", @"Incorrect node content");
}

// ----------------------------------------------------------------------------
#pragma mark Shortcut text content parsing

- (void)testShortcutTextParsing {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test2"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];
    
    // Parse data
    
    __block NSMutableArray *nodes = nil;
    
    [parser on:@"root" call:^(NSDictionary *attributes) {
        nodes = [NSMutableArray array];
        [parser onTextOf:@"node" call:^(NSString *text) {
            [nodes addObject:text];
        }];
    }];
    
    [parser start];
    
    // Check parsed data
    
    STAssertNotNil(nodes, @"Error when parsing nodes");
    STAssertEquals([nodes count], (NSUInteger)3, @"Incorrect number of nodes");
    STAssertEqualObjects([nodes objectAtIndex:0], @"text content 1", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:1], @"text content 2", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:2], @"text content 3", @"Incorrect node content");
}

- (void)testShortcutCDATAParsing {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test3"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];
    
    // Parse data
    
    __block NSMutableArray *nodes = nil;
    
    [parser on:@"root" call:^(NSDictionary *attributes) {
        nodes = [NSMutableArray array];
        [parser onCDATAOf:@"node" call:^(NSData *CDATABlock) {
            [nodes addObject:[[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding]];
        }];
    }];
    
    [parser start];
    
    // Check parsed data
    
    STAssertNotNil(nodes, @"Error when parsing nodes");
    STAssertEquals([nodes count], (NSUInteger)3, @"Incorrect number of nodes");
    STAssertEqualObjects([nodes objectAtIndex:0], @"CDATA content 1", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:1], @"CDATA content 2", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:2], @"CDATA content 3", @"Incorrect node content");
}

- (void)testShortcutAggregatedContentParsing {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test4"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];

    // Parse data
    
    __block NSMutableArray *nodes = nil;
    
    [parser on:@"root" call:^(NSDictionary *attributes) {
        nodes = [NSMutableArray array];
        [parser onContentOf:@"node" call:^(NSString *text) {
            [nodes addObject:text];
        }];
    }];
    
    [parser start];
    
    // Check parsed data
        
    STAssertNotNil(nodes, @"Error when parsing nodes");
    STAssertEquals([nodes count], (NSUInteger)3, @"Incorrect number of nodes");
    STAssertEqualObjects([nodes objectAtIndex:0], @"aggregated content 1", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:1], @"aggregated content 2", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:2], @"aggregated content 3", @"Incorrect node content");
}

// ----------------------------------------------------------------------------
#pragma mark Parsing with inherited handlers

- (void)testInheritedHandlerParsing {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test1"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];
    
    // Parse data
    
    NSMutableArray *nodes = [NSMutableArray array];    
    [parser onAny:@"node" call:^(NSDictionary *attributes) {
        NSMutableDictionary *node = [NSMutableDictionary dictionary];
        [node setObject:[attributes objectForKey:@"attr1"] forKey:@"attr1"];
        [node setObject:[attributes objectForKey:@"attr2"] forKey:@"attr2"];
        
        [nodes addObject:node];
    }];
    
    [parser start];
    
    // Check parsed data
    
    STAssertEquals([nodes count], (NSUInteger)3, @"Incorrect number of nodes");
    
    NSDictionary *node = [nodes objectAtIndex:0];
    STAssertEquals([node count], (NSUInteger)2, @"Incorrect number of node attributes");
    STAssertEqualObjects([node objectForKey:@"attr1"], @"node1.attr1", @"Incorrect node attribute");
    STAssertEqualObjects([node objectForKey:@"attr2"], @"node1.attr2", @"Incorrect node attribute");
    
    node = [nodes objectAtIndex:1];
    STAssertEquals([node count], (NSUInteger)2, @"Incorrect number of contact attributes");
    STAssertEqualObjects([node objectForKey:@"attr1"], @"node2.attr1", @"Incorrect node attribute");
    STAssertEqualObjects([node objectForKey:@"attr2"], @"node2.attr2", @"Incorrect node attribute");
    
    node = [nodes objectAtIndex:2];
    STAssertEquals([node count], (NSUInteger)2, @"Incorrect number of contact attributes");
    STAssertEqualObjects([node objectForKey:@"attr1"], @"node3.attr1", @"Incorrect node attribute");
    STAssertEqualObjects([node objectForKey:@"attr2"], @"node3.attr2", @"Incorrect node attribute");
}

- (void)testInheritedTextParsing {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test2"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];
    
    // Parse data
    
    NSMutableArray *nodes = [NSMutableArray array];;
    [parser onTextOfAny:@"node" call:^(NSString *text) {
        [nodes addObject:text];
    }];
    
    [parser start];
    
    // Check parsed data
    
    STAssertNotNil(nodes, @"Error when parsing nodes");
    STAssertEquals([nodes count], (NSUInteger)3, @"Incorrect number of nodes");
    STAssertEqualObjects([nodes objectAtIndex:0], @"text content 1", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:1], @"text content 2", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:2], @"text content 3", @"Incorrect node content");
}

- (void)testInheritedCDATAParsing {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test3"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];
    
    // Parse data
    
    NSMutableArray *nodes = [NSMutableArray array];;
    [parser onCDATAOfAny:@"node" call:^(NSData *CDATABlock) {
        [nodes addObject:[[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding]];
    }];
    
    [parser start];
    
    // Check parsed data
    
    STAssertNotNil(nodes, @"Error when parsing nodes");
    STAssertEquals([nodes count], (NSUInteger)3, @"Incorrect number of nodes");
    STAssertEqualObjects([nodes objectAtIndex:0], @"CDATA content 1", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:1], @"CDATA content 2", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:2], @"CDATA content 3", @"Incorrect node content");
}

- (void)testInheritedAggregatedContentParsing {
    NSURL     *url    = [NSURL fileURLWithPath:[self _pathToTestFileNamed:@"test4"]];
    BLXParser *parser = [BLXParser parserWithContentsOfURL:url];
    
    // Parse data
    
    NSMutableArray *nodes = nodes = [NSMutableArray array];
    [parser onContentOfAny:@"node" call:^(NSString *textContent) {
        [nodes addObject:textContent];
    }];
    
    [parser start];
    
    // Check parsed data
    
    STAssertNotNil(nodes, @"Error when parsing nodes");
    STAssertEquals([nodes count], (NSUInteger)3, @"Incorrect number of nodes");
    STAssertEqualObjects([nodes objectAtIndex:0], @"aggregated content 1", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:1], @"aggregated content 2", @"Incorrect node content");
    STAssertEqualObjects([nodes objectAtIndex:2], @"aggregated content 3", @"Incorrect node content");
}

// ----------------------------------------------------------------------------
#pragma mark Helpers

- (NSString *)_pathToTestFileNamed:(NSString *)name {
    return [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"xml"];
}

// ----------------------------------------------------------------------------

@end

// ============================================================================
