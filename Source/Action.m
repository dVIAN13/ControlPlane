//
//  Action.m
//  ControlPlane
//
//  Created by David Symonds on 3/04/07.
//

#import "Action.h"
#import "DSLogger.h"
#import "PrefsWindowController.h"
#import "ActionSubmenuItem.h"

@implementation Action

+ (NSString *)typeForClass:(Class)klass
{
	// Hack "Action" off class name (6 chars)
	// TODO: make this a bit more robust?
	NSString *className = NSStringFromClass(klass);
	return [className substringToIndex:([className length] - 6)];
}

+ (Class)classForType:(NSString *)type
{
	NSString *classString = [NSString stringWithFormat:@"%@Action", type];
	Class klass = NSClassFromString(classString);
	if (!klass) {
		NSLog(@"ERROR: No implementation class '%@'!", classString);
		return nil;
	}
	return klass;
}

+ (Action *)actionFromDictionary:(NSDictionary *)dict
{
	NSString *type = [dict valueForKey:@"type"];
	if (!type) {
		NSLog(@"ERROR: Action doesn't have a type!");
		return nil;
	}
	Action *obj = [[[Action classForType:type] alloc] initWithDictionary:dict];
	return [obj autorelease];
}

- (id)init
{
	if ([[self class] isEqualTo:[Action class]]) {
		[NSException raise:@"Abstract Class Exception"
			    format:@"Error, attempting to instantiate Action directly."];
	}

	if (!(self = [super init]))
		return nil;
	
	// Some sensible defaults
	type = [[Action typeForClass:[self class]] retain];
	context = [@"" retain];
	when = [@"Arrival" retain];
	delay = [[NSNumber alloc] initWithDouble:0];
	enabled = [[NSNumber alloc] initWithBool:YES];
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	if ([[self class] isEqualTo:[Action class]]) {
		[NSException raise:@"Abstract Class Exception"
			    format:@"Error, attempting to instantiate Action directly."];
	}

	if (!(self = [super init]))
		return nil;

	type = [[Action typeForClass:[self class]] retain];
	context = [[dict valueForKey:@"context"] copy];
	when = [[dict valueForKey:@"when"] copy];
	delay = [[dict valueForKey:@"delay"] copy];
	enabled = [[dict valueForKey:@"enabled"] copy];

	return self;
}

- (void)dealloc
{
	[type release];
	[context release];
	[when release];
	[delay release];
	[enabled release];

	[super dealloc];
}

- (NSMutableDictionary *)dictionary
{
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[[type copy] autorelease], @"type",
		[[context copy] autorelease], @"context",
		[[when copy] autorelease], @"when",
		[[delay copy] autorelease], @"delay",
		[[enabled copy] autorelease], @"enabled",
		nil];
}

+ (NSString *)helpTextForActionOfType:(NSString *)type
{
	return [[Action classForType:type] helpText];
}

- (NSComparisonResult)compareDelay:(Action *)other
{
	return [[self valueForKey:@"delay"] compare:[other valueForKey:@"delay"]];
}

- (void)notImplemented:(NSString *)methodName
{
	[NSException raise:@"Abstract Class Exception"
		    format:@"Error, -[%@ %@] not implemented.",
			    [self class], methodName];
}

- (NSString *)description
{
	[self notImplemented:@"description"];
	return @"Not implemented!";
}

- (BOOL)execute:(NSString **)errorString
{
	[self notImplemented:@"execute"];
	*errorString = @"Not implemented!";
	return NO;
}

+ (NSString *)helpText
{
	return @"Sorry, no help text written yet!";
}

+ (NSString *)creationHelpText
{
	return @"<Sorry, help text coming soon!>";
}

+ (NSString *)friendlyName {
    return @"Not implemented";
}

+ (BOOL) shouldWaitForScreensaverExit {
    return NO;
}

+ (BOOL) shouldWaitForScreenUnlock {
    return NO;
}

+ (NSString *)menuCategory {
    return @"";
}

- (void)executeAppleScriptForReal:(NSString *)script
{
	appleScriptResult_ = nil;
    
	NSAppleScript *as = [[[NSAppleScript alloc] initWithSource:script] autorelease];
	if (!as) {
		NSLog(@"AppleScript failed to construct! Script was:\n%@", script);
		return;
	}
	NSDictionary *errorDict;
	if (![as compileAndReturnError:&errorDict]) {
		NSLog(@"AppleScript failed to compile! Script was:\n%@\nError dictionary: %@", script, errorDict);
		return;
	}
	appleScriptResult_ = [as executeAndReturnError:&errorDict];
	if (!appleScriptResult_)
		NSLog(@"AppleScript failed to execute! Script was:\n%@\nError dictionary: %@", script, errorDict);
}

- (BOOL)executeAppleScript:(NSString *)script
{
	// NSAppleScript is not thread-safe, so this needs to happen on the main thread. Ick.
	[self performSelectorOnMainThread:@selector(executeAppleScriptForReal:)
                           withObject:script
                        waitUntilDone:YES];
	return (appleScriptResult_ ? YES : NO);
}

- (NSArray *)executeAppleScriptReturningListOfStrings:(NSString *)script
{
	if (![self executeAppleScript:script])
		return nil;
	if ([appleScriptResult_ descriptorType] != typeAEList)
		return nil;
    
	long count = [appleScriptResult_ numberOfItems], i;
	NSMutableArray *list = [NSMutableArray arrayWithCapacity:count];
	for (i = 1; i <= count; ++i) {		// Careful -- AppleScript lists are 1-based
		NSAppleEventDescriptor *elt = [appleScriptResult_ descriptorAtIndex:i];
		if (!elt) {
			NSLog(@"Oops -- couldn't get descriptor at index %ld", i);
			continue;
		}
		NSString *val = [elt stringValue];
		if (!val) {
			NSLog(@"Oops -- couldn't turn descriptor at index %ld into string", i);
			continue;
		}
		[list addObject:val];
	}
    
	return list;
}

@end

#pragma mark -

#import "DefaultBrowserAction.h"
#import "DefaultPrinterAction.h"
#import "DesktopBackgroundAction.h"
#import "DisplayBrightnessAction.h"
#import "DisplaySleepTimeAction.h"
#import "FirewallRuleAction.h"
#import "IChatAction.h"
#import "ITunesPlaylistAction.h"
#import "LockKeychainAction.h"
#import "MailIMAPServerAction.h"
#import "MailSMTPServerAction.h"
#import "MailIntervalAction.h"
#import "MountAction.h"
#import "MuteAction.h"
#import "NetworkLocationAction.h"
#import "OpenAction.h"
#import "OpenURLAction.h"
#import "QuitApplicationAction.h"
#import "ScreenSaverPasswordAction.h"
#import "ScreenSaverStartAction.h"
#import "ScreenSaverTimeAction.h"
#import "ShellScriptAction.h"
#import "SpeakAction.h"
#import "StartTimeMachineAction.h"
#import "TimeMachineDestinationAction.h"
#import "ToggleBluetoothAction.h"
#import "ToggleFileSharingAction.h"
#import "ToggleFirewallAction.h"
#import "ToggleFTPAction.h"
#import "ToggleInternetSharingAction.h"

#ifdef DEBUG_MODE
#import "ToggleNaturalScrollingAction.h"
#endif

#import "TogglePrinterSharingAction.h"
#import "ToggleTFTPAction.h"
#import "ToggleTimeMachineAction.h"
#import "ToggleWiFiAction.h"
#import "UnmountAction.h"
#import "VPNAction.h"


@implementation ActionSetController

- (id)init
{
	if (!(self = [super init]))
		return nil;

    // get system version
	SInt32 major = 0, minor = 0;
	Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    
	classes = [[NSArray alloc] initWithObjects:
			   [DefaultBrowserAction class],
               [DefaultPrinterAction class],
			   [DesktopBackgroundAction class],
			   [DisplayBrightnessAction class],
               [DisplaySleepTimeAction class],
			   [IChatAction class],
			   [ITunesPlaylistAction class],
			   [LockKeychainAction class],
			   [MailIMAPServerAction class],
			   [MailSMTPServerAction class],
			   [MailIntervalAction class],
			   [MountAction class],
			   [MuteAction class],
			   [NetworkLocationAction class],
			   [OpenAction class],
			   [OpenURLAction class],
			   [QuitApplicationAction class],
			   [ScreenSaverPasswordAction class],
			   [ScreenSaverStartAction class],
			   [ScreenSaverTimeAction class],
			   [ShellScriptAction class],
			   [SpeakAction class],
			   [StartTimeMachineAction class],
               [TimeMachineDestinationAction class],
			   [ToggleBluetoothAction class],
               [ToggleFileSharingAction class],
               [ToggleFirewallAction class],
               [ToggleFTPAction class],
               [ToggleInternetSharingAction class],
#ifdef DEBUG_MODE
               [ToggleNaturalScrollingAction class],
#endif
               [TogglePrinterSharingAction class],
               [ToggleTFTPAction class],
               [ToggleTimeMachineAction class],
			   [ToggleWiFiAction class],
			   [UnmountAction class],
			   [VPNAction class],
			nil];
	
	if (NO) {
		// Purely for the benefit of 'genstrings'
		NSLocalizedString(@"DefaultBrowser", @"Action type");
        NSLocalizedString(@"DefaultPrinter", @"Action type");
		NSLocalizedString(@"DesktopBackground", @"Action type");
		NSLocalizedString(@"DisplayBrightness", @"Action type");
		NSLocalizedString(@"iChat", @"Action type");
		NSLocalizedString(@"iTunesPlaylist", @"Action type");
		NSLocalizedString(@"LockKeychain", @"Action type");
		NSLocalizedString(@"MailIMAPServer", @"Action type");
		NSLocalizedString(@"MailSMTPServer", @"Action type");
		NSLocalizedString(@"MailInterval", @"Action type");
		NSLocalizedString(@"Mount", @"Action type");
		NSLocalizedString(@"Mute", @"Action type");
		NSLocalizedString(@"NetworkLocation", @"Action type");
		NSLocalizedString(@"Open", @"Action type");
		NSLocalizedString(@"OpenURL", @"Action type");
		NSLocalizedString(@"QuitApplication", @"Action type");
		NSLocalizedString(@"ScreenSaverPassword", @"Action type");
		NSLocalizedString(@"ScreenSaverStart", @"Action type");
		NSLocalizedString(@"ScreenSaverTime", @"Action type");
		NSLocalizedString(@"ShellScript", @"Action type");
		NSLocalizedString(@"Speak", @"Action type");
		NSLocalizedString(@"StartTimeMachine", @"Action type");
        NSLocalizedString(@"TimeMachineDestination", @"Action type");
		NSLocalizedString(@"ToggleBluetooth", @"Action type");
        NSLocalizedString(@"ToggleFileSharing", @"Action type");
        NSLocalizedString(@"ToggleFirewall", @"Action type");
#ifdef DEBUG_MODE
        NSLocalizedString(@"ToggleInternetSharing", @"Action type");
#endif
        NSLocalizedString(@"ToggleNaturalScrolling", @"Action type");
        NSLocalizedString(@"TimeMachineAction",@"Action type");
		NSLocalizedString(@"ToggleWiFi", @"Action type");
		NSLocalizedString(@"Unmount", @"Action type");
		NSLocalizedString(@"VPN", @"Action type");
	}
    
    // hack to remove the DisplayBrightnessAction on ML
    if (major == 10 && minor > 7) {
        NSMutableArray *tmp = [classes mutableCopy];
        [tmp removeObject:[DisplayBrightnessAction class]];
        classes = tmp;
    }
    
    
    // build a list of menu categories
    NSMutableDictionary *menuCategoryBuilder = [NSMutableDictionary dictionary];
    NSMutableDictionary *tmpDict = nil;
    ActionSubmenuItem *tmp = nil;

    
    for (id currentClass in classes) {
        
        // if the object exists then we've seen this category before
        // and we simply want to add the class to the object we just found
        if ([menuCategoryBuilder objectForKey:[currentClass menuCategory]]) {
            tmp = [menuCategoryBuilder objectForKey:[currentClass menuCategory]];
            tmpDict = [NSMutableDictionary dictionaryWithCapacity:3];
            [tmpDict setObject:currentClass forKey:@"class"];
            [tmpDict setObject:[currentClass class] forKey:@"representedObject"];
            [tmp setTarget:prefsWindowController];
            [tmp addObject:tmpDict];
            
        }
        else {
            tmp = [[ActionSubmenuItem alloc] init];
            tmpDict = [NSMutableDictionary dictionaryWithCapacity:3];
            [tmpDict setObject:currentClass forKey:@"class"];
            [tmpDict setObject:[currentClass class] forKey:@"representedObject"];
            [tmp setTarget:prefsWindowController];
            [tmp addObject:tmpDict];
            
            [menuCategoryBuilder setObject:tmp forKey:[currentClass menuCategory]];
            
            [tmp release];
        }
    }
    
    NSLog(@"looks like %@", menuCategoryBuilder);
    
    menuCategories = [menuCategoryBuilder copy];
	return self;
}

- (void)dealloc
{
	[classes release];
    [menuCategories release];
	[super dealloc];
}

- (NSArray *)types
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[classes count]];
	NSEnumerator *en = [classes objectEnumerator];
	Class klass;
	while ((klass = [en nextObject])) {
		[array addObject:[Action typeForClass:klass]];
	}
	return array;
}

#pragma mark NSMenu delegates

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel
{
	//Class klass = [classes objectAtIndex:index];
    

    NSArray *menuCategoryList = [menuCategories allKeys];
    menuCategoryList = [menuCategoryList sortedArrayUsingSelector:@selector(compare:)];
    
    NSString *friendlyName = [[classes objectAtIndex:index] friendlyName];
    NSString *categoryName = [menuCategoryList objectAtIndex:index];
    //NSString *localisedType = NSLocalizedString(type, @"Action type");
    
    NSMenu *newSubMenu = [[[NSMenu alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ Actions", @""), friendlyName]] retain];
    
    [newSubMenu setDelegate:[menuCategories objectForKey:categoryName]];
    
    
    //NSString *title = [NSString stringWithFormat:NSLocalizedString(@"'%@' Actions...", @"Menu item"),
    //friendlyName];
    //[item setTitle:title];
    
    [item setSubmenu:newSubMenu];
    [item setTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ Actions", @""), categoryName]];
    [item setRepresentedObject:[classes objectAtIndex:index]];
    
    
    

    //DSLog(@"menu category %@", [[classes objectAtIndex:index] menuCategory]);
    

	//[item setTarget:prefsWindowController];
	//[item setAction:@selector(addAction:)];
	//[item setRepresentedObject:klass];

	return YES;
}

- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action
{
	// TODO: support keyboard menu jumping?
	return NO;
}

- (NSUInteger)numberOfItemsInMenu:(NSMenu *)menu
{
    return [menuCategories count];
}

@end
