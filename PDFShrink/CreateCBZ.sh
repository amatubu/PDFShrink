#!/bin/sh

#  CreateCBZ.sh
#  PDFShrink
#
#  Created by naoki iimura on 1/13/13.
#  Copyright (c) 2013 naoki iimura. All rights reserved.

rm -rf "$1"
zip "$1" *.jpg
