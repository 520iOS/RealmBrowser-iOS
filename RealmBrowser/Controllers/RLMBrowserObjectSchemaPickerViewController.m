//
//  RLMBrowserObjectSchemaViewController.m
//  RealmBrowser
//
//  Created by Tim Oliver on 12/4/16.
//  Copyright © 2016 Tim Oliver. All rights reserved.
//

#import <Realm/Realm.h>

#import "RLMBrowserConstants.h"
#import "RLMBrowserObjectSchemaPickerViewController.h"

// Categories
#import "RLMProperty+BrowserDescription.h"
#import "UIImage+BrowserIcons.h"
#import "UIColor+BrowserRealmColors.h"

// Realm Model Objects
#import "RLMBrowserRealm.h"
#import "RLMBrowserSchema.h"

// Views
#import "RLMBrowserPropertyTableViewCell.h"
#import "RLMBrowserNavigationTitleView.h"
#import "RLMBrowserSchemaPreviewView.h"

// ------------------------------------------------------------------

CGFloat const kRLMBrowserObjectSchemaTableViewCellContentInset = 30.0f;
NSString * const kRLMBrowserObjectSchemaTableViewCellIdentifier = @"ObjectListCell";

// ------------------------------------------------------------------

@interface RLMBrowserObjectSchemaPickerViewController () <UIPopoverPresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readonly) BOOL showingSecondarySettings;

@property (nonatomic, strong) RLMBrowserNavigationTitleView *titleView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@property (nonatomic, strong) RLMBrowserRealm  *browserRealm;
@property (nonatomic, strong) RLMBrowserSchema *browserSchema;
@property (nonatomic, strong) RLMObject *demoObject;

@property (nonatomic, strong) NSArray *secondaryPropertyStrings;

@property (nonatomic, strong) RLMRealm *realm;
@property (nonatomic, strong) RLMObjectSchema *schema;

@property (nonatomic, strong) UIImage *circleIcon;
@property (nonatomic, strong) NSArray *realmColors;
@property (nonatomic, strong) UIImage *checkmarkIcon;

@property (nonatomic, strong) RLMBrowserSchemaPreviewView *previewView;

@end

// ------------------------------------------------------------------

@implementation RLMBrowserObjectSchemaPickerViewController

- (instancetype)initWithBrowserRealm:(RLMBrowserRealm *)realm browserSchema:(RLMBrowserSchema *)schema demoObject:(RLMObject *)object
{
    if (self = [super init]) {
        _browserRealm = realm;
        _browserSchema = schema;
        _secondaryPropertyStrings = schema.secondaryPropertyNameStrings;
        _demoObject = object;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    RLM_RESET_NAVIGATION_CONTROLLER(self.navigationController);

    self.checkmarkIcon = [UIImage RLMBrowser_checkmarkIcon];
    self.presentationController.delegate = self;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 50.0f;
    [self.view addSubview:self.tableView];
    
    // Configure table cell
    UINib *tableNib = [UINib nibWithNibName:@"RLMBrowserPropertyTableViewCell" bundle:nil];
    [self.tableView registerNib:tableNib forCellReuseIdentifier:kRLMBrowserObjectSchemaTableViewCellIdentifier];
    
    // Load Realm and the schema
    self.realm = [RLMRealm realmWithConfiguration:self.browserRealm.realmConfiguration error:nil];
    self.schema = [self.realm.schema schemaForClassName:self.browserSchema.className];
    
    // Set up the header for this view controller
    self.titleView = [[RLMBrowserNavigationTitleView alloc] init];
    self.titleView.titleLabel.text = self.browserSchema.className;
    
    // Configure header view
    self.titleView.subtitleLabel.text = @"Choose Visible Properties";
    [self.titleView sizeToFit];
    self.navigationItem.titleView = self.titleView;
    
    self.circleIcon = [UIImage RLMBrowser_tintedCircleImageForRadius:12.0f];
    self.realmColors = [[[UIColor RLMBrowser_realmColors] reverseObjectEnumerator] allObjects];
    
    // Add Done button
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonTapped:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    // Add segment control to bar
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Primary", @"Secondary"]];
    self.segmentedControl.frame = (CGRect){0,0, 290.0f, self.segmentedControl.frame.size.height};
    self.segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin
                                                | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.segmentedControl addTarget:self action:@selector(segmentControlChanged:) forControlEvents:UIControlEventValueChanged];

    UIBarButtonItem *controlItem = [[UIBarButtonItem alloc] initWithCustomView:self.segmentedControl];
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    self.navigationController.toolbarHidden = NO;
    self.toolbarItems = @[spaceItem, controlItem, spaceItem];
    
    // Create preview view
    self.previewView = [RLMBrowserSchemaPreviewView contentView];
    CGRect frame = self.previewView.bounds;
    frame.size.height += 20 + 20;
    UIView *containerView = [[UIView alloc] initWithFrame:frame];
    [containerView addSubview:self.previewView];
    self.previewView.frame = CGRectOffset(self.previewView.frame, 0, 20);
    self.previewView.navbar.hidden = YES;
    self.tableView.tableHeaderView = containerView;

    [self.previewView.objectPreviewView configureCellWithRealmObject:self.demoObject
                                                       titleProperty:self.browserSchema.preferredPropertyName
                                                 secondaryProperties:self.secondaryPropertyStrings];

    self.previewView.objectPreviewView.indexLabel.text = @"1";
    self.previewView.objectPreviewView.indexLabel.textColor = [UIColor RLMBrowser_realmColorsInvertedRepeating].firstObject;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.segmentedControl.selectedSegmentIndex = 0;
}

#pragma mark - Presentation Management -
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationFullScreen;
}

#pragma mark - Button Callback -
- (void)doneButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)segmentControlChanged:(id)sender
{
    [self.tableView reloadData];
}

#pragma mark - Content View Handling -

- (void)layoutAccessoryViews
{
    UIScrollView *scrollView = self.tableView;
    UIEdgeInsets insets = scrollView.contentInset;
    if (@available(iOS 11.0, *)) {
        insets = scrollView.safeAreaInsets;
    }
    CGFloat previewY = scrollView.contentOffset.y + insets.top;
    CGFloat previewOffset = 20.0f;
    self.previewView.navbar.hidden = !(previewY > previewOffset);

    CGRect previewFrame = self.previewView.frame;
    if (previewY > previewOffset) {
        previewFrame.origin.y = previewY;
    }
    else {
        previewFrame.origin.y = previewOffset;
    }
    self.previewView.frame = previewFrame;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self layoutAccessoryViews];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self layoutAccessoryViews];
}

#pragma mark - Table View Data Source -

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.schema.properties.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RLMBrowserPropertyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kRLMBrowserObjectSchemaTableViewCellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    cell.rightInset = kRLMBrowserObjectSchemaTableViewCellContentInset;

    RLMProperty *property = self.schema.properties[indexPath.row];
    cell.iconView.image = self.circleIcon;
    cell.iconView.tintColor = self.realmColors[indexPath.row % self.realmColors.count];
    cell.titleLabel.text = property.name;
    cell.subtitleLabel.text = property.RLMBrowser_configurationDescription;
    cell.typeLabel.text = property.RLMBrowser_typeDescription;
//    cell.checkmarkView.image = self.checkmarkIcon;
//
//    if (self.showingSecondarySettings) {
//        cell.checkmarkView.hidden = ![self.secondaryPropertyStrings containsObject:property.name];
//    }
//    else {
//        cell.checkmarkView.hidden = ![property.name isEqualToString:self.browserSchema.preferredPropertyName];
//    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)showingSecondarySettings
{
    return self.segmentedControl.selectedSegmentIndex == 1;
}

@end
