//
//  LoginViewController.m
//  VkShowPost
//
//  Created by Dmitry Likhtarov on 21/03/2019.
//  Copyright © 2019 Dmitry Likhtarov. All rights reserved.
//
//  Контроллер логина/логоута для VK
//  Открывается при запуске приложения
//  Если токен усталел, то отображается запрос логина VK
//

#import "LoginViewController.h"
#import <WebKit/WebKit.h>
#import "DAO.h"
#import "MasterViewController.h"
#import "AppDelegate.h"

@interface LoginViewController () <WKNavigationDelegate>

@property (weak, nonatomic) IBOutlet WKWebView *vkWebView;

@end

@implementation LoginViewController


static NSString * const APP_ID = @"6909479";
static NSString * const PAGE_OK = @"https://oauth.vk.com/blank.html";

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.vkWebView.navigationDelegate = self;
    
    if (self.logOut) {
        [self doLogOut];
    } else {
        [self doLogin];
    }
}

- (void) doLogin
{
//    [[DAO sharedInstance] deleteAll];
    NSString *authLink = [NSString stringWithFormat:@"https://oauth.vk.com/authorize?scope=wall&display=mobile&response_type=token&v=5.92&client_id=%@&redirect_uri=%@", APP_ID, PAGE_OK];
    
    NSURL *url = [NSURL URLWithString:authLink];
    
    [self.vkWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
}

- (void) doLogOut
{
    [[DAO sharedInstance] deleteAll];
    //[self deleteCookies];
    NSString *authLink = [NSString stringWithFormat:@"https://oauth.vk.com/authorize?revoke=1&scope=wall&display=mobile&response_type=token&v=5.92&client_id=%@&redirect_uri=%@", APP_ID, PAGE_OK];
    
    NSURL *url = [NSURL URLWithString:authLink];
    
    [self.vkWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
}

- (void) webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    // Для отлогинивания делаем изврат - и чего бы социалкам не включить это в апи??
    // Подобное отсутствие отлогина встречал и в других социалках
    // Загружаем контент, находим ссылку отлогина и запускаем её
    
    if (self.logOut == YES) {
        [webView evaluateJavaScript:@"document.documentElement.outerHTML.toString()" completionHandler:^(id _Nullable foo, NSError * _Nullable error) {
            
            NSString * html = (NSString*)foo;
            NSString *path = [self findInString:html pattern:@"data-href\\s*=\\s*\"(\\/logout\\?[^\"]*)"];
            if (path.length > 0) {
                NSString * urlLogOutString = [NSString stringWithFormat:@"%@://%@%@", webView.URL.scheme, webView.URL.host, path];
                NSURL *url = [NSURL URLWithString:urlLogOutString];
                
                DLog(@"urlLogOuturlLogOut=%@", url);
                
                if (url) {
                    [self.vkWebView loadRequest:[NSURLRequest requestWithURL:url]];
                }
            }
            
        }];
    }
}

- (void) webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    NSString *url = webView.URL.absoluteString;
    
    DLog(@"URL = %@",url);
    
    if ([url containsString:@"error="]) {
        [self doLogOut];
    }
    
}

- (void) webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    NSString *url = webView.URL.absoluteString;
    
    DLog(@"URL = %@",url);
    
    NSInteger length = url.length;
    DAO *dao = [DAO sharedInstance];
    
    if (length > 0 && [url hasPrefix:PAGE_OK]) {
        
        NSString *value = [self findInString:url pattern:@"access_token=([^&$]*)"];
        if (value.length > 0) {
            dao.access_token = value;
        }
        
        value = [self findInString:url pattern:@"user_id=([^&$]*)"];
        if (value.length > 0) {
            dao.user_id = value;
        }
        
        value =  [self findInString:url pattern:@"expires_in=([^&$]*)"];
        if ([value isEqualToString:@"0"]) {
            value = @"9999999999"; // Бессрочный токен
        }
        if (value.length > 0) {
            dao.expires_date =  [NSDate dateWithTimeIntervalSinceNow:value.integerValue]; // До куда жив токен;
        }
        
        DLog(@"\nТокен: %@\nюзер: %@\nжив до: %@", dao.access_token, dao.user_id, dao.expires_date);
        
        if (dao.access_token.length > 0 && dao.user_id.length > 0) {
            // Получили доступ
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil]; //
            UISplitViewController *splitViewController = [storyboard instantiateViewControllerWithIdentifier:@"UISplitViewController"];
            UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
            navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
            splitViewController.delegate = (AppDelegate*)UIApplication.sharedApplication.delegate;
            
            UINavigationController *masterNavigationController = splitViewController.viewControllers[0];
            MasterViewController *controller = (MasterViewController *)masterNavigationController.topViewController;
            controller.managedObjectContext = dao.moc;
            [self.view.window setRootViewController:splitViewController];
            
        } else {
            [self doLogin];
        }
        
    } else if ([url isEqualToString:@"https://oauth.vk.com/"]) {
        [self doLogin];
    } else if ([url containsString:@"error"]) {
        DLog(@"что то не так или токен кончился или еще что");
        [self deleteCookies];
        //        self.logOut = YES;
        [self doLogOut];
    }
}

// Разбор строки url,
- (NSString*) findInString:(NSString * _Nonnull)string pattern:(NSString * _Nonnull)pattern
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
    if (regex) {
        NSTextCheckingResult * result = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
        if (result.numberOfRanges == 2) {
            return [string substringWithRange:[result rangeAtIndex:1]];
        }
    }
    return nil;
}

- (void) deleteCookies
{
    // Почистим куки - хотя это бред
    NSHTTPCookieStorage *storage = NSHTTPCookieStorage.sharedHTTPCookieStorage;
    for (NSHTTPCookie * cookie in storage.cookies) {
        //if([cookie.domain containsString:@"vk.com"]) {
        DLog(@"Удаляю куку:\n %@", cookie);
        [storage deleteCookie:cookie];
        //}
    }
}

@end
