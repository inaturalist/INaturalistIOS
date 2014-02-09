//
//  ObservationActivityViewController.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ObservationActivityViewController.h"
#import "Observation.h"
#import "Comment.h"
#import "Identification.h"
#import "RefreshControl.h"
#import "User.h"
#import "Taxon.h"
#import "AddCommentViewController.h"
#import "AddIdentificationViewController.h"
#import "DejalActivityView.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"
#import "PhotoViewController.h"
#import "PhotoSource.h"
#import "TaxonPhoto.h"

static const int CommentCellImageTag = 1;
static const int CommentCellBodyTag = 2;
static const int CommentCellBylineTag = 3;
static const int IdentificationCellImageTag = 4;
static const int IdentificationCellTaxonImageTag = 5;
static const int IdentificationCellTitleTag = 6;
static const int IdentificationCellTaxonNameTag = 7;
static const int IdentificationCellBylineTag = 8;
static const int IdentificationCellAgreeTag = 9;
static const int IdentificationCellTaxonScientificNameTag = 10;
static const int IdentificationCellBodyTag = 11;

@interface ObservationActivityViewController () <RKObjectLoaderDelegate, RKRequestDelegate>

@property (strong, nonatomic) UIBarButtonItem *addCommentButton;
@property (strong, nonatomic) UIBarButtonItem *addIdentificationButton;
@property (strong, nonatomic) NSArray *comments;
@property (strong, nonatomic) NSArray *identifications;
@property (strong, nonatomic) NSArray *activities;
@property (strong, nonatomic) NSMutableArray *rowHeights;

- (void)initUI;
- (void)clickedAddComment;
- (void)clickedAddIdentification;
- (IBAction)clickedCancel:(id)sender;
- (IBAction)clickedAgree:(id)sender;

@end

@implementation ObservationActivityViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNSManagedObjectContextDidSaveNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:[Observation managedObjectContext]];
	
	RefreshControl *refresh = [[RefreshControl alloc] init];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	[refresh addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
	self.refreshControl = refresh;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self refreshData];
	[self markAsRead];
	[self reload];
	[DejalBezelActivityView activityViewForView:self.view withLabel:NSLocalizedString(@"Refreshing...",nil)];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    [self initUI];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)initUI
{
    UIBarButtonItem *flex = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                             target:nil
                             action:nil];
    if (!self.addCommentButton) {
        self.addCommentButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Comment",nil)
																 style:UIBarButtonItemStyleDone
																target:self
																action:@selector(clickedAddComment)];
        [self.addCommentButton setWidth:120.0];
        [self.addCommentButton setTintColor:[UIColor colorWithRed:168.0/255
															green:204.0/255
															 blue:50.0/255
															alpha:1.0]];
    }
    
    if (!self.addIdentificationButton) {
        self.addIdentificationButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add ID",nil)
																		style:UIBarButtonItemStyleDone
																	   target:self
																	   action:@selector(clickedAddIdentification)];
        [self.addIdentificationButton setWidth:120.0];
        [self.addIdentificationButton setTintColor:[UIColor colorWithRed:168.0/255
																   green:204.0/255
																	blue:50.0/255
																   alpha:1.0]];
    }
    
    [self setToolbarItems:[NSArray arrayWithObjects:
                           flex,
						   self.addCommentButton,
                           flex,
                           self.addIdentificationButton,
                           flex,
                           nil]
                 animated:NO];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)loadData
{
	self.comments = self.observation.comments.allObjects;
	self.identifications = self.observation.identifications.allObjects;
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
	NSArray *allActivities = [self.comments arrayByAddingObjectsFromArray:self.identifications];
	self.activities = [allActivities sortedArrayUsingDescriptors:@[sortDescriptor]];
	
	self.rowHeights = [NSMutableArray arrayWithCapacity:self.activities.count];
	for (int x = 0; x < self.activities.count; x++) {
		[self.rowHeights addObject:[NSNull null]];
	}
}

- (void)reload
{
    [self loadData];
    [[self tableView] reloadData];
}

- (void)handleNSManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    if (self.view && ![[UIApplication sharedApplication] isIdleTimerDisabled]) {
        [self reload];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"AddCommentSegue"]){
		AddCommentViewController *vc = segue.destinationViewController;
		vc.observation = self.observation;
	} else if ([segue.identifier isEqualToString:@"AddIdentificationSegue"]){
		AddIdentificationViewController *vc = segue.destinationViewController;
		vc.observation = self.observation;
	}
}

#pragma mark - Actions
- (void)clickedAddComment
{
	[self performSegueWithIdentifier:@"AddCommentSegue" sender:self];
}

- (void)clickedAddIdentification
{
	[self performSegueWithIdentifier:@"AddIdentificationSegue" sender:self];
}

- (void)clickedCancel:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)clickedAgree:(UIButton *)sender
{
	UIView *contentView = sender.superview;
	CGPoint center = [self.tableView convertPoint:sender.center fromView:contentView];
    NSIndexPath *indexPath = [[self tableView] indexPathForRowAtPoint:center];
	Identification *identification = (Identification *)self.activities[indexPath.row];
	[self agreeWithIdentification:identification];
}

- (void)agreeWithIdentification:(Identification *)identification
{
	[DejalBezelActivityView activityViewForView:self.view withLabel:NSLocalizedString(@"Agreeing...",nil)];
	NSDictionary *params = @{
							 @"identification[observation_id]":self.observation.recordID,
							 @"identification[taxon_id]":identification.taxonID
							 };
	[[RKClient sharedClient] post:@"/identifications" params:params delegate:self];
}

#pragma mark - API

- (void)markAsRead
{
	if (self.observation.recordID && self.observation.hasUnviewedActivity.boolValue) {
		[[RKClient sharedClient] put:[NSString stringWithFormat:@"/observations/%@/viewed_updates", self.observation.recordID] params:nil delegate:self];
		self.observation.hasUnviewedActivity = @NO;
		NSError *error = nil;
		[[[RKObjectManager sharedManager] objectStore] save:&error];
	}
}

- (void)refreshData
{
	if (self.observation.recordID) {
		[[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/observations/%@", self.observation.recordID]
													 objectMapping:[Observation mapping]
														  delegate:self];
	}
}

#pragma mark - RKRequestDelegate
- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
	NSLog(@"Did load response status code: %d for URL: %@", response.statusCode, response.URL);
	if ([response.URL.absoluteString rangeOfString:@"/identifications"].location != NSNotFound && response.statusCode == 200) {
		[self refreshData];
	} else {
		[DejalBezelActivityView removeView];
	}
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
	NSLog(@"Did fail with error: %@ for URL: %@", error.localizedDescription, request.URL);
}

#pragma mark - RKObjectLoaderDelegate

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
	[self.refreshControl endRefreshing];
	[DejalBezelActivityView removeView];
	
    if (objects.count == 0) return;
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
		
		/*
        [o setSyncedAt:now];
		
		
		if ([o isKindOfClass:[Observation class]]) {
			Observation *observation = (Observation *)o;
			
			// if there are pending local changes, don't override the sync timestamp
			if (!observation.needsSync) {
				[o setSyncedAt:now];
			}
						
			// mark any photos as being synced as well...
			NSArray *photos = [observation.observationPhotos allObjects];
			for (ObservationPhoto *photo in photos) {
				photo.syncedAt = now;
			}
		} else {
			[o setSyncedAt:now];
		}
		*/
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {

	[self.refreshControl endRefreshing];
	
    NSString *errorMsg;
    bool jsonParsingError = false, authFailure = false;
    switch (objectLoader.response.statusCode) {
            // UNPROCESSABLE ENTITY
        case 422:
            errorMsg = NSLocalizedString(@"Unprocessable entity",nil);
            break;
            
        default:
            // KLUDGE!! RestKit doesn't seem to handle failed auth very well
            jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
            authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
            errorMsg = error.localizedDescription;
    }
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                 message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                       otherButtonTitles:nil];
    [av show];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.activities.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.rowHeights[indexPath.row] == [NSNull null]) {
		INatModel *activity = self.activities[indexPath.row];
		
		NSString *body;
		float margin;
		if ([activity isKindOfClass:[Identification class]]) {
			body = ((Identification *)activity).body;
			margin = 88;
		} else {
			body = ((Comment *)activity).body;
			margin = 33;
		}
		
		if (body.length == 0) {
			self.rowHeights[indexPath.row] = @(80);
			return 80;
		} else {
			CGSize size = [body sizeWithFont:[UIFont systemFontOfSize:13.0] constrainedToSize:CGSizeMake(252.0, 10000.0) lineBreakMode:NSLineBreakByWordWrapping];
			float height = MAX(80, size.height + margin);
			self.rowHeights[indexPath.row] = [NSNumber numberWithFloat:height];
			return height;
		}
	} else {
		NSNumber *height = self.rowHeights[indexPath.row];
		return height.floatValue;
	}
	return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CommentCellIdentifier = @"CommentCell";
	static NSString *IdentificationCellIdentifier = @"IdentificationCell";

	INatModel *activity = self.activities[indexPath.row];
		
	UITableViewCell *cell;
	if ([activity isKindOfClass:[Comment class]]) {
		cell = [tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier forIndexPath:indexPath];
		TTImageView *imageView = (TTImageView *)[cell viewWithTag:CommentCellImageTag];
		UILabel *body = (UILabel *)[cell viewWithTag:CommentCellBodyTag];
		UILabel *byline = (UILabel *)[cell viewWithTag:CommentCellBylineTag];
		
		Comment *comment = (Comment *)activity;
		
		[imageView unsetImage];
		imageView.defaultImage = [UIImage imageNamed:@"thumb.png"];
		imageView.urlPath = comment.user.userIconURL;
	
		body.text = comment.body;
		byline.text = [NSString stringWithFormat:@"posted by %@ on %@", comment.user.login, comment.createdAtShortString];

	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:IdentificationCellIdentifier forIndexPath:indexPath];
		
		TTImageView *imageView = (TTImageView *)[cell viewWithTag:IdentificationCellImageTag];
		TTImageView *taxonImageView = (TTImageView *)[cell viewWithTag:IdentificationCellTaxonImageTag];
		UILabel *title = (UILabel *)[cell viewWithTag:IdentificationCellTitleTag];
		UILabel *taxonName = (UILabel *)[cell viewWithTag:IdentificationCellTaxonNameTag];
		UILabel *taxonScientificName = (UILabel *)[cell viewWithTag:IdentificationCellTaxonScientificNameTag];
		UILabel *byline = (UILabel *)[cell viewWithTag:IdentificationCellBylineTag];
		UIButton *agreeButton = (UIButton *)[cell viewWithTag:IdentificationCellAgreeTag];
		UILabel *body = (UILabel *)[cell viewWithTag:IdentificationCellBodyTag];
		
		Identification *identification = (Identification *)activity;
		
		[imageView unsetImage];
		imageView.defaultImage = [UIImage imageNamed:@"thumb.png"];
		imageView.urlPath = identification.user.userIconURL;
		
		[taxonImageView unsetImage];
		taxonImageView.defaultImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.observation.iconicTaxonName];
		if (identification.taxon) {
			if (identification.taxon.taxonPhotos.count > 0) {
				TaxonPhoto *tp = (TaxonPhoto *)identification.taxon.taxonPhotos.firstObject;
				taxonImageView.urlPath = tp.squareURL;
			}
		}
		
		title.text = [NSString stringWithFormat:@"%@'s ID", identification.user.login];
		taxonName.text = identification.taxon.name;
		taxonScientificName.text = identification.taxon.name;
		body.text = identification.body;
		byline.text = [NSString stringWithFormat:@"posted by %@ on %@", identification.user.login, identification.createdAtShortString];
		
		NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey];
		if ([username isEqualToString:identification.user.login]) {
			//agreeButton.hidden = YES;
		} else {
			agreeButton.hidden = NO;
		}
	}
	
    return cell;
}

@end
