import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import TNFCGPacks from "../../contracts/TNFCGPacks.cdc"
import TNFCGCards from "../../contracts/TNFCGCards.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {

    let TNFCGPacksReceiver: Capability<&TNFCGPacks.Vault{FungibleToken.Receiver}>
    let TNFCGCardsProvider: Capability<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let TNFCGCardsCollectionProviderPrivatePath = /private/TNFCGCardsCollectionProvider

        self.TNFCGPacksReceiver = account.getCapability<&TNFCGPacks.Vault{FungibleToken.Receiver}>(TNFCGPacks.ReceiverPublicPath)!
        
        assert(self.TNFCGPacksReceiver.borrow() != nil, message: "Missing or mis-typed Kibble receiver")

        if !account.getCapability<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(TNFCGCardsCollectionProviderPrivatePath)!.check() {
            account.link<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(TNFCGCardsCollectionProviderPrivatePath, target: TNFCGCards.CollectionStoragePath)
        }

        self.TNFCGCardsProvider = account.getCapability<&TNFCGCards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(TNFCGCardsCollectionProviderPrivatePath)!
        assert(self.TNFCGCardsProvider.borrow() != nil, message: "Missing or mis-typed KittyItems.Collection provider")

        self.storefront = account.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")
    }

    execute {
        let saleCut = NFTStorefront.SaleCut(
            receiver: self.TNFCGPacksReceiver,
            amount: saleItemPrice
        )
        self.storefront.createSaleOffer(
            nftProviderCapability: self.TNFCGCardsProvider,
            nftType: Type<@TNFCGCards.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@TNFCGPacks.Vault>(),
            saleCuts: [saleCut]
        )
    }
}
