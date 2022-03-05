//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import WnW from 0xf8d6e0586b0a20c7

// This transction uses the NFTMinter resource to mint a new NFT.
//
// It must be run with the account that has the minter resource
// stored at path /storage/NFTMinter.

transaction(name: String, rarities: {UInt8: String}) {
    //esta transaccion emberda tiene que ser la que reciba sobres de recipient y devuelva cartas

    // local variable for storing the minter reference
    let setManager: &WnW.SetManager

    prepare(signer: AuthAccount) {

        // borrow a reference to the NFTMinter resource in storage
        self.setManager = signer.borrow<&WnW.SetManager>(from: WnW.SetManagerStoragePath)
            ?? panic("Could not borrow a reference to the Set Manager")
    }

    execute {
        // Creates the set
        self.setManager.createSet(name: name, rarities: rarities)
    }
}