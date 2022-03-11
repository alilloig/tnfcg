//import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import NonFungibleToken from 0xf8d6e0586b0a20c7
import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
import WnW from 0xf8d6e0586b0a20c7

// This script returns an array of all the NFT IDs in an account's collection.
pub struct TNFC {
  pub let ID: UInt64
  pub let resourceID: UInt64
  pub let owner: Address
  pub let rarity: UInt8
  pub let card: UInt32

  init(ID: UInt64, resourceID: UInt64, owner: Address, rarity: UInt8, card: UInt32) {
    self.ID = ID
    self.resourceID = resourceID
    self.owner = owner
    self.rarity = rarity
    self.card = card
  }
}

pub fun main(tnfcID: UInt64): TNFC{
    let account = getAccount(0xf8d6e0586b0a20c7)

    let collectionRef = account.getCapability(WnW.PrintedTNFCsPublicTNFCGCollectionPath).borrow<&{WnW.WnWCollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    let tnfc = collectionRef.borrowTNFC(id: tnfcID) ?? panic("No such TNFC in printed TNFCs")

    let rarity = tnfc.data.rarityID

    let card = tnfc.data.cardID

    return TNFC(ID: tnfcID, resourceID: tnfc.uuid, owner: 0xf8d6e0586b0a20c7, rarity: rarity, card: card)
}