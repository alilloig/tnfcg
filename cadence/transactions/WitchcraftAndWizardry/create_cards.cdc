import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import WnW from 0xf8d6e0586b0a20c7

// 
//
// 
// 
transaction(metadatas: [{String: String}]) {

    // 
    let cardCreator: &WnW.CardCreator

    prepare(signer: AuthAccount) {
        // borrow a reference to the  resource in storage
        self.cardCreator = signer.borrow<&WnW.CardCreator>(from: WnW.CardCreatorStoragePath)
            ?? panic("Could not borrow a reference to the Card Creator")
    }

    execute {
        // Creates the set
        self.cardCreator.batchCreateNewCards(metadatas: metadatas)
    }
}