//
//  IbeaconListViewController.m
//  Parse Dev Day
//
//  Created by Andrey Belyakov on 8/5/15.
//  Copyright (c) 2015 Parse. All rights reserved.
//

#import "IbeaconListViewController.h"

#import "PTDBeanManager.h"

#import "PDDListViewController.h"
#import "PDDTalkCell.h"
#import "IbeaconView.h"

#import "PDDTalk.h"
#import "PDDSlot.h"
#import "PDDRoom.h"
#import "PDDConstants.h"

#import "UIColor+ParseDevDay.h"

#import <Parse/Parse.h>

@interface IbeaconListViewController () <PTDBeanManagerDelegate, PTDBeanDelegate>
// all the beans returned from a scan
@property (nonatomic, strong) NSMutableDictionary *beans;
// how we access the beans
@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (weak, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *rawTalks;
@property (strong, nonatomic) NSDictionary *dataBySection;
@property (strong, nonatomic) NSArray *sortedSections;
@property (nonatomic) PDDTalkSectionType currentSectionSort;

@property (strong, nonatomic) NSMutableArray *checkedTalks;
@property (nonatomic) int flagOne;
@property (nonatomic) int flagTwo;
@property (strong, atomic) NSTimer *timer;
@property (strong, nonatomic) NSMutableArray *beansArr;
@property (strong, nonatomic) NSArray *sortedArray;
@property (atomic) BOOL isViewed;
@property (strong, nonatomic) UIAlertView *searchingAlert;
@property (strong, nonatomic) UIAlertView *alert;

@end

@implementation IbeaconListViewController

- (id)init {
    if (self = [super init]) {
        self.title = @"Talks here";
        self.tabBarItem.image = [UIImage imageNamed:@"ibeacons"];
        self.isViewed = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.beans = [NSMutableDictionary dictionary];
    self.checkedTalks = [NSMutableArray new];
    self.beansArr = [NSMutableArray array];
    NSLog(@"VIEW DID LOAD");
}

- (void)checkAndScan {
    NSLog(@"self.beans %d", [self.beans count]);
    NSLog(@"self.rawtalks count %lu", (unsigned long)[self.rawTalks count]);
    NSLog(@"self.checkedtalks count %lu", (unsigned long)[self.checkedTalks count]);
    
    self.flagOne = self.flagTwo;
    NSLog(@"self.flagOne %d", self.flagOne);
    self.flagTwo = [self.beans count];
    NSLog(@"self.flagTwo %d", self.flagTwo);
    if ([self.beans count] == 0 && self.flagOne == 0) {
        [self reset];
        [self reorderTableViewSections];
        [self startScan];
    } else {
        self.rawTalks = self.checkedTalks;
    }
    self.beans.removeAllObjects;
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    self.beansArr.removeAllObjects;
}

-(void)reset {
    self.checkedTalks.removeAllObjects;
    self.rawTalks = self.checkedTalks;
    self.beansArr.removeAllObjects;
}

-(void)startScan {
    self.beans.removeAllObjects;
    self.isViewed = NO;
    if (([self.beans count] == 0) && ![self.searchingAlert isVisible] && ![self.alert isVisible] && (self.beanManager.state == BeanManagerState_PoweredOn)) {
        NSLog(@"dsfsdf %d", (self.beanManager.state == BeanManagerState_PoweredOn));
        self.searchingAlert = [[UIAlertView alloc] initWithTitle:@"Please wait" message:@"Searching your location.." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
        [self.searchingAlert show];
        return;
    }
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSLog(@"index %ld", (long)buttonIndex);
    if (buttonIndex == 0) {
        [self.timer invalidate];
    }
}

- (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
    if(self.beanManager.state == BeanManagerState_PoweredOn){
        [self.beanManager startScanningForBeans_error:nil];
    } else if ((self.beanManager.state == BeanManagerState_PoweredOff) && (!self.isViewed) && ![self.alert isVisible]) {
        self.alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Turn on bluetooth to continue" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [self.alert show];
        [self.timer invalidate];
        self.isViewed = YES;
        NSLog(@"isViewed %hhd", self.isViewed);
        return;
    }
}

- (void)loadView {
    IbeaconView *listView = [[IbeaconView alloc] init];
    listView.delegate = self;
    listView.dataSource = self;
    self.tableView = listView;
    self.view = listView;
    NSLog(@"LOAD VIEW");
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(startScan)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"VIEW WILL APPEAR");
    [self startScan];
    NSTimeInterval numberOfSeconds = 4;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:numberOfSeconds
                                             target:self
                                           selector:@selector(checkAndScan)
                                           userInfo:nil
                                            repeats:YES];
    
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reset];
    [self.timer invalidate];
    NSError *stopScanningError;
    [self.beanManager stopScanningForBeans_error:&stopScanningError];
    self.checkedTalks.removeAllObjects;
    self.rawTalks = self.checkedTalks;
    [self.tableView reloadData];
    [self reorderTableViewSections];
    [self reset];
    self.isViewed = NO;
    NSLog(@"VIEW WILL DISAPPEAR");
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
    NSUUID * key = bean.identifier;
    [self.beansArr addObject:bean];
    
    if (![self.beans objectForKey:key]) {
        [self.beans setObject:bean forKey:key];
    }
        self.sortedArray = [NSArray new];
        self.sortedArray = [self.beansArr sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        int first = [[(PTDBean*)a RSSI] intValue];
        int second = [[(PTDBean*)b RSSI] intValue];
        return first < second;
        }];
    
//    for (int i = 0; i < [self.sortedArray count]; i++) {
//        NSLog(@"sorted array el %d", [[(PTDBean*)[self.sortedArray objectAtIndex:i] RSSI] intValue]);
//    }
    
    [PDDTalk findByBeaconInBackgroundWithBlock:^(NSArray *talks, NSError *error) {
        
        PTDBean *beanWithBestRssi = [self.sortedArray objectAtIndex:0];
        
        if (error) {
            NSLog(@"Error while loading data: %@", error);
            return;
        }
        
        self.checkedTalks.removeAllObjects;
            NSUInteger count = [talks count];
            for (NSUInteger i = 0; i < count; i++) {
                PDDTalk *talk = [talks objectAtIndex: i];
                NSArray *beaconsForChecking = talk.room.iBeaconUuidIdentifier;
                if ([beaconsForChecking containsObject:([beanWithBestRssi.identifier UUIDString])]) {
                    [_checkedTalks addObject: talk];
                }
            }
        
        
        self.rawTalks = _checkedTalks;
        [self.tableView reloadData];
        [self reorderTableViewSections];
        if ([self.searchingAlert isVisible] && [self.tableView numberOfSections] !=0) {
            [self.searchingAlert dismissWithClickedButtonIndex:0 animated:YES];
        }
    }];
    
//    }
    
    
}

#pragma mark - UITableViewDataSource methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id sectionKey = [self.sortedSections objectAtIndex:section];
    return [[self.dataBySection objectForKey:sectionKey] count] + ([self _isLastSection:section] ? 1 : 0);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sortedSections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] > 1) {
        return [[self.sortedSections objectAtIndex:section] description];
    } else if (section == 0) {
        return @"Morning Sessions";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kReuseIdentifier = @"schedule cell";
    PDDTalkCell *cell = [tableView dequeueReusableCellWithIdentifier:kReuseIdentifier];
    if (cell == nil) {
        cell = [[PDDTalkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kReuseIdentifier];
        [cell.favoriteButton addTarget:self action:@selector(favorite:) forControlEvents:UIControlEventTouchUpInside];
    }
    cell.sectionType = self.currentSectionSort;
    
    if ([self _isLastRow:indexPath]) {
        [cell setAsToggleSortCell];
    } else {
        [cell setTalk:[self talkForIndexPath:indexPath]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self _isLastRow:indexPath]) {
        self.currentSectionSort = (self.currentSectionSort == kPDDTalkSectionByTime) ? kPDDTalkSectionByTrack : kPDDTalkSectionByTime;
        [self reorderTableViewSections];
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - PDDBaseListViewController methods
- (PDDTalk *)talkForIndexPath:(NSIndexPath *)indexPath {
    id sectionKey = [self.sortedSections objectAtIndex:indexPath.section];
    NSArray *sectionData = [self.dataBySection objectForKey:sectionKey];
    if (indexPath.row < [sectionData count]) {
        return [sectionData objectAtIndex:indexPath.row];
    }
    return nil;
}

- (void)favoriteAdded:(NSNotification *)notification {
    [self _reloadVisibleRows];
}

- (void)favoriteRemoved:(NSNotification *)notification {
    [self _reloadVisibleRows];
}

#pragma mark - PDDListViewController methods
- (void)changeSections:(id)sender {
    UISegmentedControl *control = sender;
    if (self.currentSectionSort == control.selectedSegmentIndex) {
        return;
    }
    self.currentSectionSort = control.selectedSegmentIndex;
    [self reorderTableViewSections];
}

#pragma mark - Private methods
- (void)reorderTableViewSections {
    if ([self _isSortByTime]) {
        [self _reorderTableViewSectionsByTime];
    } else {
        [self _reorderTableViewSectionsByTrack];
    }
    [self.tableView reloadData];
}

- (void)_reorderTableViewSectionsByTime {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self.rawTalks enumerateObjectsUsingBlock:^(PDDTalk *talk, NSUInteger idx, BOOL *stop) {
        id groupKey = talk.slot.startTime;
        
        [self _setObject:talk inArray:groupKey inDictionary:dictionary];
    }];
    
    NSArray *sortedKeys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    // a little extra conversion necessary
    NSMutableArray *dateStrings = [NSMutableArray arrayWithCapacity:[sortedKeys count]];
    [sortedKeys enumerateObjectsUsingBlock:^(NSDate *date, NSUInteger idx, BOOL *stop) {
        NSString *string = [PDDTalk stringTime:date];
        [dateStrings addObject:string];
        [dictionary setObject:[dictionary objectForKey:date] forKey:string];
        [dictionary removeObjectForKey:date];
    }];
    self.dataBySection = dictionary;
    self.sortedSections = dateStrings;
}

- (void)_reorderTableViewSectionsByTrack {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self.rawTalks enumerateObjectsUsingBlock:^(PDDTalk *talk, NSUInteger idx, BOOL *stop) {
        if (talk.alwaysFavorite) {
            // Skip always-favorited talks in the Track view
            return;
        }
        id groupKey = talk.room.name;

        [self _setObject:talk inArray:groupKey inDictionary:dictionary];
    }];
    
    NSArray *sortedKeys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    self.dataBySection = dictionary;
    self.sortedSections = sortedKeys;
}

- (void)_setObject:(id)object inArray:(id)key inDictionary:(NSMutableDictionary *)dict {
    NSArray *sectionTalks = [dict objectForKey:key];
    if (sectionTalks) {
        [dict setObject:[sectionTalks arrayByAddingObject:object] forKey:key];
    } else {
        [dict setObject:@[ object ] forKey:key];
    }
}

- (BOOL)_isSortByTime {
    return self.currentSectionSort == kPDDTalkSectionByTime;
}

- (void)_reloadVisibleRows {
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows]
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (BOOL)_isLastSection:(NSInteger)sectionIndex {
    return sectionIndex == [self.sortedSections count] - 1;
}

- (BOOL)_isLastRow:(NSIndexPath *)indexPath {
    if (![self _isLastSection:indexPath.section]) {
        return NO;
    }
    id sectionKey = [self.sortedSections objectAtIndex:indexPath.section];
    return indexPath.row == [[self.dataBySection objectForKey:sectionKey] count];
}



@end



