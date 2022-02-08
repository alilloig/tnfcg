import FungibleToken from "../../contracts/FungibleToken.cdc"
import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
//import FungibleToken from 0xf8d6e0586b0a20c7
//import NonFungiblePack from 0xf8d6e0586b0a20c7
//import WnWAlphaPacks from 0xf8d6e0586b0a20c7

// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the Alpha Packs

transaction {
    let packsAdmin: &WnWAlphaPacks.Administrator

    prepare(signer: AuthAccount) {

        //Te quedas loco que esta es toda la autenticación
        self.packsAdmin = signer.borrow<&WnWAlphaPacks.Administrator>(from: WnWAlphaPacks.AdminStoragePath)
            ?? panic("Signer is not the packs admin")

        if signer.borrow<&WnWAlphaPacks.Vault>(from: WnWAlphaPacks.VaultStoragePath) == nil {
            // Create a new Pack Vault and put it in storage
            signer.save(<-WnWAlphaPacks.createEmptyVault(), to: WnWAlphaPacks.VaultStoragePath)
            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            signer.link<&WnWAlphaPacks.Vault{FungibleToken.Receiver}>(
                WnWAlphaPacks.ReceiverPublicPath,
                target: WnWAlphaPacks.VaultStoragePath
            )
            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            signer.link<&WnWAlphaPacks.Vault{FungibleToken.Balance}>(
                WnWAlphaPacks.BalancePublicPath,
                target: WnWAlphaPacks.VaultStoragePath
            )
        }
        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&WnWAlphaPacks.Administrator>(
                WnWAlphaPacks.PackOpenerPublicPath, 
                target: WnWAlphaPacks.AdminStoragePath)
    }
}