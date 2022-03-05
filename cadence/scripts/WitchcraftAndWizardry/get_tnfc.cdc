//import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import NonFungibleToken from 0xf8d6e0586b0a20c7
import WnW from 0xf8d6e0586b0a20c7

pub struct AccountItem {
  pub let itemID: UInt64
  pub let resourceID: UInt64
  pub let owner: Address

  init(itemID: UInt64, resourceID: UInt64, owner: Address) {
    self.itemID = itemID
    self.resourceID = resourceID
    self.owner = owner
  }
}

pub fun main(address: Address, itemID: UInt64): AccountItem? {
  if let collection = getAccount(address).getCapability<&WnW.Collection{NonFungibleToken.CollectionPublic, WnW.WnWCollectionPublic}>(WnW.OwnedCardsCollectionPublicPath).borrow() {
    if let item = collection.borrowTNFC(id: itemID) {
      return AccountItem(itemID: itemID, resourceID: item.uuid, owner: address)
    }
  }

  return nil
}
