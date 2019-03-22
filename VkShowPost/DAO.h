//
//  DAO.h
//
//  Created by Dmitry Likhtarov on 10/01/2019.
//  Copyright © 2018 Geomatix Laboratoriess S.R.O. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import  <SAMKeychain/SAMKeychain.h>

#import "VkShowPost+CoreDataModel.h"


@interface DAO : NSObject

+ (DAO *) sharedInstance;

@property (readonly, strong) NSPersistentContainer *persistentContainer; // Хранилище
@property (nonatomic, retain) NSManagedObjectContext *moc; // Основной контекст
@property (nonatomic, strong) NSOperationQueue* persistentContainerQueue; // Очередь фоновой записи локальной базы

- (void)saveContext:(NSManagedObjectContext* _Nullable)context;
- (void)enqueueCoreDataBlock:(void (^)(NSManagedObjectContext* context))block completion:(void (^)(void))completion;

#pragma mark -

@property (nonatomic, retain) NSString * access_token;
@property (nonatomic, retain) NSString * user_id;
@property (nonatomic, retain) NSDate * expires_date; // интервал жизни токена


#pragma mark -

- (void)getPortionOffset:(NSInteger)offset completion:(void (^)(NSError * _Nullable error))completion;

- (void) deleteAll;

#pragma mark -


#ifdef DEBUG
#define DLog(fmt, ...) printf("%s\n", [[NSString stringWithFormat:(@"%s[%d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__] UTF8String])
#define ALog(fmt, ...) printf("%s\n", [[NSString stringWithFormat:(fmt), ##__VA_ARGS__] UTF8String])
#else
#define DLog(...)
#define ALog(...)
#endif

@end

