//import FungibleToken from "../../contracts/FungibleToken.cdc"
//import FlowToken from "../../contracts/FlowToken.cdc"
//import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
//import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
import FungibleToken from 0xf8d6e0586b0a20c7
import FlowToken from 0xf8d6e0586b0a20c7
import TradingFungiblePack from 0xf8d6e0586b0a20c7
import WnWAlphaPacks from 0xf8d6e0586b0a20c7

transaction() {
    let packsReceiver: &{FungibleToken.Receiver}
    let flowPayment: @FungibleToken.Vault


    prepare(signer: AuthAccount) {
        //get a reference to the buyer's packs receiver
        self.packsReceiver = signer
        .getCapability(WnWAlphaPacks.ReceiverPublicPath)
        .borrow<&{FungibleToken.Receiver}>()
        ?? panic("Unable to borrow receiver reference")

        // Get a reference to the signer's stored flow vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: FlowToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the payer's Vault!")

        // Withdraw tokens from the signer's stored vault
        let purchaseAmount = 1.0 * WnWAlphaPacks.TFPackInfo.price
        log("paying")
        log(purchaseAmount)
        self.flowPayment <- vaultRef.withdraw(amount: purchaseAmount)
    }

    execute {
        //get a reference to the WnW Alpha Packs Seller         
        let packSellerRef = getAccount(0xf8d6e0586b0a20c7)
        .getCapability(WnWAlphaPacks.PackSellerPublicPath)
        .borrow<&{TradingFungiblePack.PackSeller}>() 
        ?? panic("Bad seller address")

        packSellerRef.sellPacks(payment: <- self.flowPayment, packsPayerPackReceiver: self.packsReceiver, amount: 1.0)
    }
}
 