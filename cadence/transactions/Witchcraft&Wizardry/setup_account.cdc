import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import WnW from "../../contracts/Witchcraft&Wizardry.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import WnW from 0xf8d6e0586b0a20c7

// This transaction configures an account to hold Kitty Items.

transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a collection
        if signer.borrow<&WnW.Collection>(from: WnW.PrintedCardsStoragePath) == nil {

            // create a new empty collection
            let collection <- WnW.createEmptyCollection()
            
            // save it to the account
            signer.save(<-collection, to: WnW.PrintedCardsStoragePath)

            // create a public capability for the collection
            signer.link<&WnW.Collection{NonFungibleToken.CollectionPublic, WnW.WnWCollectionPublic}>(WnW.PrintedCardsPublicPath, target: WnW.PrintedCardsStoragePath)
        }
    }
}
