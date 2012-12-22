//
//  AppDelegate.m
//  PDFShrink
//
//  Created by naoki iimura on 9/25/12.
//  Copyright (c) 2012 naoki iimura. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

-(id) init
{
    self = [super init];
    if (self) {
        // 初期設定
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger maxWidth;
        NSInteger maxHeight;

        maxWidth = [defaults integerForKey: @"maxWidth"];
        maxHeight = [defaults integerForKey: @"maxHeight"];
        if ( maxWidth <= 0 ) {
            maxWidth = 658;
            [defaults setInteger: maxWidth forKey: @"maxWidth"];
        }
        if ( maxHeight <= 0 ) {
            maxHeight = 905;
            [defaults setInteger: maxHeight forKey: @"maxHeight"];
        }
        
        // 電子書籍リーダー設定を取得
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *path = [bundle pathForResource:@"EBookReader" ofType:@"plist"];
        NSArray *readers = [NSArray arrayWithContentsOfFile:path];
        
        for ( NSDictionary *reader in readers ) {
            NSLog( @"name:%@", [reader objectForKey:@"name"] );
            NSLog( @"width:%@", [reader objectForKey:@"width"] );
            NSLog( @"height:%@", [reader objectForKey:@"height"] );
            
            [_eBookList addItemWithTitle:[reader objectForKey:@"name"]];
        }
    }
    return self;
}

- (BOOL) applicationShouldOpenUntitledFile: (NSApplication *) application
{
    return NO;
}

- (IBAction) savePreferences:(id)sender
{
    [_preferencesPanel close];
}

@end
