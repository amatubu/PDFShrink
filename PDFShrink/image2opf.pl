#!/usr/bin/perl

#  image2opf.pl
#  PDFShrink
#
#  Created by naoki iimura on 1/13/13.
#  Copyright (c) 2013 naoki iimura. All rights reserved.

use strict;
use warnings;
use utf8;

# 標準出力のエンコードを調整する

if ( $^O eq "MSWin32" ) {
    binmode STDOUT, ":encoding(cp932)";
} else {
    binmode STDOUT, ":utf8";
}

printf STDOUT "ARGV[] : %s\n", join ",", @ARGV;

my $title = $ARGV[0] || "テスト書名";
my $author = $ARGV[1] || "テスト著者";
my $id = 123;
my $language = "ja";

my $page_direction = $ARGV[2] || "rtl";
my $outfile_name = "book";

# print "書名:", $title, "\n";
# print "著者名:", $author, "\n";

# ファイル一覧

my @image_files = <*.jpg>;
my @basenames = map { $_ =~ m{(.+)[.]}; $1 } @image_files;

# print join "\n", @basenames;

# HTML ファイル生成
# 同時に最初のファイル名を取得（これをカバーにする）

my $cover;

for my $image ( @basenames ) {
#    print $image, "\n";

    # カバーが未定義ならカバー設定

    if ( !defined($cover) ) {
        $cover = $image;
    }

    my $html_file_name = "$image.html";

    my $page_html = <<HTML_EOL;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8" />
    <link rel="stylesheet" type="text/css" href="style.css" />
    <title>$image</title>
  </head>
  <body>
    <img src="$image.jpg" alt="$image" class="content" />
  </body>
</html>
HTML_EOL

    open my $html_file, '>:utf8', $html_file_name;
    print $html_file $page_html;
    close $html_file;
}

# OPF ファイルの生成

# OPF ファイルの中身

my $opf_content = <<OPF_EOL;
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:title>$title</dc:title>
    <dc:creator>$author</dc:creator>
    <dc:language>$language</dc:language>
    <dc:identifier id="BookId">$id</dc:identifier>
    <meta name="book-type" content="comic"/>
    <meta name="fixed-layout" content="true"/>
    <meta name="cover" content="$cover.jpg"/>
  </metadata>
  <manifest>
OPF_EOL

# マニフェスト

for my $image ( @basenames ) {

#    <item id="00000000" href="00000000.html" media-type="application/xhtml+xml"/>
#    <item id="00000000.jpg" href="00000000.jpg" media-type="image/jpeg"/>

    $opf_content .= <<OPF_EOL2;
    <item id="$image" href="$image.html" media-type="application/xhtml+xml"/>
    <item id="$image.jpg" href="$image.jpg" media-type="image/jpeg"/>
OPF_EOL2

}

$opf_content .= "  </manifest>\n";

# 読み込みの順番

$opf_content .= "  <spine page-progression-direction=\"$page_direction\">\n";

for my $image ( @basenames ) {

#    <itemref idref="00000000" />

    $opf_content .= <<OPF_EOL3;
    <itemref idref="$image" />
OPF_EOL3

}

$opf_content .= "  </spine>\n";
$opf_content .= "</package>\n";

# OPF ファイル出力

open my $opf_file, '>:utf8', "$outfile_name.opf";
print $opf_file $opf_content;
close $opf_file;

# CSS ファイル出力

my $css_content = <<CSS_EOL;
body { 
  text-align: center;
  margin: 0px;
  padding: 0px;
}

img.content{
  height: 100%;
}
CSS_EOL

open my $css_file, '>', "style.css";
print $css_file $css_content;
close $css_file;

exit 0;

1;
