//
//  IbeaconView.m
//  Parse Dev Day
//
//  Created by Andrey Belyakov on 8/7/15.
//  Copyright (c) 2015 Parse. All rights reserved.
//

#import "IbeaconView.h"
#import "PDDTalk.h"

@interface IbeaconView()
@property (weak, nonatomic) UIView *emptyView;
@end

@implementation IbeaconView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BG"]];
        bgView.contentMode = UIViewContentModeCenter;
        self.backgroundView = bgView;
    }
    return self;
}

@end

