//
//  Document.m
//  PDFShrink
//
//  Created by naoki iimura on 9/25/12.
//  Copyright (c) 2012 naoki iimura. All rights reserved.
//

#import "Document.h"

@implementation Document

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.

    PDFDocument *pdfDoc = [[PDFDocument alloc] initWithURL: [self fileURL]];
    
    [_pdfView setDocument: pdfDoc];

    // とりあえずテスト
    
    // 新しいPDF作成
    PDFDocument *newPdf = [[PDFDocument alloc] init];
    
    // ページ数を取得
    NSUInteger pageCount = [pdfDoc pageCount];
    
    // ページをループ
    for (NSUInteger i = 0; i < pageCount; i++) {
        // ページを取りだす
        PDFPage *page = [pdfDoc pageAtIndex:i];
        
        // ページをPDFイメージに
        NSData *pageData = [page dataRepresentation];
        NSPDFImageRep *pdfImageRep = [[NSPDFImageRep alloc] initWithData: pageData];
        
        // 幅と高さ
        NSSize size;
        size.width = [pdfImageRep pixelsWide] * 2;
        size.height = [pdfImageRep pixelsHigh] * 2;
        
        // 幅と高さを調整
        // 754x584 以内に
        if ( size.width * 754 > size.height * 584) {
            // 横長
            if ( size.width > 584 ) {
                size.height = size.height * 584 / size.width;
                size.width = 584;
            }
        } else {
            // 縦長
            if ( size.height > 754 ) {
                size.width = size.width * 754 / size.height;
                size.height = 754;
            }
        }
        
        // ビットマップイメージを作成
        // 2ページ目以降はモノクロ化
        NSBitmapImageRep *bitmapRep =
            [[NSBitmapImageRep alloc]
                initWithBitmapDataPlanes: NULL
                 pixelsWide:              size.width
                 pixelsHigh:              size.height
                 bitsPerSample:           8
                 samplesPerPixel:         1 //( i == 0 ? 3 : 1)
                 hasAlpha:                NO
                 isPlanar:                NO
                 colorSpaceName:          NSCalibratedWhiteColorSpace //( i == 0 ? NSCalibratedRGBColorSpace : NSCalibratedWhiteColorSpace )
                 bytesPerRow:             0
                 bitsPerPixel:            0];
        
        // グラフィックコンテクストの状態を保存
        [NSGraphicsContext saveGraphicsState];
        
        // 新しいコンテクストを作成し、カレントに設定
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep: bitmapRep];
        [NSGraphicsContext setCurrentContext: context];
        
        // PDFページのイメージを描画
        [pdfImageRep drawInRect: NSMakeRect( 0, 0, size.width, size.height)];
        
        // コンテクストを元に戻す
        [NSGraphicsContext restoreGraphicsState];
        
        // JPEGの圧縮率を設定
        NSDictionary *propJpeg =
            [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithFloat: 0.8],
                NSImageCompressionFactor,
                nil];
        
        // JPEGデータに変換
        NSData *dataJpeg = [bitmapRep representationUsingType: NSJPEGFileType properties: propJpeg];
        
        // できたPDFからイメージに
        NSImage *newImage = [[NSImage alloc] initWithData: dataJpeg];
        
        // イメージをPDFページに
        PDFPage *newPage = [[PDFPage alloc] initWithImage: newImage];
        
        // 新しいページをPDFに追加
        [newPdf insertPage: newPage atIndex: [newPdf pageCount]];
    }
    
    // PDF を書き出し
    [newPdf writeToFile: @"/Users/sent/Desktop/out.pdf"];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    
    return YES;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
//    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
//    @throw exception;
    return YES;
}

@end
