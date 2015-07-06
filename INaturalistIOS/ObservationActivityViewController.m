//
//  ObservationActivityViewController.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "ObservationActivityViewController.h"
#import "Observation.h"
#import "Comment.h"
#import "Identification.h"
#import "RefreshControl.h"
#import "User.h"
#import "Taxon.h"
#import "AddCommentViewController.h"
#import "AddIdentificationViewController.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"
#import "TaxonPhoto.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"

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

static UIImage *defaultPersonImage;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    defaultPersonImage = ({
        FAKIcon *personIcon = [FAKIonIcons iosPersonOutlineIconWithSize:40];
        [personIcon addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
        [personIcon imageWithSize:CGSizeMake(40, 40)];
    });
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNSManagedObjectContextDidSaveNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:[Observation managedObjectContext]];
	
	RefreshControl *refresh = [[RefreshControl alloc] init];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Pull to Refresh",nil)];
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
    
    self.navigationController.toolbar.barStyle = UIBarStyleDefault;
    self.navigationController.toolbar.barTintColor = [UIColor whiteColor];
    self.navigationController.toolbar.tintColor = [UIColor inatTint];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    [self initUI];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self refreshData];
	[self markAsRead];
	[self reload];
    
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateObservationActivity];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateObservationActivity];
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
        [self.addCommentButton setTintColor:[UIColor inatTint]];
    }
    
    if (!self.addIdentificationButton) {
        self.addIdentificationButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add ID",nil)
																		style:UIBarButtonItemStyleDone
																	   target:self
																	   action:@selector(clickedAddIdentification)];
        [self.addIdentificationButton setWidth:120.0];
        [self.addIdentificationButton setTintColor:[UIColor inatTint]];
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
    if (![self checkForNetworkAndWarn]) {
        return;
    }
	[self performSegueWithIdentifier:@"AddCommentSegue" sender:self];
}

- (void)clickedAddIdentification
{
    if (![self checkForNetworkAndWarn]) {
        return;
    }
	[self performSegueWithIdentifier:@"AddIdentificationSegue" sender:self];
}

- (void)clickedCancel:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)clickedAgree:(UIButton *)sender
{
    if (![self checkForNetworkAndWarn]) {
        return;
    }
	UIView *contentView = sender.superview;
	CGPoint center = [self.tableView convertPoint:sender.center fromView:contentView];
    NSIndexPath *indexPath = [[self tableView] indexPathForRowAtPoint:center];
	Identification *identification = (Identification *)self.activities[indexPath.row];
	[self agreeWithIdentification:identification];
}

- (void)agreeWithIdentification:(Identification *)identification
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Agreeing...",nil)];
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
		self.observation.hasUnviewedActivity = [NSNumber numberWithBool:NO];
		NSError *error = nil;
		[[[RKObjectManager sharedManager] objectStore] save:&error];
	}
}

- (void)refreshData
{
	if (self.observation.recordID
            && [[[RKClient sharedClient] reachabilityObserver] isReachabilityDetermined]
            && [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Refreshing...",nil)];
		[[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/observations/%@", self.observation.recordID]
													 objectMapping:[Observation mapping]
														  delegate:self];
	}
}

#pragma mark - RKRequestDelegate
- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
//	NSLog(@"Did load response status code: %d for URL: %@", response.statusCode, response.URL);
	if ([response.URL.absoluteString rangeOfString:@"/identifications"].location != NSNotFound && response.statusCode == 200) {
		[self refreshData];
	} else {
        [SVProgressHUD dismiss];
	}
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:error.localizedDescription];
	NSLog(@"Did fail with error: %@ for URL: %@", error.localizedDescription, request.URL);
}

#pragma mark - RKObjectLoaderDelegate

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
	[self.refreshControl endRefreshing];
    [SVProgressHUD showSuccessWithStatus:nil];
	
    if (objects.count == 0) return;
    
    NSError *error = nil;
    [self.rowHeights removeAllObjects];
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
    INatModel *activity = self.activities[indexPath.row];
    int defaultHeight = [activity isKindOfClass:[Identification class]] ? 90 : 60;
    
    // be defensive
    @try {
        if (self.rowHeights[indexPath.row] == [NSNull null]) {
            NSString *body;
            float margin = 31.0; // sort of a buffer to capture metadata line height and some uncertainty with text height calc
            if ([activity isKindOfClass:[Identification class]]) {
                body = [((Identification *)activity).body stringByStrippingHTML];
                margin = defaultHeight + 20;
            } else {
                body = [((Comment *)activity).body stringByStrippingHTML];
                margin = 31;
            }
            
            if (body.length == 0) {
                self.rowHeights[indexPath.row] = @(defaultHeight);
                return defaultHeight;
            } else {
                float fontSize;
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    fontSize = 9;
                } else {
                    fontSize = 13;
                }
                CGSize size = [body sizeWithFont:[UIFont systemFontOfSize:fontSize]
                               constrainedToSize:CGSizeMake(252.0, 10000.0)
                                   lineBreakMode:NSLineBreakByWordWrapping];
                float height = MAX(defaultHeight, size.height+margin);
                self.rowHeights[indexPath.row] = [NSNumber numberWithFloat:height];
                return height;
            }
        } else {
            NSNumber *height = self.rowHeights[indexPath.row];
            return height.floatValue;
        }
    } @catch (NSException *exception) {
        if (![exception.name isEqualToString:NSRangeException]) {
            @throw exception;
        }
    }
	return defaultHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CommentCellIdentifier = @"CommentCell";
	static NSString *IdentificationCellIdentifier = @"IdentificationCell";

	INatModel *activity = self.activities[indexPath.row];
		
	UITableViewCell *cell;
	if ([activity isKindOfClass:[Comment class]]) {
		cell = [tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier forIndexPath:indexPath];
		UIImageView *imageView = (UIImageView *)[cell viewWithTag:CommentCellImageTag];
		UILabel *body = (UILabel *)[cell viewWithTag:CommentCellBodyTag];
		UILabel *byline = (UILabel *)[cell viewWithTag:CommentCellBylineTag];
		Comment *comment = (Comment *)activity;
        
        [imageView sd_cancelCurrentImageLoad];
        [imageView sd_setImageWithURL:[NSURL URLWithString:comment.user.userIconURL]
                     placeholderImage:defaultPersonImage];

        body.text = [comment.body stringByStrippingHTML];
		byline.text = [NSString stringWithFormat:@"Posted by %@ on %@", comment.user.login, comment.createdAtShortString];
        
        // Adding auto layout.
        body.textAlignment = NSTextAlignmentNatural;
        body.translatesAutoresizingMaskIntoConstraints = NO;
        byline.textAlignment = NSTextAlignmentNatural;
        byline.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        if(!cell.constraints.count){
            NSDictionary *views = @{@"body":body,@"byline":byline,@"imageView":imageView};
            
            [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7-[imageView(==45)]-[body]-|" options:0 metrics:0 views:views]];
            
            [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7-[imageView(==45)]-[byline]-|" options:0 metrics:0 views:views]];
            
            [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-7-[imageView(==45)]->=0-|" options:NSLayoutFormatAlignAllLeading metrics:0 views:views]];
            [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[body][byline(==21)]-4-|" options:0 metrics:0 views:views]];
        }
        
        
        
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:IdentificationCellIdentifier forIndexPath:indexPath];
		UIImageView *imageView = (UIImageView *)[cell viewWithTag:IdentificationCellImageTag];
		UIImageView *taxonImageView = (UIImageView *)[cell viewWithTag:IdentificationCellTaxonImageTag];
		UILabel *title = (UILabel *)[cell viewWithTag:IdentificationCellTitleTag];
		UILabel *taxonName = (UILabel *)[cell viewWithTag:IdentificationCellTaxonNameTag];
		UILabel *taxonScientificName = (UILabel *)[cell viewWithTag:IdentificationCellTaxonScientificNameTag];
		UILabel *byline = (UILabel *)[cell viewWithTag:IdentificationCellBylineTag];
		UIButton *agreeButton = (UIButton *)[cell viewWithTag:IdentificationCellAgreeTag];
		UILabel *body = (UILabel *)[cell viewWithTag:IdentificationCellBodyTag];
		
		Identification *identification = (Identification *)activity;
		
        [imageView sd_cancelCurrentImageLoad];
        [imageView sd_setImageWithURL:[NSURL URLWithString:identification.user.userIconURL]
                     placeholderImage:defaultPersonImage];
		
        taxonImageView.image = nil;
        [taxonImageView sd_cancelCurrentImageLoad];
		taxonImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.observation.iconicTaxonName];
		if (identification.taxon) {
			if (identification.taxon.taxonPhotos.count > 0) {
                TaxonPhoto *tp = [identification.taxon.sortedTaxonPhotos objectAtIndex:0];
                [taxonImageView sd_setImageWithURL:[NSURL URLWithString:tp.squareURL]
                                  placeholderImage:[[ImageStore sharedImageStore] iconicTaxonImageForName:self.observation.iconicTaxonName]];
			}
		}
        cell.contentView.alpha = identification.current.boolValue ? 1 : 0.5;
		
		title.text = [NSString stringWithFormat:@"%@'s ID", identification.user.login];
		taxonName.text = identification.taxon.defaultName;
        if (taxonName.text.length == 0) {
            taxonName.text = identification.taxon.name;
        }
		taxonScientificName.text = identification.taxon.name;
        body.text = [identification.body stringByStrippingHTML];
		byline.text = [NSString stringWithFormat:@"Posted by %@ on %@", identification.user.login, identification.createdAtShortString];
		
		NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey];
		if ([username isEqualToString:identification.user.login] && identification.isCurrent) {
			agreeButton.hidden = YES;
		} else {
			agreeButton.hidden = NO;
		}
        
        // Adding auto layout.
        if(!cell.constraints.count){
            title.translatesAutoresizingMaskIntoConstraints = NO;
            title.textAlignment = NSTextAlignmentNatural;
            taxonName.translatesAutoresizingMaskIntoConstraints = NO;
            taxonName.textAlignment = NSTextAlignmentNatural;
            taxonScientificName.translatesAutoresizingMaskIntoConstraints = NO;
            taxonScientificName.textAlignment = NSTextAlignmentNatural;
            byline.translatesAutoresizingMaskIntoConstraints = NO;
            byline.textAlignment = NSTextAlignmentNatural;
            body.translatesAutoresizingMaskIntoConstraints = NO;
            body.textAlignment = NSTextAlignmentNatural;
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            taxonImageView.translatesAutoresizingMaskIntoConstraints = NO;
            agreeButton.translatesAutoresizingMaskIntoConstraints = NO;
            
            NSDictionary *views = @{@"title":title,@"taxonName":taxonName,
                                    @"taxonScientificName":taxonScientificName,
                                    @"byline":byline,@"body":body,@"imageView":imageView,
                                    @"agreeButton":agreeButton,@"taxonImageView":taxonImageView};
            
            [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[imageView(==45)]-[taxonImageView(==45)]-[title]->=8-[agreeButton]-|" options:0 metrics:0 views:views]];
            
            [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-9-[imageView(==45)]" options:NSLayoutFormatAlignAllLeading metrics:0 views:views]];
            
            [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-9-[taxonImageView(==45)]" options:0 metrics:0 views:views]];
            
            [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[title(==19)][taxonName(==title)][taxonScientificName(==taxonName)]->=0-[body][byline(==21)]->=0-|" options:0 metrics:0 views:views]];
            
            [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[agreeButton(==34)]" options:NSLayoutFormatAlignAllTrailing metrics:0 views:views]];
            
            [cell addConstraint:[NSLayoutConstraint constraintWithItem:body attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:taxonImageView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
            
            [cell addConstraint:[NSLayoutConstraint constraintWithItem:body attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
            
            [cell addConstraint:[NSLayoutConstraint constraintWithItem:byline attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
            
            [cell addConstraint:[NSLayoutConstraint constraintWithItem:byline attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:taxonImageView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
            
            [cell addConstraint:[NSLayoutConstraint constraintWithItem:taxonName attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:title attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
            
            [cell addConstraint:[NSLayoutConstraint constraintWithItem:taxonScientificName attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:title attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
            
            [cell addConstraint:[NSLayoutConstraint constraintWithItem:taxonName attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:title attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
            
            [cell addConstraint:[NSLayoutConstraint constraintWithItem:taxonScientificName attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:title attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
            
        }
        
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    INatModel *activity = self.activities[indexPath.row];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    if (![activity isKindOfClass:[Identification class]]) {
        return;
    }
    Identification *ident = (Identification *)activity;
    TaxonDetailViewController *tdvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"TaxonDetailViewController"];
    tdvc.taxon = ident.taxon;
    [self.navigationController pushViewController:tdvc animated:YES];
}

- (BOOL)checkForNetworkAndWarn
{
    if ([[[RKClient sharedClient] reachabilityObserver] isReachabilityDetermined]
        && [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return YES;
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You must be connected to the Internet to do this.",nil)
                                                     message:nil
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        return NO;
    }
}

@end
