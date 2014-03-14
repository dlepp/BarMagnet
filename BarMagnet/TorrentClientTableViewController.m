//
//  TorrentClientTableViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 3/02/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import "TorrentClientTableViewController.h"
#import "FileHandler.h"
#import "TorrentDelegate.h"
#import "TorrentJobChecker.h"
#import "AddTorrentClientTableViewController.h"

@interface TorrentClientTableViewController ()
@property (nonatomic, assign) NSUInteger checkedCell;
@property (strong, nonatomic) UISegmentedControl *torrentCellTypeSegmentedControl;
@property (strong, nonatomic) NSArray * cellNames;
@end

@implementation TorrentClientTableViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.checkedCell = -1;
	self.cellNames = @[@"Pretty", @"Compact", @"Fast"];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)selectCurrentClient
{
	for (NSDictionary * dict in [NSUserDefaults.standardUserDefaults objectForKey:@"clients"])
	{
		if ([dict[@"name"] isEqualToString:[FileHandler.sharedInstance settingsValueForKey:@"server_name"]])
		{
			self.checkedCell = [[NSUserDefaults.standardUserDefaults objectForKey:@"clients"] indexOfObject:dict];
			break;
		}
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self selectCurrentClient];
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[NSNotificationCenter.defaultCenter postNotificationName:@"ChangedClient" object:nil];
	[TorrentJobChecker.sharedInstance performSelectorInBackground:@selector(credentialsCheckInvocation) withObject:nil];
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	self.editing = NO;
	[super viewDidDisappear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1)
		return [[NSUserDefaults.standardUserDefaults objectForKey:@"clients"] count];
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	switch (indexPath.section)
	{
		case 0:
			cell = [tableView dequeueReusableCellWithIdentifier:@"styleCell"];
			self.torrentCellTypeSegmentedControl = (UISegmentedControl *)[cell viewWithTag:-(1 << 3)];
			self.torrentCellTypeSegmentedControl.selectedSegmentIndex = [self.cellNames indexOfObject:[FileHandler.sharedInstance settingsValueForKey:@"cell"]];
			break;
		case 1:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:@"clientCell"];
			cell.textLabel.text = [NSUserDefaults.standardUserDefaults objectForKey:@"clients"][indexPath.row][@"name"];
			if (indexPath.row == self.checkedCell)
			{
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			}
			else
			{
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			break;
		}
		case 2:
			cell = [tableView dequeueReusableCellWithIdentifier:@"addCell"];
			break;
	}
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return @"Cell Style";
		case 1:
			return @"Torrent Clients";
		default:
			return nil;
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1)
	{
		[self performSegueWithIdentifier:@"editClient" sender:[NSUserDefaults.standardUserDefaults objectForKey:@"clients"][indexPath.row]];
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
	return indexPath.section == 1;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath.section == 1;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if (proposedDestinationIndexPath.section < 1)
	{
		return [NSIndexPath indexPathForRow:0 inSection:1];
	}
	else if (proposedDestinationIndexPath.section > 1)
	{
		return [NSIndexPath indexPathForRow:[tableView numberOfRowsInSection:1] - 1 inSection:1];
	}
	return proposedDestinationIndexPath;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!indexPath.section)
	{
		return UITableViewCellEditingStyleNone;
	}
	else if (indexPath.section == 2)
	{
		return UITableViewCellEditingStyleInsert;
	}
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1)
	{
		if (self.checkedCell != indexPath.row)
		{
			NSUInteger previouslySelected = self.checkedCell;
			self.checkedCell = indexPath.row;
			if ([self tableView:tableView numberOfRowsInSection:indexPath.section] > previouslySelected)
			{
				[tableView reloadRowsAtIndexPaths:@[indexPath, [NSIndexPath indexPathForRow:previouslySelected inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
				[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			}
			else
			{
				[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
				[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			}
		}
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[FileHandler.sharedInstance setSettingsValue:[NSUserDefaults.standardUserDefaults objectForKey:@"clients"][indexPath.row][@"name"] forKey:@"server_name"];
		[FileHandler.sharedInstance setSettingsValue:[NSUserDefaults.standardUserDefaults objectForKey:@"clients"][indexPath.row][@"type"] forKey:@"server_type"];
		[NSNotificationCenter.defaultCenter postNotificationName:@"ChangedClient" object:nil];
	}
	else
	{
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (IBAction)synchronizeData
{
	[FileHandler.sharedInstance setSettingsValue:self.cellNames[self.torrentCellTypeSegmentedControl.selectedSegmentIndex] forKey:@"cell"];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSMutableArray * array = [[NSUserDefaults.standardUserDefaults objectForKey:@"clients"] mutableCopy];
		[array removeObjectAtIndex:indexPath.row];
		[NSUserDefaults.standardUserDefaults setObject:array forKey:@"clients"];
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert)
	{
		[self performSegueWithIdentifier:@"addClient" sender:nil];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.destinationViewController respondsToSelector:@selector(setClientDictionary:)])
	{
		if ([sender respondsToSelector:@selector(objectForKey:)])
		{
			[segue.destinationViewController setClientDictionary:sender];
		}
	}
}

@end