//
//  RLMBrowserSchema.h
//  RealmBrowser
//
//  Created by Tim Oliver on 25/11/16.
//  Copyright © 2016 Tim Oliver. All rights reserved.
//

#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

/** A basic representation of each object schema backed by the parent Realm */
@interface RLMBrowserSchema : RLMObject

/** The name of the class that's being backed by this object schema. */
@property (nonatomic, copy) NSString *className;

/** The preferred property to represent objects from this schema. (e.g. 'name' over 'uuid') */
@property (nonatomic, copy) NSString *preferredPropertyName;

@end

RLM_ARRAY_TYPE(RLMBrowserSchema)

NS_ASSUME_NONNULL_END