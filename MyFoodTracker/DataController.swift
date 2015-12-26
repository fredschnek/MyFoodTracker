//
//  DataController.swift
//  MyFoodTracker
//
//  Created by Frederico Schnekenberg on 15/06/15.
//  Copyright (c) 2015 Frederico Schnekenberg. All rights reserved.
//

import UIKit
import CoreData
import Foundation

// Constant for postNotification
let kUSDAItemCompleted = "USDAItemInstanceComplete"

class DataController {
    
    class func jsonAsUSDAIdAndNameSearchResults(json: NSDictionary) -> [(name: String, idValue: String)] {
        
        // Array of Tuples to hold the data
        var usdaItemsSearchResults: [(name: String, idValue: String)] = []
        
        // Tuple for search result
        var searchResult: (name: String, idValue: String)
        
        // Checks if the returned key value hits has data
        if json["hits"] != nil {
            // Array to store the results of hits key from JSON
            let results: [AnyObject] = json["hits"]! as! [AnyObject]
            // Iterates through results to find our key pair values
            for itemDictionary in results {
                if itemDictionary["_id"] != nil {
                    if itemDictionary["fields"] != nil {
                        // Converts fields data into NSDictionay
                        let fieldsDictionay = itemDictionary["fields"] as! NSDictionary
                        if fieldsDictionay["item_name"] != nil {
                            let idValue: String = itemDictionary["_id"]! as! String
                            let name: String = fieldsDictionay["item_name"]! as! String
                            searchResult = (name: name, idValue: idValue)
                            usdaItemsSearchResults += [searchResult]
                        }
                    }
                }
            }
        }
        return usdaItemsSearchResults
    }
    
    func saveUSDAItemForId(idValue: String, json: NSDictionary) {
        
        if json["hits"] != nil {
            // Array to store hits results
            let results: [AnyObject] = json["hits"]! as! [AnyObject]
            
            for itemDictionaty in results {
                
                if itemDictionaty["_id"] != nil && itemDictionaty["_id"] as! String == idValue {
                    
                    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
                    var requestForUSDAItem = NSFetchRequest(entityName: "USDAItem")
                    var itemDictionaryId = itemDictionaty["_id"]! as! String
                    // Checks if the idValue passed  is igual to the one on hits
                    let predicate = NSPredicate(format: "idValue == %@", itemDictionaryId)
                    requestForUSDAItem.predicate = predicate
                    
                    var error: NSError?
                    
                    // Stores the result from the query
                    var items = managedObjectContext?.executeFetchRequest(requestForUSDAItem, error: &error)
                    
                    if items?.count != 0 {
                        println("This item has already been saved")
                        return
                    }
                    else {
                        println("Saving to CoreData")
                        // Setup entity and assign idValue
                        let entityDescription = NSEntityDescription.entityForName("USDAItem", inManagedObjectContext: managedObjectContext!)
                        let usdaItem = USDAItem(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext!)
                        usdaItem.idValue = itemDictionaty["_id"]! as! String

                        // Sets up the date to current date
                        usdaItem.dateAdded = NSDate()
                        
                        // Indexing fields
                        if itemDictionaty["fields"] != nil {
                            
                            // Dictionay for fields
                            let fieldsDictionay = itemDictionaty["fields"]! as! NSDictionary
                            
                            // Getting the item_name
                            if fieldsDictionay["item_name"] != nil {
                                usdaItem.name = fieldsDictionay["item_name"]! as! String
                            }
                            
                            // Indexing usda_fields
                            if fieldsDictionay["usda_fields"] != nil {
                                let usdaFieldsDictionay = fieldsDictionay["usda_fields"]! as! NSDictionary
                                
                                // Getting the Calcium
                                if usdaFieldsDictionay["CA"] != nil {
                                    let calciumDictionay = usdaFieldsDictionay["CA"]! as! NSDictionary
                                    if calciumDictionay["value"] != nil {
                                        let calciumValue: AnyObject = calciumDictionay["value"]!
                                        usdaItem.calcium = "\(calciumValue)"
                                    }
                                }
                                else {
                                    usdaItem.calcium = "0"
                                }
                                
                                // Getting the Carbohydrate
                                if usdaFieldsDictionay["CHOCDF"] != nil {
                                    let carbohydrateDictionary = usdaFieldsDictionay["CHOCDF"]! as! NSDictionary
                                    if carbohydrateDictionary["value"] != nil {
                                        let carbohydrateValue: AnyObject = carbohydrateDictionary["value"]!
                                        usdaItem.carbohydrate = "\(carbohydrateValue)"
                                    }
                                }
                                else {
                                    usdaItem.carbohydrate = "0"
                                }
                                
                                // Getting Total Fat
                                if usdaFieldsDictionay["FAT"] != nil {
                                    let fatTotalDictionay = usdaFieldsDictionay["FAT"]! as! NSDictionary
                                    if fatTotalDictionay["value"] != nil {
                                        let fatTotalValue: AnyObject = fatTotalDictionay["value"]!
                                        usdaItem.fatTotal = "\(fatTotalValue)"
                                    }
                                }
                                else {
                                    usdaItem.fatTotal = "0"
                                }
                                
                                // Getting the Cholesterol 
                                if usdaFieldsDictionay["CHOLE"] != nil {
                                    let cholesterolDictionary = usdaFieldsDictionay["CHOLE"]! as! NSDictionary
                                    if cholesterolDictionary["value"] != nil {
                                        let cholesterolValue: AnyObject = cholesterolDictionary["value"]!
                                        usdaItem.cholesterol = "\(cholesterolValue)"
                                    }
                                }
                                else {
                                    usdaItem.protein = "0"
                                }
                                
                                // Getting the Protein
                                if usdaFieldsDictionay["PROCNT"] != nil {
                                    let proteinDictionary = usdaFieldsDictionay["PROCNT"]! as! NSDictionary
                                    if proteinDictionary["value"] != nil {
                                        let proteinValue: AnyObject = proteinDictionary["value"]!
                                        usdaItem.protein = "\(proteinValue)"
                                    }
                                }
                                else {
                                    usdaItem.protein = "0"
                                }
                                
                                // Getting Sugar
                                if usdaFieldsDictionay["SUGAR"] != nil {
                                    let sugarDictionary = usdaFieldsDictionay["SUGAR"]! as! NSDictionary
                                    if sugarDictionary["value"] != nil {
                                        let sugarValue: AnyObject = sugarDictionary["value"]!
                                        usdaItem.sugar = "\(sugarValue)"
                                    }
                                } else {
                                    usdaItem.sugar = "0"
                                }
                                
                                // Getting Vitamin C
                                if usdaFieldsDictionay["VITC"] != nil {
                                    let vitaminCDictionary = usdaFieldsDictionay["VITC"]! as! NSDictionary
                                    if vitaminCDictionary["value"] != nil {
                                        let vitaminCValue: AnyObject = vitaminCDictionary["value"]!
                                        usdaItem.vitaminC = "\(vitaminCValue)"
                                    }
                                } else {
                                    usdaItem.vitaminC = "0"
                                }
                                
                                // Getting Energy
                                if usdaFieldsDictionay["ENERC_KCAL"] != nil {
                                    let energyCDictionary = usdaFieldsDictionay["ENERC_KCAL"]! as! NSDictionary
                                    if energyCDictionary["value"] != nil {
                                        let energyValue: AnyObject = energyCDictionary["value"]!
                                        usdaItem.energy = "\(energyValue)"
                                    }
                                } else {
                                    usdaItem.energy = "0"
                                }
                                
                                // Saving to CoreData
                                (UIApplication.sharedApplication().delegate as! AppDelegate).saveContext()
                                
                                NSNotificationCenter.defaultCenter().postNotificationName(kUSDAItemCompleted, object: usdaItem)
                            }
                        }
                    }
                }
            }
        }
    }
    
}