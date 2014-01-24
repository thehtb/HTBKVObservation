//
//  HTBKVO.m
//  HTBKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 The High Technology Bureau. All rights reserved.
//

#import "HTBKVObservation.h"

#import <objc/runtime.h>
#import <libextobjc/EXTScope.h>

#define NormaliseNil(v) (v == [NSNull null] ? nil : v)

const char * HTBKVObservationClassIsSwizzledKey = "HTBKVObservationClassIsSwizzledKey";
const NSString * HTBKVObservationClassIsSwizzledLockKey = @"HTBKVObservationClassIsSwizzledLockKey";
const char * HTBKVObservationObjectObserversKey = "HTBKVObservationObjectObserversKey";

@interface HTBKVObservation ()

- (void)setIsValid:(BOOL)isValid;
- (void)prepareObservedObjectAndClass;
- (void)_invalidateObservedObject:(id)obj andRemoveTargetAssociations:(BOOL)removeTargetAssociations;

@end

@implementation HTBKVObservation

- (id)init
{
    if ((self = [super init]) == nil)
        return nil;

    _isValid = NO;
    
    return self;
}

- (void)dealloc
{
    [self invalidate];
}

#pragma mark - convenience constructors

+ (HTBKVObservation *)observe:(id)observedObject
                      keyPath:(NSString *)keyPath
                      options:(NSKeyValueObservingOptions)options
                     callback:(void (^)(HTBKVObservation * observation, NSDictionary * changeDictionary))callbackBlock;
{
    HTBKVObservation * obj = [[self alloc] init];
    
    obj.observedObject = observedObject;
    obj.callbackBlock = callbackBlock;
    obj.keyPath = keyPath;
    obj.options = options;
    
    if ([obj observe])
        return obj;
    
    return nil;
}

+ (NSMutableArray *)observe:(id)observedObject
        forMultipleKeyPaths:(NSArray *)keyPaths
                    options:(NSKeyValueObservingOptions)options
                   callback:(void (^)(HTBKVObservation *, NSDictionary *))callbackBlock
{
    NSMutableArray * observations = [NSMutableArray arrayWithCapacity:[keyPaths count]];
    
    for (NSString * keyPath in keyPaths)
        [observations addObject:[self observe:observedObject
                                      keyPath:keyPath
                                      options:options
                                     callback:callbackBlock]];
    
    return observations;
}

+ (HTBKVObservation *)bind:(id)observedObject
                   keyPath:(NSString *)observedKeyPath
                  toObject:(id)boundObject
                   keyPath:(NSString *)boundObjectKeyPath
{
    HTBKVObservation * observation = [[self alloc] init];
    
    observation.observedObject = observedObject;
    observation.keyPath = observedKeyPath;
    observation.options = NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew;
    
    @weakify(boundObject);
    observation.callbackBlock = ^(HTBKVObservation *observation, NSDictionary *changeDictionary) {
        @strongify(boundObject);
        id val = changeDictionary[NSKeyValueChangeNewKey];
        [boundObject setValue:NormaliseNil(val) forKeyPath:boundObjectKeyPath];
    };
    
    if ([observation observe])
        return observation;
    
    return nil;
}

+ (NSArray *)bidirectionallyBind:(id)objectA
                                keyPath:(NSString *)objectAKeyPath
                             withObject:(id)objectB
                                keyPath:(NSString *)objectBKeyPath
{
    HTBKVObservation * observationA = [[self alloc] init];
    HTBKVObservation * observationB = [[self alloc] init];
    
    observationA.observedObject = objectA;
    observationA.keyPath = objectAKeyPath;
    observationA.options = NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew;

    observationB.observedObject = objectB;
    observationB.keyPath = objectBKeyPath;
    observationB.options = NSKeyValueObservingOptionNew;
    
    __block BOOL bindingUpdateInProgress = NO;
    
    @weakify(objectA);
    @weakify(objectB);
    
    observationA.callbackBlock = ^(HTBKVObservation *observation, NSDictionary *changeDictionary) {
        @strongify(objectB);
        if (!bindingUpdateInProgress)
        {
            bindingUpdateInProgress = YES;
            id val = changeDictionary[NSKeyValueChangeNewKey];
            [objectB setValue:NormaliseNil(val) forKeyPath:objectBKeyPath];
            bindingUpdateInProgress = NO;
        }
    };
    
    observationB.callbackBlock = ^(HTBKVObservation *observation, NSDictionary *changeDictionary) {
        @strongify(objectA);
        if (!bindingUpdateInProgress)
        {
            bindingUpdateInProgress = YES;
            id val = changeDictionary[NSKeyValueChangeNewKey];
            [objectA setValue:NormaliseNil(val) forKeyPath:objectAKeyPath];
            bindingUpdateInProgress = NO;
        }
    };

    if ([observationB observe])
    {
        if ([observationA observe])
            return @[observationA, observationB];
        
        [observationB invalidate];
    }
    
    return nil;
}

#pragma mark - instance methods

- (void)setIsValid:(BOOL)isValid
{
    if (isValid == _isValid)
        return;
    
    [self willChangeValueForKey:@"isValid"];
    _isValid = isValid;
    [self didChangeValueForKey:@"isValid"];
}

- (void)prepareObservedObjectAndClass
{
    Class class = [self.observedObject class];
    
    @synchronized(HTBKVObservationClassIsSwizzledLockKey)
    {
        NSNumber * classIsSwizzled = objc_getAssociatedObject(class, HTBKVObservationClassIsSwizzledKey);
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
                    
                    NSHashTable * _observeeObserverTrackingHashTable = objc_getAssociatedObject((__bridge id)obj, HTBKVObservationObjectObserversKey);
                    NSHashTable * observeeObserverTrackingHashTableCopy;
                    @synchronized(_observeeObserverTrackingHashTable)
                    {
                        observeeObserverTrackingHashTableCopy = [_observeeObserverTrackingHashTable copy];
                    }
                    
                    for (HTBKVObservation * observation in observeeObserverTrackingHashTableCopy)
                    {
                        //NSLog(@"Invalidating an observer in the swizzled dealloc");
                        [observation _invalidateObservedObject:(__bridge id)(obj) andRemoveTargetAssociations:NO];
                    }
                }
                ((void (*)(void *, SEL))origImpl)(obj, deallocSel);
            };
            
            IMP newImpl = imp_implementationWithBlock(block);
            
            class_replaceMethod(class, deallocSel, newImpl, method_getTypeEncoding(dealloc));
            
            objc_setAssociatedObject(class, HTBKVObservationClassIsSwizzledKey, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN);
        }
        
        // create the NSHashTable if needed - NSHashTable (when created as below) is bascially an NSMutableSet with weak references (doesn't require ARC)
        
        if (!objc_getAssociatedObject(self.observedObject, HTBKVObservationObjectObserversKey))
        {
            NSHashTable * observeeObserverTrackingHashTable = [NSHashTable weakObjectsHashTable];

            objc_setAssociatedObject(self.observedObject, HTBKVObservationObjectObserversKey, observeeObserverTrackingHashTable, OBJC_ASSOCIATION_RETAIN);
        }
    }
}

- (BOOL)observe
{
    if (!self.isValid && // can't re-observe
        self.observedObject &&
        self.keyPath &&
        self.callbackBlock)
    {
        // only swizzling the target dealloc for it to remove all observers - releasing/invalidating at the observer end
        // is its own responsibility

        [self prepareObservedObjectAndClass];
        
        [self.observedObject addObserver:self forKeyPath:_keyPath options:_options context:NULL];
    
        NSHashTable * observeeObserverTrackingHashTable = objc_getAssociatedObject(self.observedObject, HTBKVObservationObjectObserversKey);
        
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
    [self _invalidateObservedObject:self.observedObject andRemoveTargetAssociations:YES];
}

- (void)_invalidateObservedObject:(id)obj andRemoveTargetAssociations:(BOOL)removeTargetAssociations
{
    if (![self isValid])
        return;
    
    [self setIsValid:NO];
    
    [obj removeObserver:self forKeyPath:self.keyPath];
    
    if (removeTargetAssociations)
    {
        NSHashTable * observeeObserverTrackingHashTable = objc_getAssociatedObject(obj, HTBKVObservationObjectObserversKey);
        
        @synchronized(observeeObserverTrackingHashTable)
        {
            [observeeObserverTrackingHashTable removeObject:self];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([self.keyPath isEqualToString:keyPath] && self.observedObject == object)
    {
        if (self.callbackBlock)
            self.callbackBlock(self, change);
        else
            NSLog(@"HTBKVObservation: received observation but no callbackBlock is set");
    }
    else
    {
        NSLog(@"HTBKVObservation: received observation for unexpected keyPath (%@) or object (%@)", keyPath, object);
    }
}


@end
