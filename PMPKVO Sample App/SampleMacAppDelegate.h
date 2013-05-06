//
//  HTBAppDelegate.h
//  HTBKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 The High Technology Bureau. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SampleMacAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;

- (IBAction)reRunTests:(id)sender;

@end
