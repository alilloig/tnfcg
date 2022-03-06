//import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
//import TradingNonFungibleCardGame from "../../contracts/TradingNonFungibleCardGame.cdc"
//import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import TradingFungiblePack from 0xf8d6e0586b0a20c7
import WnWAlphaPacks from 0xf8d6e0586b0a20c7
import WnW from 0xf8d6e0586b0a20c7
import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7


// Tx para setear el packprinter

transaction (maxPrinterPrintings: UInt64){

    let alphaAdmin: &WnWAlphaPacks.Administrator

    prepare(signer: AuthAccount) {

        // Check if the signer is the WnWAlphaPacks Admin
        self.alphaAdmin = signer.borrow<&WnWAlphaPacks.Administrator>(from: WnWAlphaPacks.AdminStoragePath)
            ?? panic("Signer is not the WnW Alpha packs admin")

        //if the account doesn't already have a PackPrinter
        if signer.borrow<&WnWAlphaPacks.PackPrinter>(from: WnWAlphaPacks.PackPrinterStoragePath) == nil {
            //Create a PackPrinter resource
            signer.save(
                <- self.alphaAdmin.createNewPackPrinter(
                    allowedAmount: maxPrinterPrintings * WnWAlphaPacks.TFPackInfo.printingPacksAmount,
                    printRunnerCapability: 
                        signer.getCapability<&{TradingNonFungibleCardGame.SetPrintRunner}>(WnW.SetPrintRunnerPrivatePath)),
                to: WnWAlphaPacks.PackPrinterStoragePath)

            // Expose a private capability allowing admin to create new packs
            signer.link<&{TradingFungiblePack.PackPrinter}>(
                WnWAlphaPacks.PackPrinterPrivatePath,
                target: WnWAlphaPacks.PackPrinterStoragePath
            )
        }

    }
}
 