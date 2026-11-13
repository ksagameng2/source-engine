/*
 Launchdialog.m - iOS lauch dialog
 Copyright (C) 2016 mittorn
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 */

#import <Foundation/Foundation.h>
#include <stdlib.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#include <limits.h>
#include <SDL2/SDL_syswm.h>

@interface XashPromptAlertViewDelegate : NSObject <UIAlertViewDelegate>

@property (nonatomic, assign) int *button;

@end

@implementation XashPromptAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	*_button = buttonIndex;
}
@end

int szArgc;
char **szArgv;
char *g_szLibrarySuffix;
float g_iOSVer;
bool isdark;

#define SETTINGS_MAGIC 111

typedef struct settings_s
{
	unsigned char magic;
	char args[1024];
	unsigned int port;
	char suffix[32];
	unsigned int ftpserver;
} settings_t;
@interface ButtonHandler :NSObject
@property (nonatomic, assign) int *button1;
@end
@implementation ButtonHandler

const char *IOS_GetDocsDir(void)
{
	static const char *dir = NULL;
	
	if( dir )
		return dir;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirctory = [paths objectAtIndex:0];
	[[NSFileManager defaultManager] createDirectoryAtPath:documentsDirctory withIntermediateDirectories:YES attributes:nil error:nil];
	
	dir = [documentsDirctory fileSystemRepresentation];
	NSLog(@"IOS_GetDocsDir: %s", dir);
	
	return dir;
}

const char *IOS_GetExecDir(void)
{
	static const char *dir = NULL;
	
	if( dir )
		return dir;

	dir = [[[NSBundle mainBundle] bundleURL] fileSystemRepresentation];
	NSLog(@"IOS_GetExecDir: %s", dir);
	
	return dir;
}

-(void) buttonClicked:(UIButton*)sender
{
	*_button1 = 0;
}
@end
void IOS_PrepareView(void)
{
	ButtonHandler *handler = [[ButtonHandler alloc] init];
	UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	UIViewController *controller = [[UIViewController alloc] init];
	[[controller view] setBackgroundColor:[UIColor grayColor]];
	[window setRootViewController:controller];
	[window makeKeyAndVisible];
	if([[controller traitCollection] userInterfaceStyle] == UIUserInterfaceStyleDark && g_iOSVer >= 13.0) isdark = true; else isdark = false;
#if 0
	UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 100, 20)];
	int button1 = -1;
	handler.button1 = &button1;

	[button addTarget:handler action:@selector(buttonClicked:) forControlEvents:UIControlEventValueChanged];
	@autoreleasepool {
		while( button1 == -1 ) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		}
	}
	[[controller view] addSubview:button];
#endif
}

void IOS_LaunchDialog( void )
{
	NSLog(@"System Version is %@",[[UIDevice currentDevice] systemVersion]);
	NSString *ver = [[UIDevice currentDevice] systemVersion];
	g_iOSVer = [ver floatValue];

	char exec_dir[PATH_MAX];
	strcpy(exec_dir, IOS_GetExecDir());
	setenv("APP_LIB_PATH", exec_dir, 1);
	setenv("APP_MOD_LIB", exec_dir, 1);
	strcat(exec_dir, "/extras_dir.vpk");
	setenv("EXTRAS_VPK_PATH", exec_dir, 1);
	setenv("VALVE_GAME_PATH", IOS_GetDocsDir(), 1);
	setenv("ANGLE_METAL_PRINT_MSL_ENABLE=1", "1", 1);

	//request microphone permissions otherwise we will crash when joining an online server
	//[[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted){}];

	IOS_PrepareView();	
	int button = -1, bExit, bStart;
	UIAlertView * alert = [[UIAlertView alloc] init];
	bExit = [alert addButtonWithTitle:@"Exit"];
	bStart = [alert addButtonWithTitle:@"Start"];
	XashPromptAlertViewDelegate *delegate = [[XashPromptAlertViewDelegate alloc] init];
	delegate.button = &button;
	
	alert.delegate = delegate;

	const char *docsDir = IOS_GetDocsDir();

	//set working directory to documents so logs can be generated there
	NSString *workingDir = [NSString stringWithUTF8String:docsDir];
	[[NSFileManager defaultManager] changeCurrentDirectoryPath:workingDir];
	
	FILE *settingsfile;
	char settingspath[256];
	snprintf(settingspath, sizeof(settingspath), "%s/settings.bin", docsDir );
	settingspath[255] = 0;
	settings_t settings;

	[alert setTransform:CGAffineTransformMakeTranslation(0,109)];

	UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];

	UILabel *argstitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 30)];
	[argstitle setText:@"Command-line arguments:"];

	UITextField *args = [[UITextField alloc] initWithFrame:CGRectMake(0, 30, 300, 30)];
	[args setBackgroundColor:[[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:1]];
	if(isdark) [args setBackgroundColor:[[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:1]];
	
	UITextField *suffix = [[UITextField alloc] initWithFrame:CGRectMake(140, 90, 160, 30 )];
	[suffix setBackgroundColor:[[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:1]];
	if(isdark) [suffix setBackgroundColor:[[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:1]];

	UILabel *suffixtitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 90, 140, 30)];
	[suffixtitle setText:@"Library suffix"];

	[scroll addSubview:argstitle];
	[scroll addSubview:args];
	[scroll addSubview:suffix];
	[scroll addSubview:suffixtitle];

	settingsfile = fopen( settingspath, "rb" );
	if( settingsfile && ( fread(&settings, sizeof( settings ), 1, settingsfile ) == 1 ) && ( settings.magic == SETTINGS_MAGIC ) )
	{
		settings.args[1023] = 0;
		settings.suffix[31] = 0;
		[args setText:@(settings.args)];
		[suffix setText:@(settings.suffix)];
	}
	else
	{
		[args setText:@"-nouserclip"];
	}

	scroll.contentSize=CGSizeMake(250, 200);
	[alert setValue:scroll forKey:@"accessoryView"];

	[alert show];

	@autoreleasepool {
		while( button == -1 ) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		}
	}

	if( (settingsfile = fopen( settingspath, "wb" )) )
	{
		strlcpy(settings.args, [args.text UTF8String], 1024);
		strlcpy(settings.suffix, [suffix.text UTF8String], 32 );
		settings.magic = 111;
	
		fwrite(&settings, sizeof(settings), 1, settingsfile);
		fclose(settingsfile);
	}
	if( button == bExit )
	{
		printf("Exit selected\n");
		exit(0);
	}

	NSArray *argv = [ args.text componentsSeparatedByString:@" " ];
	
	int count = [argv count];
	szArgv = calloc( count + 2, sizeof( char* ) );
	if (szArgv == NULL) {
		NSLog(@"%s", strerror(errno));
    	return; 
	}
	int i;
	for( i = 0; i<count; i++ )
	{
		szArgv[i + 1] = strdup( [argv[i] UTF8String] );
	}
	szArgc = count + 1;
	szArgv[count + 1] = 0;
	szArgv[0] = exec_dir;

	alert.delegate = nil;

	[args release];
	[argstitle release];
	[suffix release];
	[suffixtitle release];

	[alert release];
}

int IOS_GetArgs( char ***out )
{
	if(szArgv != NULL)
	{
		*out = szArgv;
		return szArgc;
	}
}