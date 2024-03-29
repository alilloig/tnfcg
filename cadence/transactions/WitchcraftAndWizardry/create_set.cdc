//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import WnW from 0xf8d6e0586b0a20c7

// 

transaction(name: String, rarities: {UInt8: String}) {
    // local variable for storing the set manager reference
    let setManagerRef: &WnW.SetManager

    prepare(signer: AuthAccount) {
        // borrow a reference to the SetManager resource in storage
        self.setManagerRef = signer.borrow<&WnW.SetManager>(from: WnW.SetManagerStoragePath)
            ?? panic("Could not borrow a reference to the Set Manager")
    }

    execute {
        // Creates the set
        self.setManagerRef.createSet(name: name, rarities: rarities)
    }
}