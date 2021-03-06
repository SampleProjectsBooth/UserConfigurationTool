//
//  AESCrypt.h
//  Gurpartap Singh
//
//  Created by Gurpartap Singh on 06/05/12.
//  Copyright (c) 2012 Gurpartap Singh
// 
// 	MIT License
// 
// 	Permission is hereby granted, free of charge, to any person obtaining
// 	a copy of this software and associated documentation files (the
// 	"Software"), to deal in the Software without restriction, including
// 	without limitation the rights to use, copy, modify, merge, publish,
// 	distribute, sublicense, and/or sell copies of the Software, and to
// 	permit persons to whom the Software is furnished to do so, subject to
// 	the following conditions:
// 
// 	The above copyright notice and this permission notice shall be
// 	included in all copies or substantial portions of the Software.
// 
// 	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// 	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// 	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// 	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// 	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// 	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// 	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Cocoa/Cocoa.h>

//! Project version number for AESCrypt.
FOUNDATION_EXPORT double AESCryptVersionNumber;

//! Project version string for AESCrypt.
FOUNDATION_EXPORT const unsigned char AESCryptVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <AESCrypt/PublicHeader.h>

#import <Foundation/Foundation.h>
#import<CommonCrypto/CommonCryptor.h>

//预定义函数结构体，方便外部调用，具体在m文件实现，防止注入、hook攻击
typedef struct _aes_crypt{
    NSData *(*encrypt)(NSData *data);
    NSData *(*decrypt)(NSData *data);
    
    NSData *(*encryptDataAndKey)(NSData *data, NSString *key);
    NSData *(*decryptDataAndKey)(NSData *data, NSString *key);
}_aes_crypt;

@interface AESCrypt : NSObject

+ (_aes_crypt *)encrypt;
+ (void)free;

@end
