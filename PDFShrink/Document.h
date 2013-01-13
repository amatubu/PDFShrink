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

    IBOutlet id _exportToMobiAccessoryView;
    IBOutlet id _pdfTitle;
    IBOutlet id _pdfAuthor;
    IBOutlet id _pdfPageDirection;
    
    BOOL needAbort;

    NSString *pdfTitle;
    NSString *pdfAuthor;
    NSInteger pdfPageDirection;
}
- (IBAction)shrink:(id)sender;
- (IBAction)abortShrink:(id)sender;
- (IBAction)exportToCBZ:(id)sender;
- (IBAction)exportToMobi:(id)sender;
@end
