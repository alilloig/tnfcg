import NonFungibleToken from "./NonFungibleToken.cdc"
import FungibleToken from "./FungibleToken.cdc"

import TradingNonFungibleCardGame from "./TradingNonFungibleCardGame.cdc";

pub contract alphaWTR{

  access(self) var mintedCards: {Uint64: NFT}
  // setCards
  // Diccionario con clave la id de la carta y valor {rareza, CardInfo}
  // Darle unas vueltitas para ver como hacerlo mejor a la hora de decidir cuando reimprimir
  access(self) var setCards: {UInt16: {UInt8, CardInfo}}
  pub struct CardInfo {
    pub let cardID: UInt32
    pub let setID: UInt32
    pub let name: String
    pub let rarity: UInt8
    pub let rules: {String: String}
    pub let metadata: {String: String}

    init(cardID: UInt32, dna: String, name: String) {
      self.templateID = templateID
      self.dna = dna
      self.name = name
    }

  }
  // NFT
  // A card from the set as an NFT
  //
  pub resource NFT: NonFungibleToken.INFT {
    // The token's ID
    pub let id: UInt64
    // The token's card
    pub let data: CardInfo

    // initializer
    //faltan comprobaciones de si esta vacio card templates rollo ?? panic
    init(initID: UInt64, initCardTemplateID: UInt8) {
      self.id = initID
      self.data = self.cardTemplates[initCardTemplateID]
    }
  }

  // NFTMinter
  // Resource that an admin or something similar would own to be
  // able to mint new NFTs
  //
	pub resource NFTMinter {
	  // mintNFT
    // Mints a new NFT with a new ID
	  // and deposit it in the recipients collection using their collection reference
    //
	  access(self) fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64, rarity: UInt8) {
      emit Minted(id: alphaWTR.totalSupply, typeID: typeID)
	    // deposit it in the recipient's account using their reference
	    recipient.deposit(token: <-create alphaWTR.NFT(initID: alphaWTR.totalSupply, initTypeID: typeID))
      alphaWTR.totalSupply = alphaWTR.totalSupply + (1 as UInt64)
	  }
    access(contract) fun mintSET(recipient: &{NonFungibleToken.CollectionPublic}){
      for key in dictionary.keys {
        let value = dictionary[key]!
      }
    }


	}



  // initializer
  //
	init() {
    // Set our named paths
    self.CollectionStoragePath = /storage/alphaWTRCollection
    self.CollectionPublicPath = /public/alphaWTRCollection
    self.MinterStoragePath = /storage/alphaWTRMinter

    // Initialize the total supply
    self.totalSupply = 0
    // Create a Minter resource and save it to storage
    let minter <- create NFTMinter()
    self.account.save(<-minter, to: self.MinterStoragePath)

    emit ContractInitialized()
	}
} 