import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import TNFCGCards from "../../contracts/TNFCGCards.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

pub fun getOrCreateStorefront(account: AuthAccount): &NFTStorefront.Storefront {
    if let storefrontRef = account.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath) {
        return storefrontRef
    }

    let storefront <- NFTStorefront.createStorefront()

    let storefrontRef = &storefront as &NFTStorefront.Storefront

    account.save(<-storefront, to: NFTStorefront.StorefrontStoragePath)

    account.link<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath, target: NFTStorefront.StorefrontStoragePath)

    return storefrontRef
}

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {

    let flowReceiver: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let TNFCGCardsProvider: Capability<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let TNFCGCardsCollectionProviderPrivatePath = /private/TNFCGCardsCollectionProvider

        self.flowReceiver = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!

        assert(self.flowReceiver.borrow() != nil, message: "Missing or mis-typed FLOW receiver")

        if !account.getCapability<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(TNFCGCardsCollectionProviderPrivatePath)!.check() {
            account.link<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(TNFCGCardsCollectionProviderPrivatePath, target: TNFCGCards.CollectionStoragePath)
        }

        self.TNFCGCardsProvider = account.getCapability<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(TNFCGCardsCollectionProviderPrivatePath)!

        assert(self.TNFCGCardsProvider.borrow() != nil, message: "Missing or mis-typed TNFCGCards.Collection provider")

        self.storefront = getOrCreateStorefront(account: account)
    }

    execute {
        let saleCut = NFTStorefront.SaleCut(
            receiver: self.flowReceiver,
            amount: saleItemPrice
        )
        self.storefront.createListing(
            nftProviderCapability: self.TNFCGCardsProvider,
            nftType: Type<@TNFCGCards.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FlowToken.Vault>(),
            saleCuts: [saleCut]
        )
    }
}
