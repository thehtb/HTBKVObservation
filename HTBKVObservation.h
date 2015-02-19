//
//  HTBKVO.h
//  HTBKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 The High Technology Bureau. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Conveniently and safely use KVO, modelling KVO each observation as an object.
@interface HTBKVObservation : NSObject

/// The object that is the target of the observation
@property (nonatomic, weak) id observedObject;

/// The block that will be called whenver an observation fires
@property (nonatomic, copy) void (^callbackBlock)(HTBKVObservation * observation, NSDictionary * changeDictionary);

/// The keypath of the observedObject that is being observed
@property (nonatomic, copy) NSString * keyPath;

/// KVO options for the observation
@property NSKeyValueObservingOptions options;

/// False if the observation has been invalidated (either manually or because the target object was deallocated)
@property (nonatomic, readonly) BOOL isValid;

/// Returns a started observation
+ (HTBKVObservation *)observe:(id)observedObject
                      keyPath:(NSString *)keyPath
                      options:(NSKeyValueObservingOptions)options
                     callback:(void (^)(HTBKVObservation * observation, NSDictionary * changeDictionary))callbackBlock;

/// Returns an array of started observations, each targetted to the same object for a range of key paths.
+ (NSArray *)observe:(id)observedObject
 forMultipleKeyPaths:(NSArray *)keyPaths
             options:(NSKeyValueObservingOptions)options
            callback:(void (^)(HTBKVObservation * observation, NSDictionary * changeDictionary))callbackBlock;

/// Returns an observation that will automatically update the `boundObjectKeyPath` on the `boundObject` whenever the `observedKeyPath` changes on the `observedObject`
+ (HTBKVObservation *)bind:(id)observedObject
                   keyPath:(NSString *)observedKeyPath
                  toObject:(id)boundObject
                   keyPath:(NSString *)boundObjectKeyPath;

/// Returns a pair of observations that will automatically keep the keypaths on the respective objects in sync. Care is taken not to enter an infinite loop :)
+ (NSArray *)bidirectionallyBind:(id)objectA
                         keyPath:(NSString *)objectAKeyPath
                      withObject:(id)objectB
                         keyPath:(NSString *)objectBKeyPath;

/// Start the observation (only necessary if you alloc/init yourself)
- (BOOL)observe;

/// Stop the observation (not noramlly necessary if the observation object lifecycle/dealloc will go away at the appropriate time)
- (void)invalidate;

@end
