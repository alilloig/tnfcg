//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import WnW from 0xf8d6e0586b0a20c7

// 

transaction(owner: Address) {
    // local variable for storing the set manager reference
    let setPackFulfilerRef: &WnW.SetPackFulfiler

    prepare(signer: AuthAccount) {
        // borrow a reference to the SetPackFulfiler resource in storage
        self.setPackFulfilerRef = signer.borrow<&WnW.SetPackFulfiler>(from: WnW.SetPackFulfilerStoragePath)
            ?? panic("Could not borrow a reference to the Set Manager")
    }

    execute {
        // Creates the set
        self.setPackFulfilerRef.retrieveTNFCs(owner: owner)
    }
}