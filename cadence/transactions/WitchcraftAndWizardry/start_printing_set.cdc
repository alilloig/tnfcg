import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import WnW from 0xf8d6e0586b0a20c7

// 
//
// 
// 
transaction(setID: UInt32, cardIDs: [UInt32], rarity: UInt8) {

    // 
    let setManager: &WnW.SetManager

    prepare(signer: AuthAccount) {
        // borrow a reference to the  resource in storage
        self.setManager = signer.borrow<&WnW.SetManager>(from: WnW.SetManagerStoragePath)
            ?? panic("Could not borrow a reference to the Set Manager")
    }

    execute {
        // Creates the set
        self.setManager.startPrinting(setID: setID)
    }
}