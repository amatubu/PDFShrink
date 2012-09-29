//
//  AppDelegate.m
//  PDFShrink
//
//  Created by naoki iimura on 9/25/12.
//  Copyright (c) 2012 naoki iimura. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL) applicationShouldOpenUntitledFile: (NSApplication *) application
{
    return NO;
}

- (IBAction) savePreferences:(id)sender;
{
    [_preferencesPanel close];
}

@end
