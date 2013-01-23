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

        // 最大の幅と高さ
        NSInteger maxWidth;
        NSInteger maxHeight;
        
        maxWidth = [defaults integerForKey:@"maxWidth"];
        maxHeight = [defaults integerForKey:@"maxHeight"];
        if ( maxWidth <= 0 ) {
            maxWidth = 658;
            [defaults setInteger:maxWidth forKey:@"maxWidth"];
        }
        if ( maxHeight <= 0 ) {
            maxHeight = 905;
            [defaults setInteger:maxHeight forKey:@"maxHeight"];
        }
        
        // JPEG の画質
        NSInteger jpegQuality;
        jpegQuality = [defaults integerForKey:@"jpegQuality"];
        if ( jpegQuality <= 0 || jpegQuality > 100 ) {
            jpegQuality = 80;
            [defaults setInteger:jpegQuality forKey:@"jpegQuality"];
        }
        
        // 輝度
        float brightness;
        brightness = [defaults floatForKey:@"brightness"];
        if ( brightness < -1.0 || brightness > 1.0 ) {
            brightness = 0.0;
            [defaults setFloat:brightness forKey:@"brightness"];
        }
        
        // コントラスト
        float contrast;
        contrast = [defaults floatForKey:@"contrast"];
        if ( contrast < 0.25 || contrast > 4.0 ) {
            contrast = 1.0;
            [defaults setFloat:contrast forKey:@"contrast"];
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

// スライダーの値が変更されたとき
- (IBAction) sliderValueChanged:(id)sender {
    NSSlider *slider = (NSSlider *)sender;

    if ( [slider tag] == 1 ) {
        // JPEG 画質のスライダーは、整数値のみを許す
        [slider setIntValue:roundf( [slider floatValue] )];
    } else {
        // それ以外のスライダーは、小数第2位まで許す
        [slider setFloatValue:roundf( [slider floatValue] * 100.0 ) / 100.0];
    }
}

@end
