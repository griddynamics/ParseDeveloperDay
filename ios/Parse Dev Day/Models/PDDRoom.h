//
//  PDDRoom.h
//  Parse Dev Day
//
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import <Parse/Parse.h>

@interface PDDRoom : PFObject<PFSubclassing>
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *beacon;
@property (strong, nonatomic) NSArray *iBeaconMacAddresses;
@property (strong, nonatomic) NSArray *iBeaconUuidIdentifier;

@end
