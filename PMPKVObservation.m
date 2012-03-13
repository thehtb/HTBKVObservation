//
//  PMPKVO.m
//  PMPKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 Pumptheory Pty Ltd. All rights reserved.
//

#import "PMPKVObservation.h"

#import <objc/runtime.h>

const NSString * PMPKVObservationClassIsSwizzledKey = @"PMPKVObservationClassIsSwizzledKey";
const NSString * PMPKVObservationObjectObserversKey = @"PMPKVObservationObjectObserversKey";

@interface PMPKVObservation ()

- (void)setIsValid:(BOOL)isValid;
- (void)prepareObserveeObjectAndClass;
- (void)_invalidateAndRemoveTargetAssociations:(BOOL)removeTargetAssociations;

@end

@implementation PMPKVObservation

@synthesize observee=_observee;
@synthesize observer=_observer;
@synthesize selector=_selector;
@synthesize callbackBlock=_callbackBlock;
@synthesize keyPath=_keyPath;
@synthesize options=_options;
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

#if ! __has_feature(objc_arc)
    [_keyPath release];
    [_callbackBlock release];
#endif
    
    _keyPath = nil;
    _callbackBlock = nil;
    
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)setIsValid:(BOOL)isValid
{
    if (isValid == _isValid)
        return;
    
    [self willChangeValueForKey:@"isValid"];
    _isValid = isValid;
    [self didChangeValueForKey:@"isValid"];
}

- (void)prepareObserveeObjectAndClass
{
    Class class = [_observee class];
    
    @synchronized(PMPKVObservationClassIsSwizzledKey)
    {
        NSNumber * classIsSwizzled = objc_getAssociatedObject(class, PMPKVObservationClassIsSwizzledKey);
        if (!classIsSwizzled)
        {
            SEL deallocSel = NSSelectorFromString(@"dealloc");
            Method dealloc = class_getInstanceMethod(class, deallocSel);
            IMP origImpl = method_getImplementation(dealloc);
            IMP newImpl = imp_implementationWithBlock((__bridge void *)^ (void *obj)
                                                      {
                                                          @autoreleasepool
                                                          {
                                                              // I guess there is a possible race condition here with an observation being added *during* dealloc.
                                                              // The copy means we won't crash here, but I imagine the observation will fail.
                                                              
                                                              NSHashTable * observeeObserverTrackingHashTable;
                                                              @synchronized(observeeObserverTrackingHashTable)
                                                              {
                                                                  observeeObserverTrackingHashTable = [objc_getAssociatedObject(obj, PMPKVObservationObjectObserversKey) copy];
                                                              }
                                                              
                                                              for (PMPKVObservation * observation in observeeObserverTrackingHashTable)
                                                              {
                                                                  NSLog(@"Invalidating an observer in the swizzled dealloc");
                                                                  [observation _invalidateAndRemoveTargetAssociations:NO];
                                                              }
                                                          }
                                                          ((void (*)(void *, SEL))origImpl)(obj, deallocSel);
                                                      });
            
            class_replaceMethod(class, deallocSel, newImpl, method_getTypeEncoding(dealloc));
            
            objc_setAssociatedObject(class, PMPKVObservationClassIsSwizzledKey, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN);
        }
        
        // create the NSHashTable if needed - NSHashTable (when created as below) is bascially an NSMutableSet with weak references (doesn't require ARC)
        
        if (!objc_getAssociatedObject(_observee, PMPKVObservationObjectObserversKey))
        {
            NSHashTable * observeeObserverTrackingHashTable = [NSHashTable hashTableWithWeakObjects];
            objc_setAssociatedObject(_observee, PMPKVObservationObjectObserversKey, observeeObserverTrackingHashTable, OBJC_ASSOCIATION_RETAIN);
        }
    }
}

- (BOOL)observe
{
    if (!_isValid && // can't re-observe
        _observee &&
        _keyPath &&
        ((_observer && _selector) || _callbackBlock))
    {
        // only swizzling the target dealloc for it to remove all observers - releasing/invalidating at the observer end
        // is its own responsibility

        [self prepareObserveeObjectAndClass];
        
        [_observee addObserver:self forKeyPath:_keyPath options:_options context:NULL];
    
        NSHashTable * observeeObserverTrackingHashTable = objc_getAssociatedObject(_observee, PMPKVObservationObjectObserversKey);
        
        @synchronized(observeeObserverTrackingHashTable)
        {
            [observeeObserverTrackingHashTable addObject:self];
        }
        
        [self setIsValid:YES];
    
        return YES;
    }
    
    return NO;
}

- (void)invalidate
{
    [self _invalidateAndRemoveTargetAssociations:YES];
}

- (void)_invalidateAndRemoveTargetAssociations:(BOOL)removeTargetAssociations
{
    if (![self isValid])
        return;
    
    [self setIsValid:NO];
    
    [[self observee] removeObserver:self forKeyPath:self.keyPath];
    
    if (removeTargetAssociations)
    {
        NSHashTable * observeeObserverTrackingHashTable = objc_getAssociatedObject(_observee, PMPKVObservationObjectObserversKey);
        
        @synchronized(observeeObserverTrackingHashTable)
        {
            [observeeObserverTrackingHashTable removeObject:self];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([_keyPath isEqualToString:keyPath] && _observee == object)
    {
        if (_callbackBlock)
            _callbackBlock(self, change);
        else
            [_observer performSelector:_selector withObject:self withObject:change];
    }
    else
    {
        NSLog(@"PMPKVObservation: received observation for unexpected keyPath (%@) or object (%@)", keyPath, object);
    }
}

@end
