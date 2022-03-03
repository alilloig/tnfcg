import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
//import FungibleToken from 0xf8d6e0586b0a20c7
//import import NonFungibleToken from 0xf8d6e0586b0a20c7
//import FlowToken from 0xf8d6e0586b0a20c7
//import FungiblePack from 0xf8d6e0586b0a20c7
//import WnWAlphaPacks from 0xf8d6e0586b0a20c7

transaction(seller: Address, amount: UFix64) {

    //The collection where the opened TNFCs will be deposit
    let tnfcCollection: &{NonFungibleToken.CollectionPublic}

    // The Vault resource that holds the packs that are being opened
    let packsToOpen: @FungibleToken.Vault


    prepare(signer: AuthAccount) {

        //get a reference to the buyer's packs receiver
        self.tnfcCollection = signer
        .getCapability(WnW.OwnedCardsCollectionPublicPath)
        .borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Unable to borrow collection reference")

        // Get a reference to the signer's stored pack vault
        let vaultRef = signer.borrow<&WnWAlphaPacks.Vault>(from: WnWAlphaPacks.VaultStoragePath)
            ?? panic("Could not borrow reference to the payer's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.packsToOpen <- vaultRef.withdraw(amount: amount)
    }

    execute {
        //get a reference to the WnW Alpha Packs Seller         
        let packSellerRef = getAccount(seller)
        .getCapability(WnWAlphaPacks.PackOpenerPublicPath)
        .borrow<&{TradingFungiblePack.PackOpener}>() 
        ?? panic("Bad seller address")

        packSellerRef.openPacks(packsToOpen: <- self.packsToOpen, packsOwnerCardCollectionPublic: self.tnfcCollection)
    }
}