//
//  WallTableViewCell.h
//  VkShowPost
//
//  Created by Dmitry Likhtarov on 21/03/2019.
//  Copyright © 2019 Dmitry Likhtarov. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *WallTableViewCellID = @"WallTableViewCellID";
static NSString *WallTableViewCellImageID = @"WallTableViewCellImageID";

NS_ASSUME_NONNULL_BEGIN

@interface WallTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UIImageView *photo;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *mesage;

@property (weak, nonatomic) IBOutlet UITextView *mesageTextView;

@end

NS_ASSUME_NONNULL_END
