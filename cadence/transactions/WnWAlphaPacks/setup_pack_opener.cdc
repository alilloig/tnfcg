//import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
//import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import TradingFungiblePack from 0xf8d6e0586b0a20c7
import WnWAlphaPacks from 0xf8d6e0586b0a20c7
import WnW from 0xf8d6e0586b0a20c7


// Tx para setear el packOpener

transaction (){

    let alphaAdmin: &WnWAlphaPacks.Administrator

    prepare(signer: AuthAccount) {

        // Check if the signer is the WnWAlphaPacks Admin
        self.alphaAdmin = signer.borrow<&WnWAlphaPacks.Administrator>(from: WnWAlphaPacks.AdminStoragePath)
            ?? panic("Signer is not the WnW Alpha packs admin")

        //if the account doesn't already have a PackOpener
        if signer.borrow<&{TradingFungiblePack.PackOpener}>(from: WnWAlphaPacks.PackOpenerStoragePath) == nil {
            signer.save(
                <- self.alphaAdmin.createNewPackOpener(
                    packFulfilerCapability: signer.getCapability<&WnW.SetPackFulfiler>(WnW.SetPrintRunnerPrivatePath)),
                to: WnWAlphaPacks.PackOpenerStoragePath)
            
            // Expose a public capability allowing users to open packs, sending it to the account and receiving WnW cards
            signer.link<&WnWAlphaPacks.PackOpener>(
                WnWAlphaPacks.PackOpenerPublicPath,
                target: WnWAlphaPacks.AdminStoragePath
            )
        }

    }
}