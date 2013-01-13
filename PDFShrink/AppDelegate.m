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
        
        // kindlegen のパス
        NSString *pathToKindlegen;

        pathToKindlegen = [defaults stringForKey:@"kindlegenPath"];
        if ( pathToKindlegen == nil) {
            NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
            pathToKindlegen  = [[bundlePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"kindlegen"];
            NSLog( @"%@", pathToKindlegen );
            [defaults setValue:pathToKindlegen forKey:@"kindlegenPath"];
        }
        
        // 電子書籍リーダー設定を取得
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *path = [bundle pathForResource:@"EBookReader" ofType:@"plist"];
        eBookReaders = [NSArray arrayWithContentsOfFile:path];
    }
    return self;
}

- (BOOL) applicationShouldOpenUntitledFile: (NSApplication *) application
{
    return NO;
}

- (IBAction) showPreferences:(id)sender
{
    // 電子書籍リーダー設定をメニューに反映
    for ( NSDictionary *reader in eBookReaders ) {
        [_eBookList addItemWithTitle:[reader objectForKey:@"name"]];
    }

    [_preferencesPanel makeKeyAndOrderFront:self];
}

// 選択された電子書籍リーダーの設定を反映する
- (IBAction) selectEBookReader:(id)sender
{
    NSInteger selectedItem = [_eBookList indexOfSelectedItem];
    
    // 1行目は無視
    if ( selectedItem > 0 ) {
        // 幅、高さの最大値を設定
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger: [[eBookReaders objectAtIndex: selectedItem - 1] integerForKey:@"width"] forKey:@"maxWidth"];
        [defaults setInteger: [[eBookReaders objectAtIndex: selectedItem - 1] integerForKey:@"height"] forKey:@"maxHeight"];
    }
}

- (IBAction) savePreferences:(id)sender
{
    [_preferencesPanel close];
}

@end
