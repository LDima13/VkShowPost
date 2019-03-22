//
//  DetailViewController.m
//  VkShowPost
//
//  Created by Dmitry Likhtarov on 21/03/2019.
//  Copyright © 2019 Dmitry Likhtarov. All rights reserved.
//

#import "DetailViewController.h"
#import "WallTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+WebCacheWithActivityIndicator.h"
#import "DAO.h"

@interface DetailViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


#pragma mark - Managing the detail item

- (void)setDetailItem:(Event *)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        _images = newDetailItem.images.allObjects; // с сортировкой не буду заморачиваться для тестов
        [self.tableView reloadData];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : self.images.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        WallTableViewCell *cell = (WallTableViewCell*)[tableView dequeueReusableCellWithIdentifier:WallTableViewCellID forIndexPath:indexPath];
        [self configureCell:cell withEvent:self.detailItem];
        return cell;
    }
    
    WallTableViewCell *cell = (WallTableViewCell*)[tableView dequeueReusableCellWithIdentifier:WallTableViewCellImageID forIndexPath:indexPath];
    cell.photo.url = [NSURL URLWithString:self.images[indexPath.row].url];
    return cell;
    
}

- (void)configureCell:(WallTableViewCell *)cell withEvent:(Event *)event {
    
    NSDate *dete = event.datePost;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd.MM.yyyy HH:mm:ss"];
    cell.date.text = [NSString stringWithFormat:@"Дата: %@", dete ? [formatter stringFromDate:dete]:@"инкогнито:)"];
    
    cell.mesageTextView.text = event.textPost;
    cell.name.text = [NSString stringWithFormat:@"%@ %@", event.user.first_name, event.user.last_name];
    cell.avatar.url = [NSURL URLWithString:event.user.photo];
}

@end
