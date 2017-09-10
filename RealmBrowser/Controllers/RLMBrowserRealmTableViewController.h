//
//  RLMBrowserRealmTableViewController.h
//  RealmBrowser
//
//  Created by Tim Oliver on 5/10/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RLMBrowserList;
@class RLMBrowserRealm;

@interface RLMBrowserRealmTableViewController : UITableViewController

@property (nonatomic, readonly) RLMBrowserList *browserList;
@property (nonatomic, readonly) RLMBrowserRealm *browserRealm;
@property (nonatomic, assign) BOOL isDefaultRealm;

- (instancetype)initWithBrowserRealm:(RLMBrowserRealm *)realm browserList:(RLMBrowserList *)list;

@end
