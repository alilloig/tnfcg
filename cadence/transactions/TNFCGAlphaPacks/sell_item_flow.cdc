import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import TNFCGCards from "../../contracts/TNFCGCards.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {

    let flowTokenReceiver: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let kittyItemsProvider: Capability<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let TNFCGCardsCollectionProviderPrivatePath = /private/TNFCGCardsCollectionProvider

        self.flowTokenReceiver = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        
        assert(self.flowTokenReceiver.borrow() != nil, message: "Missing or mis-typed Kibble receiver")

        if !account.getCapability<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(TNFCGCardsCollectionProviderPrivatePath)!.check() {
            account.link<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(TNFCGCardsCollectionProviderPrivatePath, target: TNFCGCards.PrintedCardsStoragePath)
        }

        self.kittyItemsProvider = account.getCapability<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(TNFCGCardsCollectionProviderPrivatePath)!
        
        assert(self.kittyItemsProvider.borrow() != nil, message: "Missing or mis-typed KittyItems.Collection provider")

        self.storefront = account.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")
    }

    execute {
        let saleCut = NFTStorefront.SaleCut(
            receiver: self.flowTokenReceiver,
            amount: saleItemPrice
        )
        self.storefront.createSaleOffer(
            nftProviderCapability: self.kittyItemsProvider,
            nftType: Type<@TNFCGCards.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FlowToken.Vault>(),
            saleCuts: [saleCut]
        )
    }
}
 