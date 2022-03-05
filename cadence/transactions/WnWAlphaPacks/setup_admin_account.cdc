//import FungibleToken from "../../contracts/FungibleToken.cdc"
//import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
//import TradingNonFungibleCardGame from "../../contracts/TradingNonFungibleCardGame.cdc"
//import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import FungibleToken from 0xf8d6e0586b0a20c7
import TradingFungiblePack from 0xf8d6e0586b0a20c7
import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
import WnWAlphaPacks from 0xf8d6e0586b0a20c7
import WnW from 0xf8d6e0586b0a20c7
//import NonFungiblePack from 0xf8d6e0586b0a20c7


// Tx para setear el admin

transaction() {
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
    }
}
 