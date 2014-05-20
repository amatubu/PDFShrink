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
        
        // PDF からタイトルと著者を得る
        NSDictionary *attributes = [pdfDoc documentAttributes];
        pdfTitle = [attributes objectForKey:PDFDocumentTitleAttribute];
        pdfAuthor = [attributes objectForKey:PDFDocumentAuthorAttribute];
        pdfPageDirection = 1; // Right to Left

        // タイトルや著者が得られなかった場合は、ファイル名からの取得を試みる
        if ( pdfTitle == nil || pdfAuthor == nil ) {
            NSError *error;
            NSRegularExpression *regexp =
            [NSRegularExpression regularExpressionWithPattern:@"(.+?)( - (\\(著\\))?(.+?))?( - (.+))?\\.pdf"
                                                      options:0
                                                        error:&error];
            if (error != nil) {
                NSLog(@"%@", error);
            } else {
                NSString *name = [[[self fileURL] path] lastPathComponent];
                
                NSTextCheckingResult *match =
                [regexp firstMatchInString:name options:0 range:NSMakeRange(0, name.length)];
                NSLog(@"%ld", match.numberOfRanges);
                if ( match.numberOfRanges >= 4 ) {
                    NSRange range1 = [match rangeAtIndex:1];
                    NSRange range4 = [match rangeAtIndex:4];
                    NSLog(@"%@", [name substringWithRange:[match rangeAtIndex:0]]); // マッチした文字列全部
                    if ( range1.length > 0 )
                        NSLog(@"%@", [name substringWithRange:[match rangeAtIndex:1]]); // "書名"
                    if ( range4.length > 4 )
                        NSLog(@"%@", [name substringWithRange:[match rangeAtIndex:4]]); // "著者名"
                    if ( pdfTitle == nil && range1.length > 0 ) {
                        pdfTitle = [name substringWithRange:[match rangeAtIndex:1]];
                    }
                    if ( pdfAuthor == nil && range4.length > 0 ) {
                        pdfAuthor = [name substringWithRange:[match rangeAtIndex:4]];
                    }
                }
            }
        }
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

// PDFの画像を縮小してmobi形式で保存する
- (IBAction)exportToMobi:(id)sender {
    // フロントウィンドウ
    NSWindow *myWindow = [[[self windowControllers] objectAtIndex: 0] window];
    
    // kindlegen のパス
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *kindlegenPath = [defaults objectForKey:@"kindlegenPath"];
    
    // kindlegen の存在を確認
    NSFileManager *manager = [NSFileManager defaultManager];
    if ( ![manager fileExistsAtPath:kindlegenPath] || ![manager isExecutableFileAtPath:kindlegenPath] ) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString( @"error_kindlegen_not_found",
                                                                          @"Error message that KindleGen not found."),
                                                       kindlegenPath];
        [self displayAlert:message forWindow:myWindow];
        return;
    }

    // ファイル名
    NSString *name = [[self fileURL] path];
    
    // 新しいファイル名の候補
    NSString *newPath = [name stringByDeletingLastPathComponent];
    NSString *newName = [name lastPathComponent];
    newName = [newName
               stringByReplacingOccurrencesOfString: @".pdf"
               withString: @".mobi"
               options: NSCaseInsensitiveSearch
               range: NSMakeRange(0, [newName length] )
               ];
    
    // 保存ダイアログの表示
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    // デフォルトのファイル名とパス
    [panel setNameFieldStringValue: newName];
    [panel setDirectoryURL: [NSURL fileURLWithPath: newPath]];
    
    // カスタムビューを追加
    [panel setAccessoryView:_exportToMobiAccessoryView];
    if (pdfTitle != nil) [_pdfTitle setStringValue:pdfTitle];
    if (pdfAuthor != nil) [_pdfAuthor setStringValue:pdfAuthor];
    [_pdfPageDirection selectCellAtRow:pdfPageDirection column:0];
    
    // 保存ダイアログの処理
    [panel beginSheetModalForWindow: myWindow
                  completionHandler:^(NSInteger result) {
                      if ( result == NSFileHandlingPanelOKButton ) {
                          // ファイル名を得る
                          NSURL *file = [panel URL];
                          NSString *newFile = [file path];
                          
                          // その他の設定を得る
                          pdfTitle = [_pdfTitle stringValue];
                          pdfAuthor = [_pdfAuthor stringValue];
                          pdfPageDirection = [_pdfPageDirection selectedRow];
                          
                          [panel close];
                          
                          NSDictionary *arg = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [_pdfView document], @"pdfDoc",
                                               newFile, @"outFile",
                                               myWindow, @"frontWindow",
                                               pdfTitle, @"title",
                                               pdfAuthor, @"author",
                                               (pdfPageDirection == 1 ? @"rtl" : @"ltr"), @"pageDirection",
                                               nil];
                          needAbort = FALSE;
                          [NSThread detachNewThreadSelector:@selector(exportToMobiMain:)
                                                   toTarget:self
                                                 withObject:arg];
                      }
                  }];
}

// PDFの画像を縮小してEPUB3の固定フォーマットで保存する
- (IBAction)exportToEPUB3:(id)sender {
    // フロントウィンドウ
    NSWindow *myWindow = [[[self windowControllers] objectAtIndex: 0] window];
    
    // ファイル名
    NSString *name = [[self fileURL] path];
    
    // 新しいファイル名の候補
    NSString *newPath = [name stringByDeletingLastPathComponent];
    NSString *newName = [name lastPathComponent];
    newName = [newName
               stringByReplacingOccurrencesOfString: @".pdf"
               withString: @".epub"
               options: NSCaseInsensitiveSearch
               range: NSMakeRange(0, [newName length] )
               ];
    
    // 保存ダイアログの表示
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    // デフォルトのファイル名とパス
    [panel setNameFieldStringValue: newName];
    [panel setDirectoryURL: [NSURL fileURLWithPath: newPath]];
    
    // カスタムビューを追加
    [panel setAccessoryView:_exportToMobiAccessoryView];
    if (pdfTitle != nil) [_pdfTitle setStringValue:pdfTitle];
    if (pdfAuthor != nil) [_pdfAuthor setStringValue:pdfAuthor];
    [_pdfPageDirection selectCellAtRow:pdfPageDirection column:0];
    
    // 保存ダイアログの処理
    [panel beginSheetModalForWindow: myWindow
                  completionHandler:^(NSInteger result) {
                      if ( result == NSFileHandlingPanelOKButton ) {
                          // ファイル名を得る
                          NSURL *file = [panel URL];
                          NSString *newFile = [file path];
                          
                          // その他の設定を得る
                          pdfTitle = [_pdfTitle stringValue];
                          pdfAuthor = [_pdfAuthor stringValue];
                          pdfPageDirection = [_pdfPageDirection selectedRow];
                          
                          [panel close];
                          
                          NSDictionary *arg = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [_pdfView document], @"pdfDoc",
                                               newFile, @"outFile",
                                               myWindow, @"frontWindow",
                                               pdfTitle, @"title",
                                               pdfAuthor, @"author",
                                               (pdfPageDirection == 1 ? @"rtl" : @"ltr"), @"pageDirection",
                                               nil];
                          needAbort = FALSE;
                          [NSThread detachNewThreadSelector:@selector(exportToEPUB3Main:)
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
    MyImagePreferences prefs;

    [self getImagePreferences:&prefs];
    
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
        NSData *dataJpeg = [self getShrunkJPEGData:pdfDoc atIndex:i imagePreferences:prefs];
        
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
    MyImagePreferences prefs;
    
    [self getImagePreferences:&prefs];
    
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
        NSData *dataJpeg = [self getShrunkJPEGData:pdfDoc atIndex:i imagePreferences:prefs];
        
        // テンポラリディレクトリに保存
        NSString *jpegFile = [tempDir stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"%08ld.jpg", i]];
        BOOL result = [dataJpeg writeToFile:jpegFile atomically:YES];
        if ( !result )
            NSLog( @"Failed to save page %ld to JPEG file '%@'.", i, jpegFile );
        
        // プログレスバーを進める
        [_progressIndicator setDoubleValue: ((double)i) / ((double)pageCount)];
        
        // 中断なら止める
        if ( needAbort ) break;
    }
    
    if ( !needAbort ) {
        // CBZ に変換
        NSString *command = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"CreateCBZ.sh"];
        NSString *outFile = [arg objectForKey:@"outFile"];
        NSArray *params = [NSArray arrayWithObjects:command, outFile, nil];
        
        int status = [self executeUnixCommand:@"/bin/sh" withParams:params workingDir:tempDir];
        NSLog( @"Result of CreateCBZ : %d", status );
        if ( status != 0 ) {
            NSString *message = [NSString stringWithFormat:NSLocalizedString( @"error_failed_to_export_cbz",
                                                                              @"Error message that failed to export CBZ" ),
                                                           outFile, status];
            [self displayAlert:message
                     forWindow:[arg objectForKey: @"frontWindow"]];
        }
    }
    
    // テンポラリディレクトリを削除
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:tempDir
                            error:&error];
    
    // プログレスバーを閉じる
	[NSApp endSheet:_progressPanel];
}

// mobiへのエクスポートメイン
- (void)exportToMobiMain:(NSDictionary *)arg
{
    // 設定を得る
    MyImagePreferences prefs;
    
    [self getImagePreferences:&prefs];
    
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
        NSData *dataJpeg = [self getShrunkJPEGData:pdfDoc atIndex:i imagePreferences:prefs];;
        
        NSString *jpegFile = [tempDir stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"%08ld.jpg", i]];
        BOOL result = [dataJpeg writeToFile:jpegFile atomically:YES];
        if ( !result )
            NSLog( @"Failed to save page %ld to JPEG file '%@'.", i, jpegFile );
        
        // プログレスバーを進める
        [_progressIndicator setDoubleValue: ((double)i) / ((double)pageCount)];
        
        // 中断なら止める
        if ( needAbort ) break;
    }
    
    if ( !needAbort ) {
        // mobi に変換

        // 画像リストからOPF、HTMLファイルを作成
        NSString *script = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"image2opf.pl"];
        NSString *title = [arg objectForKey:@"title"];
        NSString *author = [arg objectForKey:@"author"];
        NSString *pageDirectionString = [arg objectForKey:@"pageDirection"];
        NSArray *params = [NSArray arrayWithObjects:@"-CA", // ARGV に utf8 フラグをつける
                                                    script,
                                                    title,
                                                    author,
                                                    pageDirectionString, nil];
        
        int status = [self executeUnixCommand:@"/usr/bin/perl" withParams:params workingDir:tempDir];
        NSLog( @"Result of images2opf : %d", status );

        if ( status != 0 ) {
            NSString *message = [NSString stringWithFormat:NSLocalizedString( @"error_failed_to_export_mobi",
                                                                              @"Error message that failed to export mobi." ),
                                                           [arg objectForKey:@"outFile"], status];
            [self displayAlert:message forWindow:[arg objectForKey:@"frontWindow"]];
        } else {
            // kindlegen のパス
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *kindlegenPath = [defaults objectForKey:@"kindlegenPath"];
            
            // kindlegen の存在を確認
            NSFileManager *manager = [NSFileManager defaultManager];
            if ( [manager fileExistsAtPath:kindlegenPath] && [manager isExecutableFileAtPath:kindlegenPath] ) {
            
                // kindlegen を用いて mobi を作成
                params = [NSArray arrayWithObjects:@"book.opf", nil];
                status = [self executeUnixCommand:kindlegenPath withParams:params workingDir:tempDir];
                NSLog( @"Result of kindlegen : %d", status );

                if ( status != 0 ) {
                    NSString *message = [NSString stringWithFormat:NSLocalizedString( @"error_failed_to_export_mobi",
                                                                                      @"Error message that failed to export mobi." ),
                                                                   [arg objectForKey:@"outFile"], status];
                    [self displayAlert:message forWindow:[arg objectForKey:@"frontWindow"]];
                } else {
                    // 作成した mobi ファイルを kindlestrip で縮小
                    script = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"kindlestrip.py"];
                    params = [NSArray arrayWithObjects:script,
                                                       @"book.mobi",
                                                       @"book_stripped.mobi", nil];
                    status = [self executeUnixCommand:@"/usr/bin/python" withParams:params workingDir:tempDir];
                    
                    // 作成した mobi ファイルをコピー
                    NSString *mobiFile = [tempDir stringByAppendingPathComponent:
                                          ( status == 0 ? @"book_stripped.mobi" : @"book.mobi" )];
                    NSString *outFile = [arg objectForKey:@"outFile"];
                    NSError *error;

                    // 存在する場合は先に削除する
                    if ( [manager fileExistsAtPath:outFile] ) {
                        [manager removeItemAtPath:outFile error: &error];
                        NSLog( @"%@", error );
                    }
                    
                    // コピー
                    [manager copyItemAtPath:mobiFile toPath:outFile error:&error];
                    NSLog( @"%@", error );
                }
            } else {
                NSString *message = [NSString stringWithFormat:NSLocalizedString( @"error_failed_to_execute_kindlegen",
                                                                                  @"Error message that failed to execute kindlegen." ),
                                                               kindlegenPath];
                [self displayAlert:message forWindow:[arg objectForKey:@"frontWindow"]];
            }
        }
    }
    
    // テンポラリディレクトリを削除
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:tempDir
                            error:&error];
    
    // プログレスバーを閉じる
	[NSApp endSheet:_progressPanel];
}

// EPUB3へのエクスポートメイン
- (void)exportToEPUB3Main:(NSDictionary *)arg
{
    // 設定を得る
    MyImagePreferences prefs;
    
    [self getImagePreferences:&prefs];
    
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
        NSData *dataJpeg = [self getShrunkJPEGData:pdfDoc atIndex:i imagePreferences:prefs];;
        
        NSString *jpegFile = [tempDir stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"%08ld.jpg", i]];
        BOOL result = [dataJpeg writeToFile:jpegFile atomically:YES];
        if ( !result )
            NSLog( @"Failed to save page %ld to JPEG file '%@'.", i, jpegFile );
        
        // プログレスバーを進める
        [_progressIndicator setDoubleValue: ((double)i) / ((double)pageCount)];
        
        // 中断なら止める
        if ( needAbort ) break;
    }
    
    if ( !needAbort ) {
        // mobi に変換
		
        // 画像リストからOPF、HTMLファイルを作成
        NSString *script = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"image2epub3.pl"];
        NSString *title = [arg objectForKey:@"title"];
        NSString *author = [arg objectForKey:@"author"];
        NSString *pageDirectionString = [arg objectForKey:@"pageDirection"];
        NSArray *params = [NSArray arrayWithObjects:@"-CA", // ARGV に utf8 フラグをつける
						   script,
						   title,
						   author,
						   pageDirectionString, nil];
        
        int status = [self executeUnixCommand:@"/usr/bin/perl" withParams:params workingDir:tempDir];
        NSLog( @"Result of images2epub3 : %d", status );
		
        if ( status != 0 ) {
            NSString *message = [NSString stringWithFormat:NSLocalizedString( @"error_failed_to_export_epub3",
																			 @"Error message that failed to export epub3." ),
								 [arg objectForKey:@"outFile"], status];
            [self displayAlert:message forWindow:[arg objectForKey:@"frontWindow"]];
        } else {
			// zip で圧縮する
			NSString *command = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"CreateEPUB3.sh"];
			NSString *outFile = [arg objectForKey:@"outFile"];
			NSArray *params = [NSArray arrayWithObjects:command, outFile, nil];
			
			int status = [self executeUnixCommand:@"/bin/sh" withParams:params workingDir:tempDir];
			NSLog( @"Result of CreateEPUB3 : %d", status );
			if ( status != 0 ) {
				NSString *message = [NSString stringWithFormat:NSLocalizedString( @"error_failed_to_export_epub3",
																				 @"Error message that failed to export epub3" ),
									 outFile, status];
				[self displayAlert:message
						 forWindow:[arg objectForKey: @"frontWindow"]];
			}
        }
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

// 画像の設定を得る
- (void)getImagePreferences:(MyImagePreferences *)prefs
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger quality;
    
    prefs->maxWidth = [defaults integerForKey:@"maxWidth"];
    prefs->maxHeight = [defaults integerForKey:@"maxHeight"];
    quality = [defaults integerForKey:@"jpegQuality"];
    
    prefs->brightness = [defaults floatForKey:@"brightness"];
    prefs->contrast = [defaults floatForKey:@"contrast"];
    
    if ( prefs->maxWidth <= 0 ) {
        prefs->maxWidth = 658;
        [defaults setInteger:prefs->maxWidth forKey:@"maxWidth"];
    }
    if ( prefs->maxHeight <= 0 ) {
        prefs->maxHeight = 905;
        [defaults setInteger:prefs->maxHeight forKey:@"maxHeight"];
    }
    if ( quality <= 0 || quality > 100 ) {
        quality = 80;
        [defaults setInteger:quality forKey:@"jpegQuality"];
    }
    prefs->jpegQuality = (float)quality / 100.0f;
    
    prefs->adjustBrightnessContrast = [defaults boolForKey:@"adjustBrightnessContrast"];
    
    if ( prefs->brightness < -1.0 || prefs->brightness > 1.0 ) {
        prefs->brightness = 0.0;
        [defaults setFloat:prefs->brightness forKey:@"brightness"];
    }
    if ( prefs->contrast < 0.25 || prefs->contrast > 4.0 ) {
        prefs->contrast = 1.0;
        [defaults setFloat:prefs->contrast forKey:@"contrast"];
    }

	prefs->useGrayScaleImages = [defaults boolForKey:@"useGrayScaleImages"];
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
- (NSData *)getShrunkJPEGData:(PDFDocument *)pdfDoc atIndex:(NSUInteger)i imagePreferences:(MyImagePreferences)prefs
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
    if ( size.width * prefs.maxHeight > size.height * prefs.maxWidth) {
        // 横長
        if ( size.width > prefs.maxWidth ) {
            size.height = size.height * prefs.maxWidth / size.width;
            size.width = prefs.maxWidth;
        }
    } else {
        // 縦長
        if ( size.height > prefs.maxHeight ) {
            size.width = size.width * prefs.maxHeight / size.height;
            size.height = prefs.maxHeight;
        }
    }
    
    // ビットマップイメージを作成
    NSBitmapImageRep *bitmapRep;
    
    if ( i == 0 || !prefs.useGrayScaleImages ) {
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
    [pdfImageRep drawInRect: NSMakeRect( 0, 0, size.width, size.height )];
    
    // コンテクストを元に戻す
    [NSGraphicsContext restoreGraphicsState];
    
    NSBitmapImageRep *outBitmap;
    if ( prefs.adjustBrightnessContrast ) {
        // 輝度、コントラストを調整する
        CIImage *inCIImage= [[CIImage alloc] initWithBitmapImageRep:bitmapRep];
        
        CIFilter* _colorControlsFilter= [CIFilter filterWithName:@"CIColorControls"];
        [_colorControlsFilter setDefaults];
        [_colorControlsFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputSaturation"];
        [_colorControlsFilter setValue:[NSNumber numberWithFloat:prefs.brightness] forKey:@"inputBrightness"];
        [_colorControlsFilter setValue:[NSNumber numberWithFloat:prefs.contrast] forKey:@"inputContrast"];
        
        [_colorControlsFilter setValue:inCIImage forKey:@"inputImage"];
        CIImage* outCIImage = [_colorControlsFilter valueForKey:@"outputImage"];
        
        outBitmap = [[NSBitmapImageRep alloc] initWithCIImage:outCIImage];
    }
    
    // JPEGの圧縮率を設定
    NSDictionary *propJpeg =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithFloat:prefs.jpegQuality],
     NSImageCompressionFactor,
     nil];
    
    // JPEGデータに変換
    NSData *dataJpeg = [(prefs.adjustBrightnessContrast ? outBitmap : bitmapRep)
                        representationUsingType: NSJPEGFileType properties: propJpeg];
    
    return dataJpeg;
}

// Unixコマンドを実行する
- (int)executeUnixCommand:(NSString *)command withParams:(NSArray *)params workingDir:(NSString *)workingDirectory {
    NSPipe *newPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSData *inData = nil;
    NSString *returnValue = nil;
    
    NSTask *unixTask = [[NSTask alloc] init];
    [unixTask setStandardOutput:newPipe];
    [unixTask setLaunchPath:command];
    [unixTask setArguments:params];
    [unixTask setCurrentDirectoryPath:workingDirectory];
    [unixTask launch];
    [unixTask waitUntilExit];
    int status = [unixTask terminationStatus];
    
    while ((inData = [readHandle availableData]) && [inData length]) {
        
        returnValue= [[NSString alloc]
                      initWithData:inData encoding:[NSString defaultCStringEncoding]];
        
        NSLog(@"%@",returnValue);
    }
    
    return status;
}

// シンプルなアラートを表示する
// 「アラートシートを表示」ボタンのアクション
- (void)displayAlert:(NSString *)message forWindow:(NSWindow *)window
{
	[NSApp endSheet:_progressPanel];
	
    NSAlert *alert = [ NSAlert alertWithMessageText : nil
                                      defaultButton : @"OK"
                                    alternateButton : nil
                                        otherButton : nil
                          informativeTextWithFormat : @"%@", message];
	
    [alert beginSheetModalForWindow:window
                      modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
                        contextInfo:nil];
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    
}

@end
