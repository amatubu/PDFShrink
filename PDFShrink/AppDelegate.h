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
}
-(IBAction)savePreferences:(id)sender;
@end
