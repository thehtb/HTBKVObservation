//
//  PMPKVO.m
//  PMPKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 Pumptheory Pty Ltd. All rights reserved.
//

#import "PMPKVObservation.h"

@interface PMPKVObservation ()

- (void)setIsValid:(BOOL)isValid;


@end

@implementation PMPKVObservation

@synthesize observer=_observer;
@synthesize observee=_observee;
@synthesize keyPath=_keyPath;
@synthesize options=_options;
@synthesize selector=_selector;
@synthesize isValid=_isValid;

- (id)init
{
    if ((self = [super init]))
    {
        _isValid = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [self invalidate];
    [_keyPath release], _keyPath = nil;
    
    [super dealloc];
}

- (void)setIsValid:(BOOL)isValid
{
    if (isValid == _isValid)
        return;
    
    [self willChangeValueForKey:@"isValid"];
    _isValid = isValid;
    [self didChangeValueForKey:@"isValid"];
}

- (BOOL)observe
{
    if (!_isValid && // can't re-observe
        _observee &&
        _observer &&
        _keyPath &&
        _selector)
    {
        [self.observee addObserver:self forKeyPath:self.keyPath options:self.options context:NULL];
    
        //TODO: add associated object on observee and swizzle dealloc
        
        [self setIsValid:YES];
    
        return YES;
    }
    
    return NO;
}

- (void)invalidate
{
    if (![self isValid])
        return;
    
    [self setIsValid:NO];
    
    [[self observee] removeObserver:self forKeyPath:self.keyPath];
    
    //TODO: remove associated object on observee
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([self.keyPath isEqualToString:keyPath] && self.observee == object)
        [self.observer performSelector:self.selector withObject:object withObject:change];
    else
        NSLog(@"PMPKVObservation: received observation for unexpected keyPath (%@) or object (%@)", keyPath, object);
}

@end
