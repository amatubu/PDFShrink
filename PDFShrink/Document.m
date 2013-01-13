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
    
    PDFDocument *pdfDoc;
    
    if ( [self fileURL] ) {
        pdfDoc = [[PDFDocument alloc] initWithURL: [self fileURL]];
    } else {
        pdfDoc = [[PDFDocument alloc] init];
    }
    
    [_pdfView setDocument: (NSDocument*)pdfDoc];

}

// PDFの画像を縮小する
- (IBAction)shrink:(id)sender {
    // ファイル名
    NSString *name = [[self fileURL] path];

    // 新しいファイル名の候補
    NSString *newPath = [name stringByDeletingLastPathComponent];
    NSString *newName = [name lastPathComponent];
    newName = [newName
               stringByReplacingOccurrencesOfString: @".pdf"
                                         withString: @"_l.pdf"
                                            options: NSCaseInsensitiveSearch
                                              range: NSMakeRange(0, [newName length] )
               ];
    
    // フロントウィンドウ
    NSWindow *myWindow = [[[self windowControllers] objectAtIndex: 0] window];

    // 保存ダイアログの表示
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    // デフォルトのファイル名とパス
    [panel setNameFieldStringValue: newName];
    [panel setDirectoryURL: [NSURL fileURLWithPath: newPath]];
    
    // 保存ダイアログの処理
    [panel beginSheetModalForWindow: myWindow
     completionHandler:^(NSInteger result) {
         if ( result == NSFileHandlingPanelOKButton ) {
             // ファイル名を得る
             NSURL *file = [panel URL];
             NSString *newFile = [file path];
             
             [panel close];
             
             NSDictionary *arg = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [_pdfView document], @"pdfDoc",
                                  newFile, @"outFile",
                                  myWindow, @"frontWindow",
                                  nil];
             needAbort = FALSE;
             [NSThread detachNewThreadSelector:@selector(exportToPDFMain:)
                                      toTarget:self
                                    withObject:arg];
         }
     }];
}

// PDFの画像を縮小してCBZ形式で保存する
- (IBAction)exportToCBZ:(id)sender {
    // ファイル名
    NSString *name = [[self fileURL] path];
    
    // 新しいファイル名の候補
    NSString *newPath = [name stringByDeletingLastPathComponent];
    NSString *newName = [name lastPathComponent];
    newName = [newName
               stringByReplacingOccurrencesOfString: @".pdf"
               withString: @".cbz"
               options: NSCaseInsensitiveSearch
               range: NSMakeRange(0, [newName length] )
               ];
    
    // フロントウィンドウ
    NSWindow *myWindow = [[[self windowControllers] objectAtIndex: 0] window];
    
    // 保存ダイアログの表示
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    // デフォルトのファイル名とパス
    [panel setNameFieldStringValue: newName];
    [panel setDirectoryURL: [NSURL fileURLWithPath: newPath]];
    
    // 保存ダイアログの処理
    [panel beginSheetModalForWindow: myWindow
                  completionHandler:^(NSInteger result) {
                      if ( result == NSFileHandlingPanelOKButton ) {
                          // ファイル名を得る
                          NSURL *file = [panel URL];
                          NSString *newFile = [file path];
                          
                          [panel close];
                          
                          NSDictionary *arg = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [_pdfView document], @"pdfDoc",
                                               newFile, @"outFile",
                                               myWindow, @"frontWindow",
                                               nil];
                          needAbort = FALSE;
                          [NSThread detachNewThreadSelector:@selector(exportToCBZMain:)
                                                   toTarget:self
                                                 withObject:arg];
                      }
                  }];
}

// PDF画像の縮小を中止する
- (IBAction)abortShrink:(id)sender {
    needAbort = YES;
}

// PDFの縮小メイン
- (void)exportToPDFMain:(NSDictionary *)arg
{
    // 設定を得る
    NSInteger maxWidth;
    NSInteger maxHeight;
    
    [self getMaxWidth:&maxWidth maxHeight:&maxHeight];
    
    // プログレスバーを用意する
	[self createProgressPanel:[arg objectForKey: @"frontWindow"]];
    
    // PDFドキュメントを得る
    PDFDocument *pdfDoc = [arg objectForKey: @"pdfDoc"];
    
    // 新しいPDF作成
    PDFDocument *newPdf = [[PDFDocument alloc] init];
    
    // ページ数を取得
    NSUInteger pageCount = [pdfDoc pageCount];
    
    // ページをループ
    for (NSUInteger i = 0; i < pageCount; i++) {
        // ページを取りだしてJPEGデータに変換
        NSData *dataJpeg = [self getShrunkJPEGData:pdfDoc atIndex:i maxWidth:maxWidth maxHeight:maxHeight];
        
        // できたPDFからイメージに
        NSImage *newImage = [[NSImage alloc] initWithData: dataJpeg];
        
        // イメージをPDFページに
        PDFPage *newPage = [[PDFPage alloc] initWithImage: newImage];
        
        // 新しいページをPDFに追加
        [newPdf insertPage: newPage atIndex: [newPdf pageCount]];
        
        // プログレスバーを進める
        [_progressIndicator setDoubleValue: ((double)i) / ((double)pageCount)];
        
        // 中断なら止める
        if ( needAbort ) break;
    }
    
    if ( !needAbort ) {
        // PDF を書き出し
        [newPdf writeToFile: [arg objectForKey: @"outFile"]];
    }
    
    // プログレスバーを閉じる
	[NSApp endSheet:_progressPanel];
}

// CBZへのエクスポートメイン
- (void)exportToCBZMain:(NSDictionary *)arg
{
    // 設定を得る
    NSInteger maxWidth;
    NSInteger maxHeight;
    
    [self getMaxWidth:&maxWidth maxHeight:&maxHeight];
    
    // テンポラリディレクトリを取得
    NSString *tempDir = [self createTemporaryDirectory];
    
    // プログレスバーを用意する
	[self createProgressPanel:[arg objectForKey: @"frontWindow"]];
    
    // PDFドキュメントを得る
    PDFDocument *pdfDoc = [arg objectForKey: @"pdfDoc"];
    
    // ページ数を取得
    NSUInteger pageCount = [pdfDoc pageCount];
    
    // ページをループ
    for (NSUInteger i = 0; i < pageCount; i++) {
        // ページを取りだしてJPEGデータに変換
        NSData *dataJpeg = [self getShrunkJPEGData:pdfDoc atIndex:i maxWidth:maxWidth maxHeight:maxHeight];
        
        // テンポラリディレクトリに保存
        BOOL result = [dataJpeg writeToFile:[tempDir stringByAppendingPathComponent:
                                             [NSString stringWithFormat:@"%08ld.jpg", i]]
                       atomically:YES];
        
        // プログレスバーを進める
        [_progressIndicator setDoubleValue: ((double)i) / ((double)pageCount)];
        
        // 中断なら止める
        if ( needAbort ) break;
    }
    
    if ( !needAbort ) {
        // CBZ に変換
        NSString *command = [[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:@"CreateCBZ.sh"];
        NSString *outFile = [arg objectForKey:@"outFile"];
        NSArray *params = [NSArray arrayWithObjects:command, outFile, nil];
        
        NSString *result = [self executeUnixCommandWithParams:params workingDir:tempDir];
        NSLog( @"%@", result );
    }
    
    // テンポラリディレクトリを削除
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:tempDir
                            error:&error];
    
    // プログレスバーを閉じる
	[NSApp endSheet:_progressPanel];
}

// プログレスバーのシートを閉じる
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet close];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // PDF ビューの内容を出力
    return [[_pdfView document] dataRepresentation];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    return YES;
}

// テンポラリディレクトリを作成
- (NSString *)createTemporaryDirectory
{
    NSString *tempDirectoryTemplate =
        [NSTemporaryDirectory() stringByAppendingPathComponent:@"PDFShrinkTemp.XXXXXX"];
    const char *tempDirectoryTemplateCString =
        [tempDirectoryTemplate fileSystemRepresentation];
    char *tempDirectoryNameCString =
        (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
    strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
    
    char *result = mkdtemp(tempDirectoryNameCString);
    if (!result)
    {
        return nil;
    }
    
    NSString *tempDirectoryPath =
        [[NSFileManager defaultManager]
         stringWithFileSystemRepresentation:tempDirectoryNameCString
         length:strlen(result)];
    free(tempDirectoryNameCString);

    return tempDirectoryPath;
}

// 最大サイズを得る
- (void)getMaxWidth:(NSInteger *)maxWidth maxHeight:(NSInteger *)maxHeight
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    *maxWidth = [defaults integerForKey: @"maxWidth"];
    *maxHeight = [defaults integerForKey: @"maxHeight"];
    if ( *maxWidth <= 0 ) {
        *maxWidth = 584;
        [defaults setInteger: *maxWidth forKey: @"maxWidth"];
    }
    if ( *maxHeight <= 0 ) {
        *maxHeight = 754;
        [defaults setInteger: *maxHeight forKey: @"maxHeight"];
    }
}

// プログレスパネルを用意
- (void)createProgressPanel:(NSWindow *)frontWindow
{
	[NSApp beginSheet:_progressPanel
       modalForWindow:frontWindow
        modalDelegate:self
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
	[_progressIndicator setDoubleValue:0.0];
}

// PDFの指定ページをJPEGデータとして取り出す
- (NSData *)getShrunkJPEGData:(PDFDocument *)pdfDoc atIndex:(NSUInteger)i maxWidth:(NSInteger)maxWidth maxHeight:(NSInteger)maxHeight
{
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
    if ( size.width * maxHeight > size.height * maxWidth) {
        // 横長
        if ( size.width > maxWidth ) {
            size.height = size.height * maxWidth / size.width;
            size.width = maxWidth;
        }
    } else {
        // 縦長
        if ( size.height > maxHeight ) {
            size.width = size.width * maxHeight / size.height;
            size.height = maxHeight;
        }
    }
    
    // ビットマップイメージを作成
    NSBitmapImageRep *bitmapRep;
    
    if ( i == 0 ) {
        // 1ページ目はカラーのまま
        bitmapRep =
        [[NSBitmapImageRep alloc]
         initWithBitmapDataPlanes: NULL
         pixelsWide:              size.width
         pixelsHigh:              size.height
         bitsPerSample:           8
         samplesPerPixel:         4 // ARGB
         hasAlpha:                YES // アルファチャンネルあり
         isPlanar:                NO
         colorSpaceName:          NSCalibratedRGBColorSpace
         bitmapFormat:            NSAlphaFirstBitmapFormat
         bytesPerRow:             0
         bitsPerPixel:            0];
    } else {
        // 2ページ目以降はモノクロ化
        bitmapRep =
        [[NSBitmapImageRep alloc]
         initWithBitmapDataPlanes: NULL
         pixelsWide:              size.width
         pixelsHigh:              size.height
         bitsPerSample:           8
         samplesPerPixel:         1 // モノクロ
         hasAlpha:                NO // アルファチャンネルなし
         isPlanar:                NO
         colorSpaceName:          NSCalibratedWhiteColorSpace
         bytesPerRow:             0
         bitsPerPixel:            0];
    }
    
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
    
    return dataJpeg;
}

// コマンドを実行する
- (NSString *)executeUnixCommandWithParams:(NSArray *)commandAndParams workingDir:(NSString *)workingDirectory {
    NSPipe *newPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSData *inData = nil;
    NSString *returnValue = nil;
    
    NSTask *unixTask = [[NSTask alloc] init];
    [unixTask setStandardOutput:newPipe];
    [unixTask setLaunchPath:@"/bin/sh"];
    [unixTask setArguments:commandAndParams];
    [unixTask setCurrentDirectoryPath:workingDirectory];
    [unixTask launch];
    [unixTask waitUntilExit];
    int status = [unixTask terminationStatus];
    
    while ((inData = [readHandle availableData]) && [inData length]) {
        
        returnValue= [[NSString alloc]
                      initWithData:inData encoding:[NSString defaultCStringEncoding]];
        
        NSLog(@"%@",returnValue);
    }
    
    return returnValue;
}

@end
