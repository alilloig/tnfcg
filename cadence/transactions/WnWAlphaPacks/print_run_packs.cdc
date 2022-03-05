//import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
import WnWAlphaPacks from 0xf8d6e0586b0a20c7

transaction(quantity: UInt64) {
    
    let alphaPrinter: &WnWAlphaPacks.PackPrinter


    prepare(signer: AuthAccount) {

        // Check if the signer is the WnWAlphaPacks Admin
        self.alphaPrinter = signer.borrow<&WnWAlphaPacks.PackPrinter>(from: WnWAlphaPacks.PackPrinterStoragePath)
            ?? panic("Signer is not the WnW Alpha packs printer")


    }

    execute {
        self.alphaPrinter.printRun(quantity: quantity)
    }
}