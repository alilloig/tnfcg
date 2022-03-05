//import FungibleToken from "../../contracts/FungibleToken.cdc"
//import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
//import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import FungibleToken from 0xf8d6e0586b0a20c7
import TradingFungiblePack from 0xf8d6e0586b0a20c7
import WnWAlphaPacks from 0xf8d6e0586b0a20c7
import WnW from 0xf8d6e0586b0a20c7


// Tx para setear el packSeller

transaction (){

    let alphaAdmin: &WnWAlphaPacks.Administrator

    prepare(signer: AuthAccount) {

        // Check if the signer is the WnWAlphaPacks Admin
        self.alphaAdmin = signer.borrow<&WnWAlphaPacks.Administrator>(from: WnWAlphaPacks.AdminStoragePath)
            ?? panic("Signer is not the WnW Alpha packs admin")

        //if the account doesn't already have a PackSeller
        if signer.borrow<&{TradingFungiblePack.PackSeller}>(from: WnWAlphaPacks.PackSellerStoragePath) == nil {
            signer.save(
                <- self.alphaAdmin.createNewPackSeller(
                    packSellerFlowTokenCapability: signer.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)),
                to: WnWAlphaPacks.PackSellerStoragePath)

            // Expose a public capability allowing users to buy packs
            signer.link<&WnWAlphaPacks.PackSeller>(
                WnWAlphaPacks.PackSellerPublicPath,
                target: WnWAlphaPacks.AdminStoragePath
            )
        }

    }
}