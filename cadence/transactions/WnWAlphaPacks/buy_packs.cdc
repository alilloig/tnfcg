import FungibleToken from "../../contracts/FungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
//import FungibleToken from 0xf8d6e0586b0a20c7
//import FlowToken from 0xf8d6e0586b0a20c7
//import FungiblePack from 0xf8d6e0586b0a20c7
//import WnWAlphaPacks from 0xf8d6e0586b0a20c7

transaction(seller: Address, amount: UFix64) {

    let packsReceiver: &{FungibleToken.Receiver}
    let flowPayment: @FungibleToken.Vault


    prepare(signer: AuthAccount) {

        //get a reference to the buyer's packs receiver
        self.packsReceiver = signer
        .getCapability(WnWAlphaPacks.ReceiverPublicPath)
        .borrow<&{FungibleToken.Receiver}>()
        ?? panic("Unable to borrow receiver reference")

        // Get a reference to the signer's stored flow vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow reference to the payer's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.flowPayment <- vaultRef.withdraw(amount: amount * WnWAlphaPacks.TFPackInfo.price)
    }

    execute {
        //get a reference to the WnW Alpha Packs Seller         
        let packSellerRef = getAccount(seller)
        .getCapability(WnWAlphaPacks.PackSellerPublicPath)
        .borrow<&{TradingFungiblePack.PackSeller}>() 
        ?? panic("Bad seller address")

        packSellerRef.sellPacks(payment: <- self.flowPayment, packsPayerPackReceiver: self.packsReceiver, amount: amount)
    }
}