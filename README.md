BLXParser, a block based event driven XML parsing API for MacOS/iOS.
====================================================================

BLXParser (**BL**ock-based **X**ML **Parser**) provides an intuitive block based XML parsing API which sits on top of the standard event based NSXMLParser, allowing to massively simplify XML parsing code while retaining the raw speed and low memory overhead of the underlying SAX parser. BLXParser takes care of the complex task of maintaining contexts between SAX event handlers so you can concentrate on the actual structure of the XML document.

Example:
--------

Consider the following contrived example of an XML document:

``` xml
<?xml version="1.0"?>
<address-book name="homies">
    <contact>
        <first-name>Tim</first-name>
        <last-name>Cook</last-name>
        <address>Cupertino</address>
    </contact>
    <contact>
        <first-name>Steve</first-name>
        <last-name>Ballmer</last-name>
        <address>Redmond</address>
    </contact>
    <contact>
        <first-name>Mark</first-name>
        <last-name>Zuckerberg</last-name>
        <address>Menlo Park</address>
    </contact>
</address-book>
```

A typical way to parse this with BLXParser would be:

``` objective-c
NSURL     *url    = [NSURL fileURLWithPath:@"homies.xml"]
BLXParser *parser = [BLXParser parserWithContentsOfURL:url];

__block NSMutableDictionary *addressBook = nil;

[parser on:@"address-book" call:^(NSDictionary *attributes) {
    addressBook = [NSMutableDictionary dictionary];
    [addressBook setObject:[attributes objectForKey:@"name"] forKey:@"name"];

    NSMutableArray *contacts = [NSMutableArray array];
    [addressBook setObject:contacts forKey:@"contacts"];

    [parser on:@"contact" call:^(NSDictionary *attributes) {
        NSMutableDictionary *contact = [NSMutableDictionary dictionary];
        [contacts addObject:contact];

        [parser on:@"first-name" call:^(NSDictionary *attributes) {
            [parser onContent:^(NSString *text) {
                [contacts setObject:text forKey:@"first-name"];
            }];
        }];

        [parser on:@"last-name" call:^(NSDictionary *attributes) {
            [parser onContent:^(NSString *text) {
                [contacts setObject:text forKey:@"last-name"];
            }];
        }];

        [parser on:@"address" call:^(NSDictionary *attributes) {
            [parser onContent:^(NSString *text) {
                [contacts setObject:text forKey:@"address"];
            }];
        }];
    }];
}];

[parser start];
```

BLXParser provides quite a bunch of shortcut allowing to cut down on the most common cases:

``` objective-c
[parser on:@"address-book" call:^(NSDictionary *attributes) {
    ...
    ...
    [parser on:@"contact" call:^(NSDictionary *attributes) {
        NSMutableDictionary *contact = [NSMutableDictionary dictionary];
        [contacts addObject:contact];

        [parser onContentOf:@"first-name" call:^(NSString *text) {
            [contacts setObject:text forKey:@"first-name"];
        }];

        [parser onContentOf:@"last-name" call:^(NSString *text) {
            [contacts setObject:text forKey:@"last-name"];
        }];

        [parser onContentOf:@"address" call:^(NSString *text) {
            [contacts setObject:text forKey:@"address"];
        }];
    }];
}];
```

You can also completely ignore some parent nodes and go straight to the nodes that interest you:

``` objective-c
NSMutableArray *contacts = [NSMutableArray array];
[parser onAny:@"contact" call:^(NSDictionary *attributes) {
    NSMutableDictionary *contact = [NSMutableDictionary dictionary];
    [contacts addObject:contact];

    [parser onContentOf:@"first-name" call:^(NSString *text) {
        [contacts setObject:text forKey:@"first-name"];
    }];

    [parser onContentOf:@"last-name" call:^(NSString *text) {
        [contacts setObject:text forKey:@"last-name"];
    }];

    [parser onContentOf:@"address" call:^(NSString *text) {
        [contacts setObject:text forKey:@"address"];
    }];
}];
```

See the `BLXParser.h` header for the complete API.
