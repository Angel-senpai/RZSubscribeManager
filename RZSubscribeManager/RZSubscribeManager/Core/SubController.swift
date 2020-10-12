//
//  ProductId.swift
//  Yoga
//
//  Created by Александр Сенин on 25.09.2020.
//  Copyright © 2020 Александр Сенин. All rights reserved.
//

import UIKit
import StoreKit
import SwiftyStoreKit

class SubController{
    //MARK: - start
    /// `RU: - `
    /// Запускает все необходимые для проверки подписок процессы. Для корректной работы лучше запускать из `AppDelegate` приложения
    static func start(_ delegate: SubDelegateProtocol? = nil){
        self.delegate = delegate
        SubRefrasher.start()
        
        SubController.activeReceipt = SubController.activeReceipt
    }
    
    static weak var delegate: SubDelegateProtocol?
    
    //MARK: - activeSub
    /// `RU: - `
    /// Индекатор активности подписочного предложения
    static var activeSub: Bool = false{
        didSet(old){
            if activeSub == old { return }
            delegate?.changeSubscibe(status: activeSub)
        }
    }
    
    //MARK: - activeTrial
    /// `RU: - `
    /// Индекатор активности триального периода
    static var activeTrial: Bool {
        guard let activeReceipt = activeReceipt else {return false}
        return activeReceipt.isTrialPeriod
    }
    
    //MARK: - activeProduct
    /// `RU: - `
    /// Активный продукт, может иметь значение `nil`
    static var activeProduct: Product? {
        guard let activeReceipt = activeReceipt else {return nil}
        return Product.getProduct(activeReceipt.productId)
    }
    
    private static var activeReceiptKey = "activeReceipt"
    
    //MARK: - activeReceipt
    /// `RU: - `
    /// `ReceiptItem` активного продукта
    static var activeReceipt: ReceiptItem?{
        set(activeReceipt){
            activeSub = activeReceipt != nil
            UserDefaults.standard.set(activeReceipt?.getJson(), forKey: activeReceiptKey)
        }
        get{
            guard let activeReceiptRow = UserDefaults.standard.object(forKey: activeReceiptKey) as? [String: AnyObject] else { return nil }
            guard let activeReceipt = ReceiptItem(receiptInfo: activeReceiptRow) else { return nil }
            
            if let ti = activeReceipt.subscriptionExpirationDate?.timeIntervalSince1970{
                if ti < Date().timeIntervalSince1970{
                    return nil
                }
            }else if activeReceipt.webOrderLineItemId == nil{
                return activeReceipt
            }else{
                return nil
            }
            return activeReceipt
        }
    }
    
    
    
    //MARK: - subscribe
    /// `RU: - `
    /// Метод для инициирования процесса подписки
    ///
    /// - Parameter productId
    /// id продукта
    /// - Parameter completion
    /// замыкае вызываемое при окончании процесса подписки
    static func subscribe(product: Product, customData: Any? = nil, completion: (()->())? = nil){
        SwiftyStoreKit.purchaseProduct(product.id, atomically: true){ result in
            
            switch result{
            case .success(let purchase):
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                activeSub = true
                completion?()
                SubRefrasher.refrash()
                delegate?.subscibeSucces(product: product, customData: customData)
            case .error:
                completion?()
                delegate?.subscibeFaild(product: product, customData: customData)
            }
        }
    }
}

/*
class SubData{
    var stateСhange: [((Bool)->(Bool))] = []
    
    var completLoadingPriseClosure: [((Bool)->(Bool))] = []
    
      
    
    var activeSub = false{
        didSet(old){
            if old == activeSub {return}
            stateСhange = stateСhange.filter(){$0(activeSub)}
        }
    }
    var activeTrial = false
    
    var localeStore: String = ParentElements.localeRow
    
    init(){
        if UserDefaults.standard.integer(forKey: "dateUsing") >= Int(Date().timeIntervalSince1970){
            activeSub = true
        }
        
        getProduct()
        refrash(completion: nil)
    }
    
    var completionsClosers: [(()->(Bool))?] = []
    var refrashTimer: Timer!
    
    var compGetPrise = false{
        didSet{
            completLoadingPriseClosure = completLoadingPriseClosure.filter(){$0(activeSub)}
            if compRefrash{
                completionsClosers = completionsClosers.filter(){$0?() ?? false}
            }
        }
    }
    var compRefrash = false{
        didSet{
            if compGetPrise{
                completionsClosers = completionsClosers.filter(){$0?() ?? false}
            }
        }
    }

    func getProduct(){
        var skProducts: Set<SKProduct> = []{
            didSet{
                DispatchQueue.main.async{
                    self.getPrise(prodects: skProducts)
                }
            }
        }
        SwiftyStoreKit.retrieveProductsInfo(ProductId.allKeys) { result in
            skProducts = result.retrievedProducts
        }
    }
    
    func getPrise(prodects: Set<SKProduct>){
        if prodects != []{
            for plan in prodects{
                if let productId = ProductId(rawValue: plan.productIdentifier),
                   let price = plan.localizedPrice,
                   let currencyCode = plan.priceLocale.currencyCode{
                    ProductId.setPrise(productId, price)
                    ProductId.setPrisesMans(productId, "\(plan.price)")
                    ProductId.setCurrencyCods(productId, currencyCode)
                }
            }
            self.compGetPrise = true
            postSKU(skProducts: prodects)
        }else{
            getProduct()
        }
        
    }
    
    func startRefrash(completion: (()->(Bool))?){
        if compGetPrise && compRefrash{
            _ = completion?()
        }else{
            completionsClosers.append(completion)
            refrash(completion: nil)
            //getPrise()
        }
        refrashTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true, block: {_ in
            DispatchQueue.global(qos: .background).async {
                self.refrash(completion: completion)
            }
        })
    }
    
    var refrashBackgroundTaskId: UIBackgroundTaskIdentifier?
    var postAppBackgroundTaskId: UIBackgroundTaskIdentifier?
    var postSKUBackgroundTaskId: UIBackgroundTaskIdentifier?
    
    func refrash(completion: (()->(Bool))?, purchase: Bool = false){
        
        self.refrashBackgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "refrash")
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: ProductId.sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            if case .success(let receipt) = result {
                var active = false
                var receiptActive: ReceiptItem?
                for i in ProductId.all{
                    let purchaseResult = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable,
                                                                           productId: i.rawValue,
                                                                           inReceipt: receipt)
                    switch purchaseResult {
                    case .purchased(_, let receiptItems):
                        active = true
                        let trial = receiptItems.filter { $0.isTrialPeriod == true}
                        if trial.count > 0{
                        
                            let dateEndTrial = trial[0].purchaseDate + TimeInterval(60 * 60 * 24 * i.trial)
                            if dateEndTrial > Date(){
                                self.activeTrial = true
                            }
                        }
                        if purchase{
                            receiptActive = receiptItems.last!
                        }
                        
                        DispatchQueue.main.async {
                            if let receipt = receiptItems.last{
                                self.postApp(receiptItem: receipt, trial: i.trial)
                            }
                        }
                    case .expired: UserDefaults.standard.set(true, forKey: "expired")
                    case .notPurchased: break
                    }
                }
                if DataBase.godMod{
                    self.activeSub = true
                }else{
                    self.activeSub = active
                }
                if let receipt = receiptActive{
                    self.events(receiptItem: receipt)
                }
                
                _ = completion?()
            
                self.compRefrash = true
            }
            if let btID = self.refrashBackgroundTaskId{
                UIApplication.shared.endBackgroundTask(btID)
            }
        }
    }
    
    func events(receiptItem: ReceiptItem){
        guard let product = ProductId(rawValue: receiptItem.productId) else {return}
        if self.activeTrial{
            EventManager.sendAFEvent(with: "af_trial" + "_\(product.name)")
            EventManager.sendAFEvent(with: "af_all_events")
            EventManager.sendADJEvent(with: product.getToken(true))
            
            let params = [AppEvents.ParameterName.orderID.rawValue:receiptItem.originalTransactionId,
                          AppEvents.ParameterName.currency.rawValue:"USD"]
            AppEvents.logEvent(.startTrial, parameters: params)
            
        }
        if !UserDefaults.standard.bool(forKey: "sub") &&
            self.activeSub &&
            !self.activeTrial{
            EventManager.sendAFEvent(with: "af_subscribe" + "_\(product.name)")
            EventManager.sendAFEvent(with: "af_all_events")
            getPriceAndCurrency(product, transictionId: receiptItem.transactionId)
        }
        
    }
    
    private func getPriceAndCurrency(_ product: ProductId, transictionId: String){
        var rev: Double? = nil
        var cur: String? = nil
        
        ProductId.getPricesMans(productId: product){ [weak self] revenueStr in
            rev = Double(Float(revenueStr) ?? 0)
            self?.sendAdjRev(product: product, revenue: rev, currency: cur, trId: transictionId)
        }
        
        ProductId.getCurrencyCods(productId: product){ [weak self] currency in
            cur = currency
            self?.sendAdjRev(product: product, revenue: rev, currency: cur, trId: transictionId)
        }
    }
    
    private func sendAdjRev(product: ProductId, revenue: Double?, currency: String?, trId: String){
        guard let revenue = revenue, let currency = currency else {return}
        EventManager.sendADJEvent(with: product.getToken(), revenue: revenue * 0.7, currency: currency)
        
        guard let recipt = SwiftyStoreKit.localReceiptData else {return}
        guard let subscribe = ADJSubscription(price: NSDecimalNumber(value: revenue),
                                              currency:  currency,
                                              transactionId: trId,
                                              andReceipt: recipt ) else {return}
        Adjust.trackSubscription(subscribe)
    }
    
    private var keyIvent = "Ivent"
    var ivent: Bool{
        set(composeTutor){
            UserDefaults.standard.set(composeTutor, forKey: keyIvent)
        }
        get{
            return UserDefaults.standard.bool(forKey: keyIvent)
        }
    }
    
    private func postApp(receiptItem: ReceiptItem, trial: Int = 0){
        if ivent {return}
        
        self.postAppBackgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "postApp")
        let queue = DispatchQueue.global(qos: .utility)
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let parameters: [String : String] = ["ot_id": "\(receiptItem.originalTransactionId)",
                                             "af_id": "\(AppsFlyerTracker.shared().getAppsFlyerUID())",
                                             "country": localeStore,
                                             "idfa": identifierForAdvertising() ?? "",
                                             "adid": Adjust.adid() ?? "",
                                             "install_time": UserDefaults.standard.string(forKey: "install_time") ?? "\(Date().timeIntervalSince1970)",
                                             "trial_days":"\(trial)",
                                             "bid": bundleID]
        request(DownloadSupport.domenPath + "yoga-ios-server/NewServer/AppScript.php", method: .post, parameters: parameters).response(queue: queue, responseSerializer: DataRequest.stringResponseSerializer()) {response in
            if (Int(response.value ?? "") ?? 0) == 1{
                self.ivent = true
            }
            if let btID = self.postAppBackgroundTaskId{
                UIApplication.shared.endBackgroundTask(btID)
            }
        }
    }
    
    private func postSKU(skProducts: Set<SKProduct>){
        self.postSKUBackgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "postSKU")
        let skuPostModel = SKUPostModel()
        var skuModels: [SKUModel] = []
        var country = ParentElements.localeRow
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        
        for plan in skProducts{
            let skuModel = SKUModel()
            
            skuModel.SKU = plan.productIdentifier
            skuModel.name = ProductId(rawValue: plan.productIdentifier)?.name ?? "???"
            skuModel.currency = plan.priceLocale.currencyCode ?? "???"
            skuModel.price = "\(plan.price)"
            country = plan.priceLocale.regionCode ?? ParentElements.localeRow
            skuModels.append(skuModel)
        }
        skuPostModel.SKUS = skuModels
        skuPostModel.country = country
        skuPostModel.bid = bundleID
        DispatchQueue.main.async {
            self.localeStore = country
        }
        guard let parameters = skuPostModel.convertToJson() as? [String: Any] else {return}
        let queue = DispatchQueue.global(qos: .utility)
        
        request(DownloadSupport.domenPath + "yoga-ios-server/NewServer/SKUUpdater.php", method: .post, parameters: parameters, encoding: JSONEncoding()).response(queue: queue, responseSerializer: DataRequest.stringResponseSerializer()) {response in
            if let btID = self.postSKUBackgroundTaskId{
                UIApplication.shared.endBackgroundTask(btID)
            }
        }
    }
    
    private func identifierForAdvertising() -> String? {
        guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
            return nil
        }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    func goSub(productId: String, completion: (()->(Bool))?){
        SwiftyStoreKit.purchaseProduct(productId, atomically: true){ result in
            
            switch result{
            case .success(let purchase):
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                
                let dateUsing = (Int(Date().timeIntervalSince1970) + (60 * 60 * 24) * ProductId.init(rawValue: productId)!.using)
                UserDefaults.standard.set(dateUsing, forKey: "dateUsing")
                self.activeSub = true
                EventManager.sendAMPEvent(with: EventManager.eventName,params: ["wich":EventManager.eventValue,"where":EventManager.screenName,"subscribe":"success"], projct: .all)

                //EventManager.sendAMPEvent(with: "\(ProductId.init(rawValue: productId)!.name) subscribe success")
                _ = completion?()
                self.refrash(completion: nil, purchase: true)
            case .error(let purchase):
                print(purchase)
                EventManager.sendAMPEvent(with: EventManager.eventName,params: ["wich":EventManager.eventValue,"where":EventManager.screenName,"subscribe":"cancel"], projct: .all)
                //EventManager.sendAMPEvent(with: "\(ProductId.init(rawValue: productId)!.name) subscribe cancel")
                self.refrash(completion: completion)
            }
        }
    }
}
*/








