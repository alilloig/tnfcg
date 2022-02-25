import FungibleToken from "../../contracts/FungibleToken.cdc"
import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
import TradingNonFungibleCardGame from "../../contracts/TradingNonFungibleCardGame.cdc"
import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
//import FungibleToken from 0xf8d6e0586b0a20c7
//import TradingFungiblePack from 0xf8d6e0586b0a20c7
//import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
//import WnWAlphaPacks from 0xf8d6e0586b0a20c7
//import WnW from 0xf8d6e0586b0a20c7
//import NonFungiblePack from 0xf8d6e0586b0a20c7


// Tx para setear el admin

transaction {
    let packsAdmin: &WnWAlphaPacks.Administrator

    prepare(signer: AuthAccount) {

        // Check if the signer is the WnWAlphaPacks Admin
        self.packsAdmin = signer.borrow<&WnWAlphaPacks.Administrator>(from: WnWAlphaPacks.AdminStoragePath)
            ?? panic("Signer is not the WnW Alpha packs admin")

        // if the account doesn't already have a vault
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

        //if the account doesn't already have a PackSeller
        if signer.borrow<&{TradingFungiblePack.PackSeller}>(from: WnWAlphaPacks.PackSellerStoragePath) == nil {
            signer.save(
                <- self.packsAdmin.createNewPackSeller(packSellerFlowTokenCapability: signer.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)), 
                to: WnWAlphaPacks.PackSellerStoragePath)
        }

        // if the account doesn't already have a PackOpener
        if signer.borrow<&{TradingFungiblePack.PackOpener}>(from: WnWAlphaPacks.PackOpenerStoragePath) == nil {
            signer.save(
                <- self.packsAdmin.createNewPackOpener(packFulfilerCapability: signer.getCapability<&WnW.SetPackFulfiler>(WnW.PackFulfilerPrivatePath)), 
                to: WnWAlphaPacks.PackOpenerStoragePath)
        }

    }
}


       /* packSellerFlowTokenCapability: self.account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), 
                packFulfilerCapability: self.account.getCapability<&{TradingNonFungibleCardGame.PackFulfiler}>(WnW.PackFulfilerPrivatePath)
        // Expose a public capability allowing users to get packs in exchange for flow tokens
        self.account.link<&WnWAlphaPacks.Administrator{TradingFungiblePack.PackSeller}>(
            self.PackSellerPublicPath,
            target: self.AdminStoragePath
        )

        // Expose a public capability allowing users to open packs, sending it to the account and receiving WnW cards
        self.account.link<&WnWAlphaPacks.Administrator{TradingFungiblePack.PackOpener}>(
            self.PackOpenerPublicPath,
            target: self.AdminStoragePath
        ) */