//
//  PMPAppDelegate.m
//  PMPKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 Pumptheory Pty Ltd. All rights reserved.
//

#import "PMPAppDelegate.h"

#import "PMPKVOTests.h"

@interface PMPAppDelegate ()

@property (strong) PMPKVOTests * tests;

@end


@implementation PMPAppDelegate

@synthesize window = _window;
@synthesize tests;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.tests = [[PMPKVOTests alloc] init];
    [self.tests runTests];
}

- (IBAction)reRunTests:(id)sender
{
    [self.tests runTests];
}

@end
