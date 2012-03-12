//
//  PMPKVOTests.m
//  PMPKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 Pumptheory Pty Ltd. All rights reserved.
//

#import "PMPKVOTests.h"

#import "TestObservee.h"

@interface PMPKVOTests ()

@property (retain) TestObservee * observee;
@property BOOL changeObserved;
@property (retain) NSArray * testSelectors;
@property NSInteger currentTestSelectorIndex;

- (void)next;
- (void)checkObservationAndNext;
- (void)test1NormalKVO;

@end


@implementation PMPKVOTests

@synthesize observee;
@synthesize changeObserved;
@synthesize testSelectors;
@synthesize currentTestSelectorIndex;

- (void)test1NormalKVO
{
    self.observee = [[[TestObservee alloc] init] autorelease];
    self.observee.observeMe = @"Orig text";
    
    [self.observee addObserver:self forKeyPath:@"observeMe" options:0 context:NULL];
    
    self.observee.observeMe = @"New text";
    
    [self checkObservationAndNext];
}

- (void)test1cleanup
{
    [self.observee removeObserver:self forKeyPath:@"observeMe"];
    self.observee = nil; // shouldn't cause any KVO warnings in console
    
    [self next];
}

/*
 *
 * Machinery
 *
 */

- (void)runTests
{
    self.testSelectors = [NSArray arrayWithObjects:
                          @"test1NormalKVO",
                          @"test1cleanup",
                          nil];
    
    self.currentTestSelectorIndex = -1;
    [self next];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSAssert(object == self.observee, @"recieved change notification for a different object");
    self.changeObserved = YES;
}

- (void)_next
{
    self.currentTestSelectorIndex++;
    if (self.currentTestSelectorIndex < [self.testSelectors count])
    {
        NSString * selector = [self.testSelectors objectAtIndex:self.currentTestSelectorIndex];
        NSLog(@"Running test method: %@", selector); //TODO: log to window
        [self performSelector:NSSelectorFromString(selector)];
    }
    else
    {
        NSAlert * alert = [NSAlert alertWithMessageText:@"Tests complete"
                                          defaultButton:@"Cool"
                                        alternateButton:nil
                                            otherButton:nil
                              informativeTextWithFormat:@"Make sure you check the logs for KVO warnings"];
        [alert runModal];
    }
}

- (void)next
{
    [self performSelector:@selector(_next) withObject:nil afterDelay:0];
}

- (void)_checkObservationAndNext
{
    NSAssert(self.changeObserved, @"No change observed");
    
    NSLog(@"Confirmed change observation");
    
    self.changeObserved = NO;
    
    [self _next];
}

- (void)checkObservationAndNext
{
    [self performSelector:@selector(_checkObservationAndNext) withObject:nil afterDelay:0];
}

@end
