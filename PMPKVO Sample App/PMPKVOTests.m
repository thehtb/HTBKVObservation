//
//  PMPKVOTests.m
//  PMPKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 Pumptheory Pty Ltd. All rights reserved.
//

#import "PMPKVOTests.h"

#import "TestObservee.h"
#import "PMPKVObservation.h"

@interface PMPKVOTests ()

@property (strong) TestObservee * observee;
@property BOOL changeObserved;
@property (strong, readonly) NSArray * testSelectors;
@property NSInteger currentTestSelectorIndex;
@property (strong) PMPKVObservation * kvo;

- (void)next;
- (void)checkObservationAndNext;
- (NSString *)currentTest;

@end


@implementation PMPKVOTests

@synthesize observee;
@synthesize changeObserved;
@synthesize currentTestSelectorIndex;
@synthesize kvo = _kvo;

- (NSArray *)testSelectors
{
    return [NSArray arrayWithObjects:
            @"test1NormalKVO",
            @"test1cleanup",
            @"test4simpleBlockObservation",
            @"test4cleanup",
            @"test5helperMethodSimpleBlockObservation",
            @"test5cleanup",
            nil];
}

- (void)test1NormalKVO
{
    self.observee = [[TestObservee alloc] init];
    self.observee.observeMe = @"Orig text";
    
    [self.observee addObserver:self forKeyPath:@"observeMe" options:0 context:(void *)1];
    
    self.observee.observeMe = @"New text";
    
    [self checkObservationAndNext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // checking context to make sure we don't get called for PMPKVO
    NSAssert(object == self.observee && context == (void *)1, @"recieved wrong kvo");
    self.changeObserved = YES;
}

- (void)test1cleanup
{
    [self.observee removeObserver:self forKeyPath:@"observeMe"];
    self.observee = nil; // shouldn't cause any KVO warnings in console
    
    [self next];
}

- (void)test4simpleBlockObservation
{
    self.observee = [[TestObservee alloc] init];
    self.observee.observeMe = @"Orig text";
    
    self.kvo = [[PMPKVObservation alloc] init];
    self.kvo.observedObject = self.observee;
    self.kvo.keyPath = @"observeMe";
    
    __weak PMPKVOTests * _self = self;
    
    [self.kvo setCallbackBlock:^(PMPKVObservation * obs, NSDictionary * change) {
        // NSAssert causes a self retain cycle :(
        if (! [[_self currentTest] isEqualToString:@"test4simpleBlockObservation"])
        {
            NSLog(@"received wrong kvo");
            [NSException raise:@"received wrong kvo" format:NULL];
        }
    }];
    
    [self.kvo observe];
    
    self.observee.observeMe = @"New text";
    
    //[self checkObservationAndNext];
    [self next];
}

- (void)test4cleanup
{
    self.kvo = nil; // will remove the observation
    self.observee = nil; // shouldn't cause any KVO warnings in console
    
    [self next];
}

- (void)test5helperMethodSimpleBlockObservation
{
    self.observee = [[TestObservee alloc] init];
    self.observee.observeMe = @"Orig text";
    
    __block typeof(self) _self = self;
    
    self.kvo = [PMPKVObservation observe:self.observee
                                 keyPath:@"observeMe"
                                 options:0
                                callback:^(PMPKVObservation *observation, NSDictionary *changeDictionary) {
                                    NSAssert([[_self currentTest] isEqualToString:@"test5helperMethodSimpleBlockObservation"], @"received wrong kvo");
                                    _self.changeObserved = YES;
                                }];
        
    self.observee.observeMe = @"New text";
    
    //[self checkObservationAndNext];
    [self next];
}

- (void)test5cleanup
{
    self.kvo = nil; // will remove the observation
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
    self.currentTestSelectorIndex = -1;
    [self next];
}

- (NSString *)currentTest
{
    return [self.testSelectors objectAtIndex:self.currentTestSelectorIndex];
}

// NB: doing all this in seperate runloop cycles to make sure not-yet autoreleased objects
//     don't mask any issues

- (void)_next
{
    self.currentTestSelectorIndex++;
    if (self.currentTestSelectorIndex < [self.testSelectors count])
    {
        NSLog(@"Running test method: %@", [self currentTest]); //TODO: log to window
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:NSSelectorFromString([self currentTest])];
#pragma clang diagnostic pop
    }
    else
    {

#if TARGET_OS_IPHONE
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Tests complete"
                                                         message:@"Make sure you check the logs for KVO warnings"
                                                        delegate:nil
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"Cool", nil];
        [alert show];
#else
        NSAlert * alert = [NSAlert alertWithMessageText:@"Tests complete"
                                          defaultButton:@"Cool"
                                        alternateButton:nil
                                            otherButton:nil
                              informativeTextWithFormat:@"Make sure you check the logs for KVO warnings"];
        [alert runModal];
#endif
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
