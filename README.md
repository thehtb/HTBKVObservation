# HTBKVObservation - Yet Another KVO-improvement project

## Synopsis

Include HTBKVObservation.m and .h in your project

```objective-c
#import "HTBKVObservation.h"

@interface HTBKVOTests ()
@property (strong) HTBKVObservation * anObservation;
@property (strong) NSArray * multipleObservations;
@property (strong) HTBKVObservation * binding;
@property (strong) NSArray * bidirectionalBinding;
@end

@implementation HTBKVOTests

- (void)blockObservation
{
    self.anObservation = [HTBKVObservation observe:anObjectToObserve
                                           keyPath:@"observeMe"
                                           options:0
                                          callback:^(HTBKVObservation *observation, NSDictionary *changeDictionary) {
                                              NSLog(@"observation fired for object: %@ keyPath: %@ changes: %@",
                                                  observation.observedObject,
                                                  observation.keyPath,
                                                  changes);
                                          }];
                                          
    self.multipleObservations = [HTBKVObservation observe:anObjectToObserve
                                      forMultipleKeyPaths:@[@"observeMe2", @"observeMe3"]
                                                  options:0
                                             callback:^(HTBKVObservation *observation, NSDictionary *changeDictionary) {
                                                 NSLog(@"observation fired for object: %@ keyPath: %@ changes: %@",
                                                     observation.observedObject,
                                                     observation.keyPath,
                                                     changes);
                                             }];

    self.unidirectionalBinding = [HTBKVObservation bind:theSourceObject
                                                keyPath:@"somePropertyOnTheSourceObject"
                                               toObject:destinationObject
                                                keyPath:@"somePropertyOnTheDestinationObject"];

    self.bidirectionalBinding = [HTBKVObservation bidrectionallyBind:objectA
                                                              keyPath:@"somePropertyOnObjectA"
                                                           withObject:objectB
                                                              keyPath:@"somePropertyOnObjectB"];
}

@end
```

The options and change dictionary are as per normal KVO. You need to be wary of the block causing retain cycles of self as usual.

Unlike MAKVONotificationCenter and others, you are responsible for managing the lifecycle of the kvo object - when it is dealloc-ed the observation will be removed. Like MAKVONotificationCenter, a minimum of magic is used to swizzle the dealloc method of the observed object and remove the observation if it still exists (tracked via an associated NSHashTable). If for some reason you want to find out if the kvo object you hold has been released early you can check the @isValid@ accessor (which you can observe with KVO).

## Creating Observations

In the Synopsis above you can see the two ways of creating observations, with the second being purely a convenience. The HTBKVObservation instance must be retained for the observation to remain active (see the section on Lifetime below).

The options value is simply passed through to the underlying KVO call, so see `NSKeyValueObservingOptions` for more info. Likewise, the `changeDictionary` is the one provided by KVO itself, so see `observeValueForKeyPath:ofObject:change:context:` for more info.

## Creating Bindings

When you create a unidirectional binding, the destination object is brought in sync immediately.

When you create a bidirectional binding pair, objectB is brought in sync with objectA. Subsequently, any change to either objectA or objectB will be propogated to the other object.

## Observation/Binding Lifetime

The Observation will begin automatically when one of the above class/convenience methods is called or if you create an instance of HTBKVObservation yourself, when you send the `observe` message.

The Observation will end (cleanly) when any one of the following happens:

1. The HTBKVObservation object is dealloc'd
2. The observed object is dealloc'd
3. The HTBKVObservation object is sent an invalidate message.

Additionally, if the observing object is dealloc'd the observation will be void (although still fire) since the HTBObservation instance maintains only a weak reference to the observing object.

For unidirectional binding, the above rules apply as you would expect. The bidirectional binding convenience method simply returns two instances of HTBKVObservation, with objectA and objectB the observer/observee on one or the other - so in effect both are ended or nullified by either objectA or objectB being dealloc'd (and of course also if the observation objects are dealloc'd).

## Caveats

1. While I am using this in a number of Mac and iOS client projects, I can't promise wide-spread testing. Take a look at the tests in the test app and if you are using scenarios that you don't thing are tested pull requests are welcome!
2. As of version 0.2 it requires ARC. It is most tested under MacOS 10.8 but supports 10.7 and up and iOS 5 and up (there are test apps for both MacOS 10.7 and iOS 5).

## Running the Test Apps

Before the test apps will run from the workspace, you need the libextobjc dependency. The easiest way is with CocoaPods - just go to the root project directory and run `pod install`. This is not neccessary for using the class.

## Background

If you're reading this then you're probably as frustrated by seemingly random KVO crashes and/or the pain of huge if/else blocks in your observers. I've never been happy with the other KVO-improvement classes I've seen, and never having had any bright insights myself I kept doing things the normal way. This becomes especially painful with things like view based NSTableViews when you are re-using objects and so need to observe a new object, being very careful to un-observe the prior object (unless it's been released, which you need to either track yourself if you can, or retain it, which has its own problems).

It was clear that the dealloc swizzling approach of Mike Ash's [MAKVONotificationCenter](https://github.com/mikeash/MAKVONotificationCenter) was unavoidable, but I didn't like the complexity. Recently Gwynne Raskind posted a [somewhat updated MAKVONotificationCenter](http://www.mikeash.com/pyblog/friday-qa-2012-03-02-key-value-observing-done-right-take-2.html) which sparked some discussion, including a comment discussing [SPKVONotificationCenter](https://github.com/nevyn/SPSuccinct/blob/master/SPSuccinct/SPKVONotificationCenter.m) by Joachim Bengtsson. Joachim's brainwave was that observations should be modelled as standalone objects and simply managing the lifecycle of that object appropriately should remove the observation. Clean and simple.

Except it's not quite that simple because you still need to swizzle the dealloc of the observed object since it can go away at any time. And as much as I love a good macro as much as the next hacker, Joachim's @$depends()@ macro looks about as much fun as a [turing complete makefile](http://okmij.org/ftp/Computation/Make-functional.txt).

Enter HTBKVObservation!

## Changelog

* 0.1 : first version tag created for CocoaPods user happiness
* 0.2 : Now requires ARC, and consequently the target/action API was removed in favour of the block based API.
* 0.3 : Fixed a possible race condition.
* 0.4 : Added uni-directional binding.

## Author

Mark Aufflick ([mark@aufflick.com](mailto:mark@aufflick.com))
[http://mark.aufflick.com](http://mark.aufflick.com)
[http://htb.io](http://htb.io)
