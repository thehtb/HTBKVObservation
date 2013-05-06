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
#import "TestBinder.h"

#import <libextobjc/EXTScope.h>

@interface PMPKVOTests ()

@property (nonatomic, strong) TestObservee * observee;
@property BOOL test1ChangeObserved;
@property (nonatomic, strong, readonly) NSArray * testSelectors;
@property (nonatomic) NSInteger currentTestSelectorIndex;
@property (nonatomic, strong) PMPKVObservation * kvo;

- (void)next;
- (void)checkObservationAndNext:(BOOL)changeObserved;
- (NSString *)currentTest;

@end


@implementation PMPKVOTests

- (NSArray *)testSelectors
{
    return @[
             @"test1NormalKVO",
             @"test1cleanup",
             @"test2simpleBlockObservation",
             @"test2cleanup",
             @"test3helperMethodSimpleBlockObservation",
             @"test3cleanup",
             @"test4uniDirectionalBinding",
             @"test5biDirectionalBinding",
             @"test6releaseObjectBFirst",
             @"test7releaseBindingsFirst",
             ];
}

- (void)test1NormalKVO
{
    self.test1ChangeObserved = NO;
    self.observee = [[TestObservee alloc] init];
    self.observee.observeMe = @"Steve Wozniak";
    
    [self.observee addObserver:self forKeyPath:@"observeMe" options:0 context:(void *)1];
    
    self.observee.observeMe = @"Steve Jobs";
    
    [self checkObservationAndNext:self.test1ChangeObserved];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // checking context to make sure we don't get called for PMPKVO
    NSAssert(object == self.observee && context == (void *)1, @"recieved wrong kvo");
    self.test1ChangeObserved = YES;
}

- (void)test1cleanup
{
    [self.observee removeObserver:self forKeyPath:@"observeMe"];
    self.observee = nil; // shouldn't cause any KVO warnings in console
    
    [self next];
}

- (void)test2simpleBlockObservation
{
    self.observee = [[TestObservee alloc] init];
    self.observee.observeMe = @"Bill Atkinson";
    
    self.kvo = [[PMPKVObservation alloc] init];
    self.kvo.observedObject = self.observee;
    self.kvo.keyPath = @"observeMe";
    
    __block BOOL changeObserved;
    @weakify(self)
    
    [self.kvo setCallbackBlock:^(PMPKVObservation * obs, NSDictionary * change) {
        @strongify(self)

        if (! [[self currentTest] isEqualToString:@"test2simpleBlockObservation"])
        {
            NSLog(@"received wrong kvo");
            [NSException raise:@"received wrong kvo" format:NULL];
        }
        changeObserved = YES;
    }];
    
    [self.kvo observe];
    
    self.observee.observeMe = @"Burrell Smith";
    
    [self checkObservationAndNext:changeObserved];
}

- (void)test2cleanup
{
    self.kvo = nil; // will remove the observation
    self.observee = nil; // shouldn't cause any KVO warnings in console
    
    [self next];
}

- (void)test3helperMethodSimpleBlockObservation
{
    self.observee = [[TestObservee alloc] init];
    self.observee.observeMe = @"Susan Kare";
    
    __block BOOL changeObserved;
    @weakify(self)
    
    self.kvo = [PMPKVObservation observe:self.observee
                                 keyPath:@"observeMe"
                                 options:0
                                callback:^(PMPKVObservation *observation, NSDictionary *changeDictionary) {
                                    @strongify(self)
                                    NSAssert([[self currentTest] isEqualToString:@"test3helperMethodSimpleBlockObservation"], @"received wrong kvo");
                                    changeObserved = YES;
                                }];
        
    self.observee.observeMe = @"Bill Budge";
    
    [self checkObservationAndNext:changeObserved];
}

- (void)test3cleanup
{
    self.kvo = nil; // will remove the observation
    self.observee = nil; // shouldn't cause any KVO warnings in console
    
    [self next];
}

- (void)test4uniDirectionalBinding
{
    TestObservee * obs;
    TestBinder * binder;
    PMPKVObservation * kvo;
    
    @autoreleasepool
    {
        obs = [[TestObservee alloc] init];
        obs.observeMe = @"Budd Tribble";
        
        binder = [[TestBinder alloc] init];
        kvo = [PMPKVObservation bind:obs keyPath:@"observeMe" toObject:binder keyPath:@"targetString"];
        
        NSAssert([binder.targetString isEqualToString:@"Budd Tribble"], @"Initial value not set on binder");
        
        obs.observeMe = @"Steve Capps";
        
        NSAssert([binder.targetString isEqualToString:@"Steve Capps"], @"Next value not set on binder");
        
        // removing the objects should clear the kvo automatically
        obs = nil; // shouldn't cause any KVO warnings in console
        
        // the observation isn't actually released until the autorelease pool exits since it's an autoreleased convenience method
    }
    
    NSAssert(!kvo.isValid, @"KVO Object still marked as valid even after observee cleared");
    
    binder = nil; // shouldn't cause any KVO warnings in console
    
    kvo = nil;
    
    [self next];
}

- (void)test5biDirectionalBinding
{
    TestObservee * objectA;
    TestBinder * objectB;
    NSArray * bindings;
    
    @autoreleasepool
    {
        objectA = [[TestObservee alloc] init];
        objectA.observeMe = @"Chris Espinosa";
        
        objectB = [[TestBinder alloc] init];
        objectB.targetString = @"Andy Hertzfeld";
        
        bindings = [PMPKVObservation bidirectionallyBind:objectA keyPath:@"observeMe" withObject:objectB keyPath:@"targetString"];
        
        NSAssert(bindings, @"bidirectionallyBind convenience method returned nil");
        
        NSAssert([objectA.observeMe isEqualToString:@"Chris Espinosa"], @"After creating the binding, objectA's property should be unchanged");
        NSAssert([objectB.targetString isEqualToString:@"Chris Espinosa"], @"After creating the binding, objectB's property should equal objectA's");
        
        objectA.observeMe = @"Bruce Horn";
        NSAssert([objectB.targetString isEqualToString:@"Bruce Horn"], @"Setting objectA's property updates objectB's");
        
        objectB.targetString = @"Joanna Hoffman";
        NSAssert([objectA.observeMe isEqualToString:@"Joanna Hoffman"], @"Setting object B's property updates object A's");
        
        objectA = nil; // releasing objectA first should generate no KVO warnings
    }
    
    objectB = nil;
    bindings = nil;
    
    [self next];
}

- (void)test6releaseObjectBFirst
{
    TestObservee * objectA;
    TestBinder * objectB;
    NSArray * bindings;
    
    @autoreleasepool
    {
        objectA = [[TestObservee alloc] init];
        objectA.observeMe = @"Randy Wigginton";
        
        objectB = [[TestBinder alloc] init];
        objectB.targetString = @"Jef Raskin";
        
        bindings = [PMPKVObservation bidirectionallyBind:objectA keyPath:@"observeMe" withObject:objectB keyPath:@"targetString"];
        
        NSAssert(bindings, @"bidirectionallyBind convenience method returned nil");
        
        NSAssert([objectA.observeMe isEqualToString:@"Randy Wigginton"], @"After creating the binding, objectA's property should be unchanged");
        NSAssert([objectB.targetString isEqualToString:@"Randy Wigginton"], @"After creating the binding, objectB's property should equal objectA's");
        
        objectA.observeMe = @"Mark Markkula";
        NSAssert([objectB.targetString isEqualToString:@"Mark Markkula"], @"Setting objectA's property updates objectB's");
        
        objectB.targetString = @"Caroline Rose";
        NSAssert([objectA.observeMe isEqualToString:@"Caroline Rose"], @"Setting object B's property updates object A's");
        
        objectB = nil; // releasing objectA first should generate no KVO warnings
    }
    
    objectA = nil;
    bindings = nil;
    
    [self next];
}

- (void)test7releaseBindingsFirst
{
    TestObservee * objectA;
    TestBinder * objectB;
    NSArray * bindings;
    
    @autoreleasepool
    {
        objectA = [[TestObservee alloc] init];
        objectA.observeMe = @"Clarus";
        
        objectB = [[TestBinder alloc] init];
        objectB.targetString = @"Moof";
        
        bindings = [PMPKVObservation bidirectionallyBind:objectA keyPath:@"observeMe" withObject:objectB keyPath:@"targetString"];
        
        NSAssert(bindings, @"bidirectionallyBind convenience method returned nil");
        
        NSAssert([objectA.observeMe isEqualToString:@"Clarus"], @"After creating the binding, objectA's property should be unchanged");
        NSAssert([objectB.targetString isEqualToString:@"Clarus"], @"After creating the binding, objectB's property should equal objectA's");
        
        objectA.observeMe = @"MacMan";
        NSAssert([objectB.targetString isEqualToString:@"MacMan"], @"Setting objectA's property updates objectB's");
        
        objectB.targetString = @"Dan Kottke";
        NSAssert([objectA.observeMe isEqualToString:@"Dan Kottke"], @"Setting object B's property updates object A's");
        
        bindings = nil;
    }
    
    objectA = nil;
    objectB = nil;
    
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

- (void)checkObservationAndNext:(BOOL)changeObserved
{
    NSAssert(changeObserved, @"No change observed");
    
    NSLog(@"Confirmed change observation");
    
    [self _next];
}

@end
