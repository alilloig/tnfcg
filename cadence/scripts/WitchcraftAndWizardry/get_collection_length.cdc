import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import WnW from 0xf8d6e0586b0a20c7

// This script returns the size of an account's TNFCGCards collection.

pub fun main(address: Address): Int {
    let account = getAccount(address)

    let collectionRef = account.getCapability(WnW.OwnedCardsCollectionPublicPath)!
        .borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.getIDs().length
}
