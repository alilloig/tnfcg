//import FungibleToken from "../../contracts/FungibleToken.cdc"
//import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
//import FlowToken from "../../contracts/FlowToken.cdc"
//import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
//import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
import FungibleToken from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7
import FlowToken from 0xf8d6e0586b0a20c7
import TradingFungiblePack from 0xf8d6e0586b0a20c7
import WnW from 0xf8d6e0586b0a20c7
import WnWAlphaPacks from 0xf8d6e0586b0a20c7

transaction() {

    // The Vault resource that holds the packs that are being opened
    let packsToOpen: @FungibleToken.Vault
    let packsOwnerAddress: Address


    prepare(signer: AuthAccount) {
        // Get a reference to the signer's stored pack vault
        let vaultRef = signer.borrow<&WnWAlphaPacks.Vault>(from: WnWAlphaPacks.VaultStoragePath)
            ?? panic("Could not borrow reference to the payer's Vault!")
        // Withdraw one pack from the signer's stored vault
        self.packsToOpen <- vaultRef.withdraw(amount: 1.0)
        self.packsOwnerAddress = signer.address
    }

    execute {
        // Get a reference to the WnW Alpha Packs Seller
        // The address should be set as a parameter but stays hardcoded for the moment
        // for easier testing execution         
        let packOpenerRef = getAccount(0xf8d6e0586b0a20c7)
        .getCapability(WnWAlphaPacks.PackOpenerPublicPath)
        .borrow<&{TradingFungiblePack.PackOpener}>() 
        ?? panic("Bad seller address")

        packOpenerRef.openPacks(packsToOpen: <- self.packsToOpen, owner: self.packsOwnerAddress)
    }
}
 