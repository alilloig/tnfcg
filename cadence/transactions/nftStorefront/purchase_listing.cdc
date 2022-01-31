import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import KittyItems from "../../contracts/KittyItems.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

pub fun getOrCreateCollection(account: AuthAccount): &KittyItems.Collection{NonFungibleToken.Receiver} {
    if let collectionRef = account.borrow<&KittyItems.Collection>(from: KittyItems.CollectionStoragePath) {
        return collectionRef
    }

    // create a new empty collection
    let collection <- KittyItems.createEmptyCollection() as! @KittyItems.Collection

    let collectionRef = &collection as &KittyItems.Collection
    
    // save it to the account
    account.save(<-collection, to: KittyItems.CollectionStoragePath)

    // create a public capability for the collection
    account.link<&KittyItems.Collection{NonFungibleToken.CollectionPublic, KittyItems.KittyItemsCollectionPublic}>(KittyItems.CollectionPublicPath, target: KittyItems.CollectionStoragePath)

    return collectionRef
}

transaction(listingResourceID: UInt64, storefrontAddress: Address) {

    let paymentVault: @FungibleToken.Vault
    let kittyItemsCollection: &KittyItems.Collection{NonFungibleToken.Receiver}
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

        self.kittyItemsCollection = getOrCreateCollection(account: account)
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )

        self.kittyItemsCollection.deposit(token: <-item)

        self.storefront.cleanup(listingResourceID: listingResourceID)
    }
}
