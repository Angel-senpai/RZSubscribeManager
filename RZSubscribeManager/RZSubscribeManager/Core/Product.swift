//
//  Product.swift
//  Yoga
//
//  Created by Александр Сенин on 09.10.2020.
//  Copyright © 2020 Александр Сенин. All rights reserved.
//

import Foundation
import StoreKit
import SwiftyStoreKit


struct Product: Equatable{
    var id: String
    var isSubscibe: Bool = true
    var customData: [String: Any] = [:]
    
    static var allProduct: [String: Product] = [:]
    
    static func getProduct(_ id: String) -> Product?{
        return allProduct[id]
    }
    
    static var sharedSecret: String = ""
    
    static func add(_ products: [Product]){
        for product in products{
            allProduct[product.id] = product
        }
        getProductInfo()
    }
    
    static var allKeys: Set<String> {
        var allKeys: Set<String> = []
        allProduct.forEach{allKeys.insert($0.key)}
        return allKeys
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
    
    private static var prices: [String: String] = [:]
    private static var pricesMans: [String: String] = [:]
    private static var currencyCods: [String: String] = [:]
    
    private static var pricesClosure: [String: (String)->()] = [:]
    private static var pricesMansClosure: [String: (String)->()] = [:]
    private static var currencyCodsClosure: [String: (String)->()] = [:]
    
    static func setPrice(_ productId: Product, _ prise: String){
        DispatchQueue.main.async {
            prices[productId.id] = prise
            pricesClosure.removeValue(forKey: productId.id)?(prise)
        }
    }
    static func setPricesMans(_ productId: Product, _ priseMan: String){
        DispatchQueue.main.async {
            pricesMans[productId.id] = priseMan
            pricesMansClosure.removeValue(forKey: productId.id)?(priseMan)
        }
    }
    static func setCurrencyCods(_ productId: Product, _ currencyCod: String){
        DispatchQueue.main.async {
            currencyCods[productId.id] = currencyCod
            currencyCodsClosure.removeValue(forKey: productId.id)?(currencyCod)
        }
    }
    
    private static func getProductInfo(){
        var skProducts: Set<SKProduct> = []{
            didSet{
                DispatchQueue.main.async{ setProductInfo(prodects: skProducts) }
            }
        }
        SwiftyStoreKit.retrieveProductsInfo(allKeys) { result in
            if skProducts != result.retrievedProducts{
                skProducts = result.retrievedProducts
            }
            if result.retrievedProducts.count < allKeys.count{
                getProductInfo()
                return
            }
        }
    }
    
    private static func setProductInfo(prodects: Set<SKProduct>){
        if prodects != []{
            for plan in prodects{
                if let productId = getProduct(plan.productIdentifier),
                   let price = plan.localizedPrice,
                   let currencyCode = plan.priceLocale.currencyCode{
                    setPrice(productId, price)
                    setPricesMans(productId, "\(plan.price)")
                    setCurrencyCods(productId, currencyCode)
                }
            }
            SubController.delegate?.productsReceived(skProducts: prodects)
        }else{
            getProductInfo()
        }
    }
    
    //MARK: - getPrice
    /// `RU: - `
    /// Метод устанавливает замыкание ожидающее получения локализованного ценника подписки
    ///
    /// Если значение цены уже получено зымыкание будет вызвано сразу
    ///
    /// - Parameter productId
    /// Продукт
    /// - Parameter action
    /// Замыкание принимающее локалезированный ценник
    static func getPrice(productId: Product, action: @escaping (String)->()){
        DispatchQueue.main.async {
            getValue(productId, prices, &pricesClosure, action)
        }
    }
    
    /// `RU: - `
    /// Метод устанавливает замыкание ожидающее получения локализованного ценника подписки
    ///
    /// Если значение цены уже получено зымыкание будет вызвано сразу
    ///
    /// - Parameter action
    /// Замыкание принимающее локалезированный ценник
    func getPrice(action: @escaping (String)->()){
        Self.getPrice(productId: self, action: action)
    }
    
    //MARK: - getPricesMans
    /// `RU: - `
    /// Метод устанавливает замыкание ожидающее получения ценника подписки
    ///
    /// Если значение цены уже получено зымыкание будет вызвано сразу
    ///
    /// - Parameter productId
    /// Продукт
    /// - Parameter action
    /// Замыкание принимающее локалезированный ценник
    static func getPricesMans(productId: Product, action: @escaping (String)->()){
        DispatchQueue.main.async {
            getValue(productId, pricesMans, &pricesMansClosure, action)
        }
    }
    
    /// `RU: - `
    /// Метод устанавливает замыкание ожидающее получения ценника подписки
    ///
    /// Если значение цены уже получено зымыкание будет вызвано сразу
    ///
    /// - Parameter action
    /// Замыкание принимающее ценник
    func getPricesMans(action: @escaping (String)->()){
        Self.getPricesMans(productId: self, action: action)
    }
    
    //MARK: - getCurrencyCods
    /// `RU: - `
    /// Метод устанавливает замыкание ожидающее получение кода валюты подписки
    ///
    /// Если значение кода валюты уже получено зымыкание будет вызвано сразу
    ///
    /// - Parameter productId
    /// Продукт
    /// - Parameter action
    /// Замыкание принимающее локалезированный кода валюты
    static func getCurrencyCods(productId: Product, action: @escaping (String)->()){
        DispatchQueue.main.async {
            getValue(productId, currencyCods, &currencyCodsClosure, action)
        }
    }
    
    /// `RU: - `
    /// Метод устанавливает замыкание ожидающее получение кода валюты подписки
    ///
    /// Если значение кода валюты уже получено зымыкание будет вызвано сразу
    ///
    /// - Parameter action
    /// Замыкание принимающее локалезированный кода валюты
    func getCurrencyCods(action: @escaping (String)->()){
        Self.getCurrencyCods(productId: self, action: action)
    }
    
    
    private static func getValue(_ productId: Product,
                                 _ dic: [String: String],
                                 _ closures: inout [String: (String)->()],
                                 _ action: @escaping (String)->()){
        if let value = dic[productId.id]{
            action(value)
        }else{
            closures[productId.id] = action
        }
    }
    
    func subscribe(_ customData: Any? = nil, completion: (()->())? = nil){
        SubController.subscribe(product: self, customData: customData, completion: completion)
    }
}
