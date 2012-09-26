//
//  Document.h
//  PDFShrink
//
//  Created by naoki iimura on 9/25/12.
//  Copyright (c) 2012 naoki iimura. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import <PDFKit/PDFKit.h>
#import <Quartz/Quartz.h>

@interface Document : NSDocument
{
    IBOutlet id _pdfView;
    IBOutlet id _progressPanel;
    IBOutlet id _progressIndicator;
    IBOutlet id window;
}
- (IBAction)shrink:(id)sender;
@end
