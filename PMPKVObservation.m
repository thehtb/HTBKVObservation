//
//  PMPKVO.m
//  PMPKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 Pumptheory Pty Ltd. All rights reserved.
//

#import "PMPKVObservation.h"

#import <objc/runtime.h>

const char * PMPKVObservationClassIsSwizzledKey = "PMPKVObservationClassIsSwizzledKey";
const NSString * PMPKVObservationClassIsSwizzledLockKey = @"PMPKVObservationClassIsSwizzledLockKey";
const char * PMPKVObservationObjectObserversKey = "PMPKVObservationObjectObserversKey";

@interface PMPKVObservation ()

- (void)setIsValid:(BOOL)isValid;
- (void)prepareObserveeObjectAndClass;
- (void)_invalidateAndRemoveTargetAssociations:(BOOL)removeTargetAssociations;

@end

@implementation PMPKVObservation

@synthesize observee=_observee;
@synthesize callbackBlock=_callbackBlock;
@synthesize keyPath=_keyPath;
@synthesize options=_options;
@synthesize isValid=_isValid;

+ (PMPKVObservation *)observe:(id)observee 
                      keyPath:(NSString *)keyPath
                      options:(NSKeyValueObservingOptions)options
                     callback:(void (^)(PMPKVObservation * observation, NSDictionary * changeDictionary))callbackBlock;
{
    PMPKVObservation * obj = [[self alloc] init];
    
    obj.observee = observee;
    obj.callbackBlock = callbackBlock;
    obj.keyPath = keyPath;
    obj.options = options;
    
    if ([obj observe])
        return obj;
    
    return nil;

}


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
    
    @synchronized(PMPKVObservationClassIsSwizzledLockKey)
    {
        NSNumber * classIsSwizzled = objc_getAssociatedObject(class, PMPKVObservationClassIsSwizzledKey);
        if (!classIsSwizzled)
        {
            SEL deallocSel = NSSelectorFromString(@"dealloc");
            Method dealloc = class_getInstanceMethod(class, deallocSel);
            IMP origImpl = method_getImplementation(dealloc);
            id block = ^ (void *obj)
            {
                @autoreleasepool
                {
                    // I guess there is a possible race condition here with an observation being added *during* dealloc.
                    // The copy means we won't crash here, but I imagine the observation will fail.
                    
                    NSHashTable * observeeObserverTrackingHashTable;
                    @synchronized(observeeObserverTrackingHashTable)
                    {
                        observeeObserverTrackingHashTable = [objc_getAssociatedObject((__bridge id)obj, PMPKVObservationObjectObserversKey) copy];
                    }
                    
                    for (PMPKVObservation * observation in observeeObserverTrackingHashTable)
                    {
                        //NSLog(@"Invalidating an observer in the swizzled dealloc");
                        [observation _invalidateAndRemoveTargetAssociations:NO];
                    }
                }
                ((void (*)(void *, SEL))origImpl)(obj, deallocSel);
            };
            
            IMP newImpl = imp_implementationWithBlock(block);
            
            class_replaceMethod(class, deallocSel, newImpl, method_getTypeEncoding(dealloc));
            
            objc_setAssociatedObject(class, PMPKVObservationClassIsSwizzledKey, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN);
        }
        
        // create the NSHashTable if needed - NSHashTable (when created as below) is bascially an NSMutableSet with weak references (doesn't require ARC)
        
        if (!objc_getAssociatedObject(_observee, PMPKVObservationObjectObserversKey))
        {
#if defined(__IPHONE_6_0) || defined(__MAC_10_8)
            NSHashTable * observeeObserverTrackingHashTable = [NSHashTable weakObjectsHashTable];
#else
            NSHashTable * observeeObserverTrackingHashTable = [NSHashTable hashTableWithWeakObjects];
#endif
            objc_setAssociatedObject(_observee, PMPKVObservationObjectObserversKey, observeeObserverTrackingHashTable, OBJC_ASSOCIATION_RETAIN);
        }
    }
}

- (BOOL)observe
{
    if (!_isValid && // can't re-observe
        _observee &&
        _keyPath &&
        _callbackBlock)
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
            NSLog(@"PMPKVObservation: received observation but no callbackBlock is set");
    }
    else
    {
        NSLog(@"PMPKVObservation: received observation for unexpected keyPath (%@) or object (%@)", keyPath, object);
    }
}


@end
