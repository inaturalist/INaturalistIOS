//
//  AddIdentificationViewController.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <UIImageView+WebCache.h>
#import <UIView+WebCache.h>

#import "AddIdentificationViewController.h"
#import "Observation.h"
#import "ImageStore.h"
#import "TaxonPhoto.h"
#import "Analytics.h"
#import "TextViewCell.h"
#import "ObsDetailTaxonCell.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "IdentificationsAPI.h"

@interface AddIdentificationViewController () <RKRequestDelegate, UITextViewDelegate> {
    BOOL viewHasPresented;
}
@property BOOL taxonViaVision;
@property (copy) NSString *comment;

- (IBAction)cancelAction:(id)sender;
- (IBAction)saveAction:(id)sender;
- (IBAction)clickedSpeciesButton:(id)sender;

@end

@implementation AddIdentificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TaxonCell" bundle:nil]
         forCellReuseIdentifier:@"taxonFromNib"];
    [self.tableView registerClass:[TextViewCell class]
           forCellReuseIdentifier:@"textViewCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.taxon) {
        if (viewHasPresented) {
            // user is trying to cancel adding an ID
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self performSegueWithIdentifier:@"IdentificationTaxaSearchSegue" sender:nil];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    viewHasPresented = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"IdentificationTaxaSearchSegue"]) {
        TaxaSearchViewController *vc = (TaxaSearchViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
        vc.observationToClassify = self.observation;
    }
}

- (IBAction)cancelAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveAction:(id)sender {
    
    BOOL inputValidated = YES;
    NSString *alertMsg = nil;
    
    if (!self.observation || ![self.observation inatRecordId]) {
        inputValidated = NO;
        alertMsg = NSLocalizedString(@"Unable to add an identification to this observation. Please try again later.",
                                     @"Failure message when making an identification");
    } else if (!self.taxon) {
        inputValidated = NO;
        alertMsg = NSLocalizedString(@"Unable to identify this observation to that species. Please try again later.",
                                     @"Failure message when making an identification");
    }
    
    if (!inputValidated) {
        NSString *alertTitle = NSLocalizedString(@"Identification Failed", @"Title of identification failure alert");
        if (!alertMsg) {
            alertMsg = NSLocalizedString(@"Unknown error while making an identification.", @"Unknown error");
        }
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:alertMsg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    IdentificationsAPI *api = [[IdentificationsAPI alloc] init];
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    __weak typeof(self) weakSelf = self;
    
    [api addIdentificationTaxonId:weakSelf.taxon.taxonId
                    observationId:weakSelf.observation.inatRecordId
                             body:weakSelf.comment ?: nil
                           vision:self.taxonViaVision
                          handler:^(NSArray *results, NSInteger count, NSError *error) {
                              [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
                              
                              if (error) {
                                  UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                                                                                                 message:error.localizedDescription
                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                                  [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                            style:UIAlertActionStyleCancel
                                                                          handler:nil]];
                                  [weakSelf presentViewController:alert animated:YES completion:nil];
                              } else {
                                  [self.navigationController popViewControllerAnimated:YES];
                              }
                          }];
}

- (IBAction)clickedSpeciesButton:(id)sender {
    if (self.taxon) {
        self.taxon = nil;
        [self.tableView reloadData];
    } else {
        [self performSegueWithIdentifier:@"IdentificationTaxaSearchSegue" sender:nil];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    self.comment = textView.text;
}


#pragma mark - UITableViewDataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"Identification Taxon", @"Title for taxon section when adding an ID");
    } else {
        return NSLocalizedString(@"Tell Us Why", @"Title for description/comment when adding an ID");
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        ObsDetailTaxonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taxonFromNib"];
        if (self.taxon) {
            if (self.taxon.photoUrl) {
                [cell.taxonImageView sd_setImageWithURL:self.taxon.photoUrl];
            } else {
                [cell.taxonImageView setImage:[[ImageStore sharedImageStore] iconicTaxonImageForName:self.taxon.iconicTaxonName]];
            }
            cell.taxonNameLabel.text = self.taxon.commonName;
            cell.taxonSecondaryNameLabel.text = self.taxon.scientificName;
        } else {
            [cell.taxonImageView setImage:[[ImageStore sharedImageStore] iconicTaxonImageForName:@"unknown"]];
            cell.taxonNameLabel.text = NSLocalizedString(@"Unknown", nil);
            cell.taxonSecondaryNameLabel.text = nil;
        }
        return cell;
    } else {
        TextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"textViewCell"];
        cell.textView.text = self.comment;
        cell.textView.delegate = self;
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 55;
    } else {
        return 105;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // begin taxon search (again, presumably)
        [self performSegueWithIdentifier:@"IdentificationTaxaSearchSegue" sender:nil];
    }
}

#pragma mark - TaxaSearchViewControllerDelegate
- (void)taxaSearchViewControllerChoseTaxon:(id <TaxonVisualization>)taxon chosenViaVision:(BOOL)visionFlag
{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.taxon = taxon;
    self.taxonViaVision = visionFlag;
    self.comment = nil;
    [self.tableView reloadData];
}

- (void)taxaSearchViewControllerCancelled {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
