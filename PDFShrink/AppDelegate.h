//
//  AppDelegate.h
//  PDFShrink
//
//  Created by naoki iimura on 9/25/12.
//  Copyright (c) 2012 naoki iimura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppDelegate : NSObject
{
    IBOutlet id _preferencesPanel;
    
    IBOutlet id _eBookList;
    
    NSArray *eBookReaders;
}
-(IBAction)showPreferences:(id)sender;
-(IBAction)savePreferences:(id)sender;
-(IBAction)selectEBookReader:(id)sender;
@end
