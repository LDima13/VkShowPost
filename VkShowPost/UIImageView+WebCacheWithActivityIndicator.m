//
//  UIImageView+WebCacheWithActivityIndicator.m
//
//  Created by Dmitry Likhtarov on 05.06.2018.
//

#import "UIImageView+WebCacheWithActivityIndicator.h"


@implementation UIImageView (WebCacheWithActivityIndicator)

@dynamic url;

- (void) setImageAndActivityIndicatorWithURL:(nullable NSURL *)url
{
    if (!url) {
        self.image = [UIImage imageNamed:@"faceUser"];
        return;
    }
    
    // Если файл есть в кэше то не будем грузить из инета
    UIImage * image = [[SDImageCache sharedImageCache] imageFromCacheForKey:url.absoluteString];
    if (image) {
        self.image = image;
        return;
    }
    
    __block UIActivityIndicatorView* activ = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

    // поставим ромашку в центре
    CGRect frame = activ.frame;
    frame.origin.x = (self.frame.size.width - frame.size.width) / 2;
    frame.origin.y = (self.frame.size.height - frame.size.height) / 2;
    [activ setFrame:frame];
    
    [self addSubview:activ];

    [activ startAnimating];
    
    [self sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"faceUser"] options:0 completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
       
        [activ stopAnimating];
        [activ removeFromSuperview];
        
    }];

}
- (void) setImageBlankAndActivityIndicatorWithURL:(nullable NSURL *)url
{
    if (!url) {
        self.image = [UIImage imageNamed:@"blank"];
        return;
    }
    
    // Если файл есть в кэше то не будем грузить из инета
    UIImage * image = [[SDImageCache sharedImageCache] imageFromCacheForKey:url.absoluteString];
    if (image) {
        self.image = image;
        return;
    }
    
    __block UIActivityIndicatorView* activ = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    // поставим ромашку в центре
    CGRect frame = activ.frame;
    frame.origin.x = (self.frame.size.width - frame.size.width) / 2;
    frame.origin.y = (self.frame.size.height - frame.size.height) / 2;
    [activ setFrame:frame];
    
    [self addSubview:activ];
    
    [activ startAnimating];
    
    [self sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"blank"] options:0 completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        
        [activ stopAnimating];
        [activ removeFromSuperview];
        
    }];
    
}

@end
