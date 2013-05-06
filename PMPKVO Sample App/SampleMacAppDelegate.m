//
//  HTBAppDelegate.m
//  HTBKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 Pumptheory Pty Ltd. All rights reserved.
//

#import "SampleMacAppDelegate.h"

#import "HTBKVOTests.h"

@interface SampleMacAppDelegate ()

@property (strong) HTBKVOTests * tests;

@end


@implementation SampleMacAppDelegate

@synthesize window = _window;
@synthesize tests;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.tests = [[HTBKVOTests alloc] init];
    [self.tests runTests];
}

- (IBAction)reRunTests:(id)sender
{
    [self.tests runTests];
}

@end
