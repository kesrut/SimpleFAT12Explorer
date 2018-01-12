//
//  Item.h
//  SimpleFAT12
//
//  Created by Kestutis Rutkauskas on 13/09/2017.
//  Copyright © 2017 Kęstutis Rutkauskas. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Item : NSObject

@property (strong) NSString *name ;
@property (strong) NSString *size ;
@property (assign) unsigned short start ;
@property (assign) BOOL directory ;
@property (assign) long fileSize ;

@end
