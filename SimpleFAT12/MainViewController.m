//
//  MainViewController.m
//  SimpleFAT12
//
//  Created by Kestutis Rutkauskas on 13/09/2017.
//  Copyright © 2017 Kęstutis Rutkauskas. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _files = [[NSMutableArray alloc] init] ;
    [_table setDelegate:(id)self] ;
    [_table setDoubleAction:@selector(select:)] ;
}

unsigned short *fat ;
struct fat_BS boot ;
FILE *fp ;

typedef struct fat_BS
{
    unsigned char 		bootjmp[3];
    unsigned char 		oem_name[8];
    unsigned short 	    bytes_per_sector;
    unsigned char		sectors_per_cluster;
    unsigned short		reserved_sector_count;
    unsigned char		table_count;
    unsigned short		root_entry_count;
    unsigned short		total_sectors_16;
    unsigned char		media_type;
    unsigned short		table_size_16;
    unsigned short		sectors_per_track;
    unsigned short		head_side_count;
    unsigned int 		hidden_sector_count;
    unsigned int 		total_sectors_32;
    unsigned char		extended_section[54];
    
}__attribute__((packed)) fat_BS_t;


typedef struct directory
{
    unsigned char name[8] ;
    unsigned char ext[3] ;
    unsigned char attr ;
    unsigned short reserved ;
    unsigned short create_time ;
    unsigned short create_date ;
    unsigned short last_access ;
    unsigned short temp ;
    unsigned short last_write_time ;
    unsigned short last_write_date ;
    unsigned short first ;
    unsigned int size ;
} __attribute__((packed)) dir_type;




- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_files count] ;
}

- (void) readSector: (unsigned short) sector buffer: (unsigned char*) buff length: (unsigned short) length
{
        size_t s = 0 ;
        int i = 0 ;
        while (s < length)
        {
            unsigned char c;
            size_t k = fread(&c, 1, 1, fp) ;
            if (k > 0)
            {
                buff[i] = c ;
                i++ ;
            }
            s = s + k ;
        }
}

 - (void) writeSector: (FILE*) f buffer: (unsigned char*) buff length: (unsigned short) length
{
    size_t s = 0 ;
    int i = 0 ;
    while (s < length)
    {
        unsigned char c = buff[i] ;
        size_t k = fwrite(&c, 1, 1, f) ;
        i++ ;
        s = s + k ;
    }
}

- (void) getDirectory: (unsigned short) start
{
    if (fp != NULL)
    {
        [_files removeAllObjects] ;
        unsigned short first_root = boot.reserved_sector_count + (boot.table_count * boot.table_size_16) ;
        unsigned short root_sectors = (boot.root_entry_count * 32 + (boot.bytes_per_sector - 1)) / boot.bytes_per_sector;
        unsigned short data_start = first_root + root_sectors ;
        if (start == 0)
        {
            [self getRoot] ;
            return ;
        }
        NSMutableArray *indexes = [self get_clusters:start] ;
        if (indexes != NULL)
        {
            int i = 0 ;
            int p = 0 ;
            for (i=0; i < [indexes count]; i++)
            {
                unsigned short sector = data_start + [[indexes objectAtIndex:i] intValue] - 2 ;
                fseek(fp, sector * boot.bytes_per_sector, SEEK_SET) ;
                while (p < 32)
                {
                struct directory dir ;
                fread(&dir, sizeof(dir_type), 1, fp) ;
                if (dir.name[0] == 0) break ;
                if (dir.name[0] != 0xe5 && dir.name[0] != 0x0)
                {
                    char name[9] ;
                    strncpy(name, (char*)dir.name, 8) ;
                    name[8] = '\0' ;
                    char ext[4] ;
                    strncpy(ext, (char*)dir.ext, 3) ;
                    ext[3] = '\0' ;
                    NSString *nameStr = [NSString stringWithFormat:@"%s", name] ;
                    NSString *extStr = [NSString stringWithFormat:@"%s", ext] ;
                    NSString *realName = [nameStr stringByReplacingOccurrencesOfString:@" " withString:@""] ;
                    NSString *finalName = [NSString stringWithFormat:@"%@.%@", realName, extStr] ;
                    Item *item = [[Item alloc] init] ;
                    if (dir.attr & 0x10)
                    {
                        finalName = realName ;
                    }
                    item.name = finalName ;
                    NSString *size = [NSString stringWithFormat:@"%u bytes", dir.size] ;
                    if (dir.attr & 0x10)
                    {
                        item.directory  = YES ;
                        size = @"Directory" ;
                    }
                    item.size = size ;
                    item.start = dir.first ;
                    item.fileSize = dir.size ;
                    [_files addObject:item] ;
                }
                    p++ ;
                }
                i++ ;
            }
        }
    }
    [_table reloadData] ;
}
- (void) getRoot
{
    if (fp != NULL)
    {
        [_files removeAllObjects] ;
        fseek(fp, 0, SEEK_SET) ;
        fread(&boot, sizeof(fat_BS_t), 1, fp) ;
        unsigned short first_root = boot.reserved_sector_count + (boot.table_count * boot.table_size_16) ;
        fseek(fp, first_root * 512, SEEK_SET) ;
        int i = 0 ;
        while (i < boot.root_entry_count)
        {
            struct directory dir ;
            fread(&dir, sizeof(dir_type), 1, fp) ;
            //if (dir.name[0] == 0) break ;
            if (dir.name[0] != 0xe5 && dir.name[0] != 0x0)
            {
                char name[9] ;
                strncpy(name, (char*)dir.name, 8) ;
                name[8] = '\0' ;
                char ext[4] ;
                strncpy(ext, (char*)dir.ext, 3) ;
                ext[3] = '\0' ;
                NSString *nameStr = [NSString stringWithFormat:@"%s", name] ;
                NSString *extStr = [NSString stringWithFormat:@"%s", ext] ;
                NSString *realName = [nameStr stringByReplacingOccurrencesOfString:@" " withString:@""] ;
                NSString *finalName = [NSString stringWithFormat:@"%@.%@", realName, extStr] ;
                Item *item = [[Item alloc] init] ;
                if (dir.attr & 0x10)
                {
                    finalName = realName ;
                }
                item.name = finalName ;
                NSString *size = [NSString stringWithFormat:@"%u bytes", dir.size] ;
                if (dir.attr & 0x10)
                {
                    item.directory  = YES ;
                    size = @"Directory" ;
                }
                item.size = size ;
                item.start = dir.first ;
                item.fileSize = dir.size ;
                if (!(dir.attr & 0x08))
                {
                    [_files addObject:item] ;
                }
                else
                {
                    NSString *volume_label = [NSString stringWithFormat:@"Volume Label: %@", nameStr] ;
                    _label.stringValue = volume_label ;
                }
            }
            i++ ;
        }
        [_table reloadData] ;
    }
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row

{
    NSTextField* textField = [tableView makeViewWithIdentifier:@"TextField" owner:self] ;
    Item *item = [self.files objectAtIndex:row] ;
    if (textField == nil) {
        textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        [textField setBordered:NO];
        [textField setEditable:NO];
        [textField setDrawsBackground:NO];
        textField.identifier = @"TextField";
    }
    if ([tableColumn.identifier isEqualToString:@"Name"]) {
        textField.stringValue = item.name ;
    } else
        if ([tableColumn.identifier isEqualToString:@"Details"]) {
            textField.stringValue = item.size ;
        }
    return textField;
}

- (IBAction) open: (id) sender 
{
    NSWindow* window = [[self view] window];
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSString* path = [[panel URL] path];
            [self openFile:path] ;
            [self getRoot]  ;
            [self readFat] ;
            [_table reloadData] ;
        }
    }];
}


- (void) select: (id) object
{
    NSInteger row = [_table clickedRow] ;
    Item *item = [_files objectAtIndex:row] ;
    if (item.directory == YES)
    {
        [self getDirectory:item.start] ;
    }
    else
    {
        NSWindow*  window = [[self view] window] ;
        NSSavePanel*    panel = [NSSavePanel savePanel];
        [panel setNameFieldStringValue:item.name];
        [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton)
            {
                NSString*  theFile = [[panel URL] path];
                [self writeFile:item.start name:theFile size:item.fileSize] ;
            }
        }];
    }
}

- (void) writeFile: (unsigned int) start name: (NSString*) name size: (long) size
{
    if (fp != NULL)
    {
        unsigned short first_root = boot.reserved_sector_count + (boot.table_count * boot.table_size_16) ;
        unsigned short root_sectors = (boot.root_entry_count * 32 + (boot.bytes_per_sector - 1)) / boot.bytes_per_sector;
        unsigned short data_start = first_root + root_sectors ;
        
        NSMutableArray *indexes = [self get_clusters:start] ;
        if ([indexes count] > 0)
        {
            FILE *f;
            f = fopen([name UTF8String], "wb") ;
            if (f == NULL) return ;
            int i = 0 ;
            for (i=0; i < [indexes count]; i++)
            {
                unsigned short sector = data_start + [[indexes objectAtIndex:i] intValue] - 2 ;
                fseek(fp, sector * boot.bytes_per_sector, SEEK_SET) ;
                if (i < ([indexes count] - 1))
                {
                    unsigned char buff[512] ;
                    [self readSector:sector buffer:buff length:512] ;
                    [self writeSector:f buffer:buff length:512] ;
                }
                else
                {
                    long end = (size % 512) ;
                    unsigned char buff[512] ;
                    [self readSector:sector buffer:buff length:end] ;
                    [self writeSector:f buffer:buff length:end] ;
                    fclose(f) ;
                }
            }
        }
        
    }
}

- (NSMutableArray*) get_clusters: (unsigned short) first
{
    unsigned short value = first ;
    NSMutableArray *indexes = [[NSMutableArray alloc] init] ;
    BOOL failure = NO ;
    do
    {
        [indexes addObject:[NSNumber numberWithInteger:value]] ;
        value = fat[value] ;
        if (value == 0 || ((value >= 0xFF0) && (value <= 0xff6 )) || value == 0xFF7) { failure = YES; break ; }
    }
    while (!((value >= 0xFF8) && (value <= 0xFFF))) ;
    if (failure == NO)
    {
        return indexes ;
    }
    else
        return NULL ;
}


- (BOOL) openFile: (NSString*) name
{
    fp = fopen([name UTF8String], "r") ;
    if (fp != NULL)
    {
        return YES ;
    }
    else return NO ;
}

- (void) readFat
{
    unsigned char *fat12 = (unsigned char*) malloc(boot.table_size_16 * 512) ;
    unsigned short fat_start = boot.reserved_sector_count ;
    fseek(fp, fat_start * 512, SEEK_SET) ;
    //fread(fat12, boot.table_size_16 * 512, 1, fp) ;
    int i = 0 ;
    size_t s = 0;
    while (s < boot.table_size_16 * 512)
    {
        unsigned char c;
        size_t k = fread(&c, 1, 1, fp) ;
        if (k > 0)
        {
            fat12[i] = c ;
            i++ ;
        }
        s = s + k ;
    }
    fat = (unsigned short*) malloc(boot.table_size_16 * 512 * 2) ;
    int p = 0 ;
    i = 0 ;
    while (p < (boot.table_size_16 * 512))
    {
        unsigned char v1 = 0 ;
        v1 = fat12[p] ;
        unsigned char v2 = 0 ;
        p++ ;
        v2 = fat12[p];
        p++ ;
        unsigned char v3 = 0 ;
        v3 = fat12[p] ;
        p++ ;
        unsigned short first = (v1 | ((v2 & 0x0F) << 8)) & 0xFFF ;
        unsigned short second = (((v2 & 0xF0) >> 4) | (v3 << 4)) & 0xFFF ;
        fat[i] = first ;
        i++ ;
        fat[i] = second;
        i++ ;
    }
    free(fat12) ;
    free(fat) ;

}
- (void) awakeFromNib
{
}

@end
