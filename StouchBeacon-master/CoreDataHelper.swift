import UIKit
import AVFoundation
import CoreData
import CoreLocation

private let sharedCoreDataHelper = CoreDataHelper()

class CoreDataHelper {
    class var instance: CoreDataHelper {
        return sharedCoreDataHelper
    }
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    
    // MARK: Beacon
    
    func getBeacon () -> Beacon? {
        let fetchRequest: NSFetchRequest<Beacon> = Beacon.fetchRequest()
        
        do {
            return try getContext().fetch(fetchRequest).first as Beacon?
        }
        catch {
            print("error with request beacon: \(error)")
        }
        return nil
    }
    
    func storeBeacon (id: String, major: String, minor: String) {
        let context = getContext()
        let entity  = NSEntityDescription.entity(forEntityName: "Beacon", in: context)
        let transc  = NSManagedObject(entity: entity!, insertInto: context)
        
        transc.setValue(id, forKey: "id")
        transc.setValue(major, forKey: "major")
        transc.setValue(minor, forKey: "minor")
        transc.setValue(false, forKey: "sent")
        transc.setValue(false, forKey: "isMissing")
        
        do {
            try context.save()
            print("beacon saved in core data")
        }
        catch let error as NSError  {
            print("could not store \(error), \(error.userInfo)")
        }
        catch {
        }
    }
    
    func updateBeacon(key: String, value: Bool) {
        let beacon = getBeacon()
        
        if beacon != nil {
            beacon!.setValue(value, forKey: key)
            do {
                let context = getContext()
                try context.save()
                print("beacon updated in core data")
            }
            catch let error as NSError  {
                print("could not update beacon \(error), \(error.userInfo)")
            }
            catch {
            }
        }
    }
    
    func isMyBeacon(beacon: CLBeacon) -> Bool  {
        let coreDataEntry = getBeacon()
        
        if nil != coreDataEntry {
            let major = NSNumber.init(value: Int32(coreDataEntry!.major!)!)
            let minor = NSNumber.init(value: Int32(coreDataEntry!.minor!)!)
            
            return major==beacon.major && minor==beacon.minor
        }
        
        return false
    }
    
    
    // MARK: User
    
    func getUser () -> AppUser? {
        let fetchRequest: NSFetchRequest<AppUser> = AppUser.fetchRequest()
        
        do {
            return try getContext().fetch(fetchRequest).first as AppUser?
        }
        catch {
            print("error with request user: \(error)")
        }
        return nil
    }
    
    func storeUser (userId: String) {
        let context = getContext()
        let entity  = NSEntityDescription.entity(forEntityName: "AppUser", in: context)
        let transc  = NSManagedObject(entity: entity!, insertInto: context)
        
        transc.setValue(userId, forKey: "userId")
        
        do {
            try context.save()
            print("user saved in core data")
        }
        catch let error as NSError  {
            print("could not store user \(error), \(error.userInfo)")
        }
        catch {
        }
    }
    
    func updateUserData(firstName: String, lastName: String, email : String, phone: String) {
        let user = getUser()
        
        if user != nil {
            user!.setValue(firstName, forKey: "first_Name")
            user!.setValue(lastName, forKey: "last_Name")
            user!.setValue(email, forKey: "email")
            user!.setValue(phone, forKey: "tel")
            
            do {
                let context = getContext()
                try context.save()
                print("beacon updated in core data")
            }
            catch let error as NSError  {
                print("could not update beacon \(error), \(error.userInfo)")
            }
            catch {
            }
        }
    }
}
