//import FungibleToken from "../../contracts/FungibleToken.cdc"
//import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
//import TradingNonFungibleCardGame from "../../contracts/TradingNonFungibleCardGame.cdc"
//import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
//import FlowToken from "../../contracts/FlowToken.cdc"
import FlowToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xf8d6e0586b0a20c7
import TradingFungiblePack from 0xf8d6e0586b0a20c7
import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
import WnWAlphaPacks from 0xf8d6e0586b0a20c7
import WnW from 0xf8d6e0586b0a20c7


// Tx para setear el admin

transaction() {
    let alphaAdmin: &WnWAlphaPacks.Administrator

    prepare(signer: AuthAccount) {

        // Check if the signer is the WnWAlphaPacks Admin
        self.alphaAdmin = signer.borrow<&WnWAlphaPacks.Administrator>(from: WnWAlphaPacks.AdminStoragePath)
            ?? panic("Signer is not the WnW Alpha packs admin")

        //if the account doesn't already have a PackSeller
        if signer.borrow<&WnWAlphaPacks.PackSeller>(from: WnWAlphaPacks.PackSellerStoragePath) == nil {
            signer.save(
                <- self.alphaAdmin.createNewPackSeller(
                    packSellerFlowTokenCapability: 
                        signer.getCapability<&{FungibleToken.Receiver}>(FlowToken.ReceiverPublicPath)),
                to: WnWAlphaPacks.PackSellerStoragePath)

            // Expose a public capability allowing users to buy packs
            signer.link<&WnWAlphaPacks.PackSeller{TradingFungiblePack.PackSeller}>(
                WnWAlphaPacks.PackSellerPublicPath,
                target: WnWAlphaPacks.PackSellerStoragePath
            )
        }

        //if the account doesn't already have a PackOpener
        if signer.borrow<&WnWAlphaPacks.PackOpener>(from: WnWAlphaPacks.PackOpenerStoragePath) == nil {
            signer.save(
                <- self.alphaAdmin.createNewPackOpener(
                    packFulfilerCapability: 
                        signer.getCapability<&{TradingNonFungibleCardGame.SetPackFulfiler}>(WnW.SetPackFulfilerPrivatePath)),
                to: WnWAlphaPacks.PackOpenerStoragePath)
            
            // Expose a public capability allowing users to open packs, sending it to the account and receiving WnW TNFCs
            signer.link<&WnWAlphaPacks.PackOpener{TradingFungiblePack.PackOpener}>(
                WnWAlphaPacks.PackOpenerPublicPath,
                target: WnWAlphaPacks.PackOpenerStoragePath
            )
        }
    }
}
 