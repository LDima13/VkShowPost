//
//  UIImageView+WebCacheWithActivityIndicator.h
//
//  Created by Dmitry Likhtarov on 05.06.2018.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface UIImageView (WebCacheWithActivityIndicator)

// Пока грузится картинка из урл
// отображаем заставку - изображение с именем @"LaunchIcon"
// и крутится ромашка
// если изображение не загрузилось, то просто отключим ромашку
// и оставив заставку
//

@property (setter = setImageAndActivityIndicatorWithURL:) NSURL * url;
@property (setter = setImageBlankAndActivityIndicatorWithURL:) NSURL * urlBlank;

- (void) setImageAndActivityIndicatorWithURL:(nullable NSURL *)url;
- (void) setImageBlankAndActivityIndicatorWithURL:(nullable NSURL *)url;

@end
