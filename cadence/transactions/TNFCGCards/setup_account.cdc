import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import TNFCGCards from "../../contracts/TNFCGCards.cdc"

// This transaction configures an account to hold Kitty Items.

transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a collection
        if signer.borrow<&TNFCGCards.Collection>(from: TNFCGCards.PrintedCardsStoragePath) == nil {

            // create a new empty collection
            let collection <- TNFCGCards.createEmptyCollection()
            
            // save it to the account
            signer.save(<-collection, to: TNFCGCards.PrintedCardsStoragePath)

            // create a public capability for the collection
            signer.link<&TNFCGCards.Collection{NonFungibleToken.CollectionPublic, TNFCGCards.TNFCGCardsCollectionPublic}>(TNFCGCards.PrintedCardsPublicPath, target: TNFCGCards.PrintedCardsStoragePath)
        }
    }
}
