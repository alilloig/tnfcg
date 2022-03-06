//import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import NonFungibleToken from 0xf8d6e0586b0a20c7
import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
import WnW from 0xf8d6e0586b0a20c7

// This script returns an array of all the NFT IDs in an account's collection.

pub fun main(): [UInt64] {
    let account = getAccount(0xf8d6e0586b0a20c7)

    let collectionRef = account.getCapability(WnW.PrintedCardsTNFCGCollectionPath).borrow<&{TradingNonFungibleCardGame.TNFCGCollection}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.getIDs()
}
