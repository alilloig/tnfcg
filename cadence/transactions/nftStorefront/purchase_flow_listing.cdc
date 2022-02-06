import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import WnW from "../../contracts/Witchcraft&Wizardry.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

pub fun getOrCreateCollection(account: AuthAccount): &WnW.Collection{NonFungibleToken.Receiver} {
    if let collectionRef = account.borrow<&WnW.Collection>(from: WnW.PrintedCardsStoragePath) {
        return collectionRef
    }

    // create a new empty collection
    let collection <- WnW.createEmptyCollection() as! @WnW.Collection

    let collectionRef = &collection as &WnW.Collection
    
    // save it to the account
    account.save(<-collection, to: WnW.PrintedCardsStoragePath)

    // create a public capability for the collection
    account.link<&WnW.Collection{NonFungibleToken.CollectionPublic, WnW.WnWCollectionPublic}>(WnW.PrintedCardsPublicPath, target: WnW.PrintedCardsStoragePath)

    return collectionRef
}

transaction(listingResourceID: UInt64, storefrontAddress: Address) {

    let paymentVault: @FungibleToken.Vault
    let WnWCollection: &WnW.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}

    prepare(account: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No Listing with that ID in Storefront")
        
        let price = self.listing.getDetails().salePrice

        let mainFLOWVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow FLOW vault from account storage")
        
        self.paymentVault <- mainFLOWVault.withdraw(amount: price)

        self.WnWCollection = getOrCreateCollection(account: account)
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )

        self.WnWCollection.deposit(token: <-item)

        self.storefront.cleanup(listingResourceID: listingResourceID)
    }
}
 