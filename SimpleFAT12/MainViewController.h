//
//  MainViewController.h
//  SimpleFAT12
//
//  Created by Kestutis Rutkauskas on 13/09/2017.
//  Copyright © 2017 Kęstutis Rutkauskas. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Item.h"

@interface MainViewController : NSViewController <NSTableViewDataSource, NSTabViewDelegate>

@property (strong) NSMutableArray *files ;
@property (strong) IBOutlet NSTableView *table ;
@property (strong) IBOutlet NSTextField *label ;

- (IBAction) open: (id) sender ;

@end
