import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import TNFCGPacks from "../../contracts/TNFCGPacks.cdc"
import TNFCGCards from "../../contracts/TNFCGCards.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

transaction(saleOfferResourceID: UInt64, storefrontAddress: Address) {

    let paymentVault: @FungibleToken.Vault
    let kittyItemsCollection: &TNFCGCards.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let saleOffer: &NFTStorefront.SaleOffer{NFTStorefront.SaleOfferPublic}

    prepare(account: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Cannot borrow Storefront from provided address")

        self.saleOffer = self.storefront.borrowSaleOffer(saleOfferResourceID: saleOfferResourceID)
            ?? panic("No offer with that ID in Storefront")
        
        let price = self.saleOffer.getDetails().salePrice

        let mainKibbleVault = account.borrow<&TNFCGPacks.Vault>(from: TNFCGPacks.VaultStoragePath)
            ?? panic("Cannot borrow Kibble vault from account storage")
        
        self.paymentVault <- mainKibbleVault.withdraw(amount: price)

        self.kittyItemsCollection = account.borrow<&TNFCGCards.Collection{NonFungibleToken.Receiver}>(
            from: TNFCGCards.CollectionStoragePath
        ) ?? panic("Cannot borrow KittyItems collection receiver from account")
    }

    execute {
        let item <- self.saleOffer.accept(
            payment: <-self.paymentVault
        )

        self.kittyItemsCollection.deposit(token: <-item)

        self.storefront.cleanup(saleOfferResourceID: saleOfferResourceID)
    }
}
