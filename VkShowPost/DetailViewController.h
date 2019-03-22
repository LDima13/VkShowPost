//
//  DetailViewController.h
//  VkShowPost
//
//  Created by Dmitry Likhtarov on 21/03/2019.
//  Copyright © 2019 Dmitry Likhtarov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VkShowPost+CoreDataModel.h"

@interface DetailViewController : UIViewController

@property (strong, nonatomic) Event *detailItem;
@property (strong, nonatomic) NSArray <Image*> * images;

@end

