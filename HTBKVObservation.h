//
//  HTBKVO.h
//  HTBKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 The High Technology Bureau. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTBKVObservation : NSObject

@property (nonatomic, weak) id observedObject;
@property (nonatomic, copy) void (^callbackBlock)(HTBKVObservation * observation, NSDictionary * changeDictionary);
@property (nonatomic, copy) NSString * keyPath;
@property NSKeyValueObservingOptions options;
@property (nonatomic, readonly) BOOL isValid;

+ (HTBKVObservation *)observe:(id)observedObject
                      keyPath:(NSString *)keyPath
                      options:(NSKeyValueObservingOptions)options
                     callback:(void (^)(HTBKVObservation * observation, NSDictionary * changeDictionary))callbackBlock;

+ (NSArray *)observe:(id)observedObject
 forMultipleKeyPaths:(NSArray *)keyPaths
             options:(NSKeyValueObservingOptions)options
            callback:(void (^)(HTBKVObservation * observation, NSDictionary * changeDictionary))callbackBlock;

+ (HTBKVObservation *)bind:(id)observedObject
                   keyPath:(NSString *)observedKeyPath
                  toObject:(id)boundObject
                   keyPath:(NSString *)boundObjectKeyPath;

+ (NSArray *)bidirectionallyBind:(id)objectA
                         keyPath:(NSString *)objectAKeyPath
                      withObject:(id)objectB
                         keyPath:(NSString *)objectBKeyPath;

- (BOOL)observe; // only necessary if you alloc/init yourself
- (void)invalidate; // not necessary if the observation object lifecycle/dealloc will go away at the appropriate time

@end
