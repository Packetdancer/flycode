//
//  JSTListener.m
//  jstalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTListener.h"
#import "JSCocoaController.h"
#import "JSTalk.h"

@interface JSTListener (Private)
- (void)setupListener;
@end


@implementation JSTListener

+ (id) sharedListener {
    static JSTListener *me = 0x00;
    if (!me) {
        debug(@"setting up listener");
        me = [[JSTListener alloc] init];
    }
    
    return me;
}

+ (void) listen {
    [[self sharedListener] setupListener];
}

CFDataRef receivedJSTalkMessage(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
    
    
    NSPropertyListFormat format;
    NSString *err = 0x00;
    
    NSDictionary *dict = [NSPropertyListSerialization propertyListFromData:(id)data
                                                          mutabilityOption:kCFPropertyListImmutable
                                                                    format:&format
                                                          errorDescription:&err];
    
    NSMutableDictionary *T = [[[dict objectForKey:@"T"] mutableCopy] autorelease];
    
    debug(@"T: %@", T);
    
    NSString *source = [dict objectForKey:@"source"];
    debug(@"source: %@", source);
    
    JSTalk *jsTalk = [[[JSTalk alloc] init] autorelease];
    
    jsTalk.T = T;
    
    [jsTalk executeString:source];
    
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    
    [ret setObject:T forKey:@"T"];
    
    err = 0x00;
    data = (CFDataRef)[[NSPropertyListSerialization dataFromPropertyList:ret
                                                                 format:NSPropertyListBinaryFormat_v1_0
                                                       errorDescription:&err] retain];
    
    return data;
}

- (void) setupListener {
    
    NSString *myBundleId    = [[NSBundle mainBundle] bundleIdentifier];
    NSString *port          = [NSString stringWithFormat:@"%@.JSTalk", myBundleId];
    
    CFMessagePortRef local  = CFMessagePortCreateLocal(NULL,  (CFStringRef)port, receivedJSTalkMessage, NULL, false);
    
    if (!local) {
        NSLog(@"Could not create JSTalk listener for %@", port);
        return;
    }
    
    CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(NULL, local, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
}

@end
