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

pub fun main(address: Address): [TNFC]{
    let account = getAccount(address)

    let collectionRef = account.getCapability(WnW.OwnedTNFCsCollectionPublicPath).borrow<&{WnW.WnWCollectionPublic, NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    var tnfcCollection:[TNFC] = []

    let collectionIDs = collectionRef.getIDs()
    
    for ID in collectionIDs{
      
      let tnfc = collectionRef.borrowTNFC(id: ID) ?? panic("No such TNFC in printed TNFCs")

      let rarity = tnfc.data.rarityID

      let card = tnfc.data.cardID

      tnfcCollection.append(TNFC(ID: ID, resourceID: tnfc.uuid, owner: address, rarity: rarity, card: card))

    }
  
    return tnfcCollection
}