//
//  DAO.m
//  MixMac
//
//  Created by Dmitry Likhtarov on 10/01/2019.
//  Copyright © 2018 Geomatix Laboratoriess S.R.O. All rights reserved.
//

#import "DAO.h"

@interface DAO ()

@end

@implementation DAO

+ (DAO *) sharedInstance
{
    static DAO *_sharedDao = nil;
    if (!_sharedDao) {
        _sharedDao = [[DAO alloc] init];
    }
    return _sharedDao;
}

- (instancetype) init
{
    if (self = [super init]) {
        _persistentContainerQueue = [[NSOperationQueue alloc] init];
        _persistentContainerQueue.maxConcurrentOperationCount = 1;
     }
    return self;
}

#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSManagedObjectContext *)moc
{
    return self.persistentContainer.viewContext;
}

- (NSPersistentContainer *)persistentContainer {
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"VkShowPost"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    NSLog(@"Неразрешимая ошибка загрузки хранилища %@, %@", error, error.userInfo);
                    abort();
                } else {
                    self->_persistentContainer.viewContext.automaticallyMergesChangesFromParent = true;
                }
            }];
        }
    }    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext:(NSManagedObjectContext* _Nullable)context
{
    if (!context) {
        context = self.persistentContainer.viewContext;
    }

    NSError *error;
    if ([context hasChanges] && ![context save:&error]) {
        NSLog(@"Неразрешимая ошибка сохранения контекста %@, %@", error, error.userInfo);
        abort();
    }
}

- (void)enqueueCoreDataBlock:(void (^)(NSManagedObjectContext* context))block completion:(void (^)(void))completion {
    void (^blockCopy)(NSManagedObjectContext*) = [block copy];
    void (^completionCopy)(void) = [completion copy];
    [self.persistentContainerQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        NSManagedObjectContext* context =  self.persistentContainer.newBackgroundContext;
        [context performBlockAndWait:^{
            // внутри блока выполняем нужные операции в контексте
            blockCopy(context);
            NSError *error;
            if ([context hasChanges] && ![context save:&error]) {
                NSLog(@"Неразрешимая ошибка сохранения контекста (2) %@, %@", error, error.userInfo);
                abort();
            } else if (completionCopy) {
                // Блок завершения для операций, которые надо выполнять после сохранения контекста
                // вызовется после завершения блока blockCopy
                completionCopy();
            }
            
        }];
    }]];
}

#pragma mark -

- (void)getPortionOffset:(NSInteger)offset completion:(void (^)(NSError * _Nullable error))completion
{
    // поскольку в мойе тестовой стене нет записей, использую чужую:)
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.vk.com/method/wall.get?owner_id=%@&access_token=%@&v=5.92&offset=%ld&count=%@&extended=1&fields=first_name,last_name,id,users", @"-60750833", self.access_token, offset, @"10"]];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.vk.com/method/wall.get?access_token=%@&v=5.92&offset=%ld&count=%@", self.access_token, offset, @"6"]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:45];
    request.HTTPMethod = @"GET";
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication.sharedApplication.networkActivityIndicatorVisible = YES;
    });
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable subData, NSURLResponse * _Nullable subResponse, NSError * _Nullable subError) {

        [self debugRequest:request response:subResponse data:subData error:subError];

        dispatch_async(dispatch_get_main_queue(), ^{
            UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
        });
        

        if (subError) {
            if (completion) completion(subError);
        } else {
                NSDictionary *responce = [self dictFromJSON:subData][@"response"];
                NSArray *items = responce[@"items"];
                __block NSMutableDictionary * eventIDs = [NSMutableDictionary new]; // накапливаем id userov
                [self enqueueCoreDataBlock:^(NSManagedObjectContext *context) {
                    for (NSInteger i = 0; i < items.count; i++) {
                        NSDictionary * item = items[i];
                        Event *event = [self getOrCreateEventWithDict:item context:context];
                        DLog(@"ev = %lld", event.from_id);
                        //if (event.from_id > 0 && event.idPost > 0) { // ? не уверен что нулевых постов нету
                            eventIDs[@(event.idPost).stringValue] = @(event.from_id);
                        //}
                    }
                } completion:^{
                    if (completion) completion(nil);
                    [self getUsers:eventIDs completion:nil]; // обновим юзеров
                }];
        }
        
    }] resume];
}

- (void)getUsers:(NSDictionary * _Nullable)eventsUserID completion:(void (^)(NSError * _Nullable error))completion
{
    if (eventsUserID.count < 1) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    NSMutableDictionary *dictUserIDs = [NSMutableDictionary new];
    
    for (NSNumber *from_id in eventsUserID.allValues) {
        if (from_id) {
            dictUserIDs[from_id.stringValue] = from_id;
        }
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.vk.com/method/users.get?access_token=%@&v=5.92&fields=photo_50&user_ids=%@", self.access_token ,[dictUserIDs.allValues componentsJoinedByString:@","]]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:45];
    request.HTTPMethod = @"GET";
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication.sharedApplication.networkActivityIndicatorVisible = YES;
    });
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable subData, NSURLResponse * _Nullable subResponse, NSError * _Nullable subError) {
        
        [self debugRequest:request response:subResponse data:subData error:subError];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
        });
        
        
        if (subError) {
            if (completion) completion(subError);
        } else {
                NSArray *users = [self dictFromJSON:subData][@"response"];
                [self enqueueCoreDataBlock:^(NSManagedObjectContext *context) {
                    // Не очень красиво, зато быстро:))
                    
                    for (NSInteger i = 0; i < users.count; i++) {
                        NSDictionary * dict = users[i];
                        [self getOrCreateUserWithDict:dict context:context];
                    }
                    
                    for (NSString *idPost in eventsUserID.allKeys) {
                        Event *event = [self getEventWithIdPost:idPost context:context];
                        DLog(@"event.from_id = %lld",event.from_id);
                        event.user = [self getUserWithID:@(event.from_id) context:context];;
                    }
                    
                } completion:^{
                    if (completion) completion(nil);
                }];
        }
        
    }] resume];
}

- (Event *) getOrCreateEventWithDict:(NSDictionary*)dict context:(NSManagedObjectContext*)context
{
    NSNumber * idPost = dict[@"id"]; // идентификатор записи.
    
    if (!idPost) return nil;
    
    Event * event = nil;
    NSFetchRequest *req = [Event fetchRequest];
    req.predicate = [NSPredicate predicateWithFormat:@"idPost = %@", idPost];
    
    NSArray * res = [context executeFetchRequest:req error:nil];
    
    if (res.count > 0) {
        event = res[0];
        //return res[0];
    }
    
    if (!event) {
        //Event *
        event = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(Event.class) inManagedObjectContext:context];
        event.idPost = idPost.integerValue; // идентификатор записи.
    }
    if (event) {
        // h ttps://vk.com/dev/objects/post
        event.textPost = dict[@"text"]; // текст записи.
        NSNumber *num = dict[@"date"]; // время публикации записи в формате unixtime.
        if (num) {
            event.datePost = [NSDate dateWithTimeIntervalSince1970:num.integerValue];
        }
        num = dict[@"from_id"]; // идентификатор автора записи (от чьего имени опубликована запись).
        if (num) {
            event.from_id = ABS(num.integerValue);
        }
        
        // просто найдем первую попавшуюся случайного размера прикрепленную фотку
        NSArray * attachments = dict[@"attachments"];
        for (NSDictionary *attDict in attachments) {
            NSDictionary *dictPhoto = attDict[@"photo"];
            NSArray *sizes = dictPhoto[@"sizes"];
            NSNumber *idPhoto = dictPhoto[@"id"];
            NSString *url = nil;
            for (NSDictionary *dictSizes in sizes) {
                url = dictSizes[@"url"];
                DLog(@"url= %@  %@",url,dictSizes[@"height"]);
                if (url) {
                    event.photo = url;
                }
            }
            if (idPhoto && url) {
                [self getOrCreateImageID:idPhoto url:url event:event context:context];
            }
            
            NSDictionary *dictLink = attDict[@"link"];
            if (dictLink) {
                NSDictionary *dictPhoto = dictLink[@"photo"];
                idPhoto = dictPhoto[@"id"];
                url = nil;
                NSArray *sizes = dictPhoto[@"sizes"];
                for (NSDictionary *dictSizes in sizes) {
                    url = dictSizes[@"url"];
                    DLog(@"urlLink= %@  %@",url,dictSizes[@"height"]);
                    if (!event.photo) { // тут меньший приоритет
                        event.photo = url;
                    }
                }
                
                if (idPhoto && url) {
                    [self getOrCreateImageID:idPhoto url:url event:event context:context];
                }

            }
        }
    }
    
    return event;
}

- (Image *) getOrCreateImageID:(NSNumber*)idPhoto url:(NSString*)url event:(Event*)event context:(NSManagedObjectContext*)context
{
    if (!idPhoto || url.length < 1) {
        return nil;
    }
    
    Image *image = nil;
    
    NSFetchRequest *req = [Image fetchRequest];
    req.predicate = [NSPredicate predicateWithFormat:@"idPhoto = %@", idPhoto];
    NSArray * res = [context executeFetchRequest:req error:nil];
    if (res.count > 0) {
        image = res[0];
    }

    if (!image) {
        image = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(Image.class) inManagedObjectContext:context];
        image.idPhoto = idPhoto.integerValue;
    }
    
    if (image) {
        image.url = url;
        [event addImagesObject:image];
    }
    
    return image;
}


- (Event *) getEventWithIdPost:(NSString*)idPost context:(NSManagedObjectContext* _Nonnull)context
{
    if (idPost.length > 0) {
        NSFetchRequest *req = [Event fetchRequest];
        req.predicate = [NSPredicate predicateWithFormat:@"idPost = %@", idPost];
        NSArray * res = [context executeFetchRequest:req error:nil];
        if (res.count > 0) {
            return res[0];
        }
    }
    return nil;
}

- (User *) getOrCreateUserWithDict:(NSDictionary*)dict context:(NSManagedObjectContext*)context
{
    NSNumber * idUser = dict[@"id"]; // идентификатор записи.
    
    if (!idUser) return nil;
    
    User * user = [self getUserWithID:idUser context:context];

    if (!user) {
        //User *
        user = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(User.class) inManagedObjectContext:context];
        user.idUser = idUser.integerValue; // идентификатор юзера.
    }
    
    if (user) {
        user.first_name = dict[@"first_name"];
        user.last_name = dict[@"last_name"];
        user.photo = dict[@"photo_50"];
    }
    
    return user;
}

- (User *) getUserWithID:(NSNumber*)idUser context:(NSManagedObjectContext* _Nonnull)context
{
    if (idUser) {
        NSFetchRequest *req = [User fetchRequest];
        req.predicate = [NSPredicate predicateWithFormat:@"idUser = %@", idUser];
        NSArray * res = [context executeFetchRequest:req error:nil];
        if (res.count > 0) {
            return res[0];
        }
    }
    return nil;
}

- (void) deleteAll
{
    NSManagedObjectContext *context = self.moc;
    for (Class class in @[User.class, Image.class, Event.class]) {
        NSFetchRequest *req = [class fetchRequest];
        NSArray * res = [context executeFetchRequest:req error:nil];
        for (NSInteger i = 0; i < res.count; i++) {
            [context deleteObject:res[i]];
        }
    }
    [self saveContext:context];
}

#pragma mark - Helpersы

- (NSDictionary *) dictFromJSON:(NSData *)dataJson
{
    if (!dataJson) {
        return nil;
    }
    
    NSError * error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData: dataJson
                                                    options: NSJSONReadingMutableContainers
                                                      error: &error];
    
    if (error == nil && [jsonObject isKindOfClass:NSDictionary.class]) {
        return jsonObject;
    }
    
    DLog(@"%@", error.localizedDescription);
    return nil;
}

- (NSArray *) arrayFromJSON:(NSData *)dataJson
{
    if (!dataJson) {
        return nil;
    }
    
    NSError * error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData: dataJson
                                                    options: NSJSONReadingMutableContainers
                                                      error: &error];
    
    if (error == nil && [jsonObject isKindOfClass:NSArray.class]) {
        return jsonObject;
    }
    
    DLog(@"%@", error.localizedDescription);
    return nil;
}


- (void)debugRequest:(NSURLRequest*)request response:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error
{
#ifdef DEBUG
    
    ALog(@"\n\n🌐 -▽-▽-▽-▽-▽------------------------------------ Запрос:\n\n%@:  %@\n\n%@\n\n%@",
         request.HTTPMethod, request.URL,
         request.allHTTPHeaderFields,
         [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    NSHTTPURLResponse * resp = (NSHTTPURLResponse *)response;
    //NSStringEncoding encoding = [NSString stringEncodingForData:subData encodingOptions:nil convertedString:nil usedLossyConversion:nil];
    //NSString *responseString = [[NSString alloc] initWithData:subData encoding:encoding];
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    //NSString *file =  [NSString stringWithFormat:@"/Users/Dima/Downloads/___%ld___LDD.xml", (long)self->prefs.counter];
    //[responseString writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    ALog(@"\n     ----------------- deUnicodeString & deHtmlString Ответ %ld байт:\n\n%@%@\n\n%@\n\n-△-△-△-△-△------------------------------------\n\n",
         (long)data.length,
         resp.allHeaderFields,
         error?[NSString stringWithFormat:@"\n‼️Ошибка: %@", error]:@"",
         responseString); // .deUnicodeString.deHtmlString
#endif
    
}


@end
