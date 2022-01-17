import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import TNFCGCards from "../../contracts/TNFCGCards.cdc"

// This script returns the size of an account's TNFCGCards collection.

pub fun main(address: Address): Int {
    let account = getAccount(address)

    let collectionRef = account.getCapability(TNFCGCards.CollectionPublicPath)!
        .borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.getIDs().length
}
