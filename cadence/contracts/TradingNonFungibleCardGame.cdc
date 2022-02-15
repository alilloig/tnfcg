import NonFungibleToken from "./NonFungibleToken.cdc"
import FungibleToken from "./FungibleToken.cdc"
import TradingFungiblePack from "./TradingFungiblePack.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import FungibleToken from 0xf8d6e0586b0a20c7
//import TradingFungiblePack from 0xf8d6e0586b0a20c7

/**

## The Flow Trading Non-Fungible Card standard

## `NonFungibleToken` contract interface

The interface that all non-fungible token contracts could conform to.
If a user wants to deploy a new nft contract, their contract would need
to implement the NonFungibleToken interface.

Their contract would have to follow all the rules and naming
that the interface specifies.

## `NFT` resource

The core resource type that represents an NFT in the smart contract.

## `Collection` Resource

The resource that stores a user's NFT collection.
It includes a few functions to allow the owner to easily
move tokens in and out of the collection.

## `Provider` and `Receiver` resource interfaces

These interfaces declare functions with some pre and post conditions
that require the Collection to follow certain naming and behavior standards.

They are separate because it gives the user the ability to share a reference
to their Collection that only exposes the fields and functions in one or more
of the interfaces. It also gives users the ability to make custom resources
that implement these interfaces to do various things with the tokens.

By using resources and interfaces, users of NFT smart contracts can send
and receive tokens peer-to-peer, without having to interact with a central ledger
smart contract.

To send an NFT to another user, a user would simply withdraw the NFT
from their Collection, then call the deposit function on another user's
Collection to complete the transfer.

*/

// The main NFT contract interface. Other NFT contracts will
// import and implement this interface
//
pub contract interface TradingNonFungibleCardGame {
    
    // PacksFulfiled
    //
    // The event that is emitted when Packs are fulfiled
    pub event PacksFulfiled(amount: UFix64)

    // PackFulfilerCreated
    //
    // The event that is emitted when a new PackFulfiler resource is created
    pub event PackFulfilerCreated(allowedAmount: UFix64)

    pub struct interface SetInfo {
        pub let name: String
        pub let id: UInt64
        pub let printing: Bool
        pub let rarities: {UInt8: String}
    }

    pub struct interface CardInfo {
        pub let cardID: UInt32
        pub let set: {SetInfo}
        pub let name: String
        pub let rarity: UInt8
        pub let rules: {String: String}
        pub let metadata: {String: String}
    }


    pub resource interface TradingNonFungibleCard{
        pub let card: {CardInfo}
    }

    pub resource interface Set{

    }


    /// Set Starter
    ///
    /// The interface that enforces the requirements for starting a new set
    ///
    pub resource interface SetInitializer{
        /// openPacks takes a Vault and destroys it returning the number of opened packs
        //pub fun startSet(set: {SetInfo}, printedCardsCollectionPublic: &{NonFungibleToken.CollectionPublic})
    }

    /// Set PrintRunner
    ///
    /// The interface that enforces the requirements for creating new copies of the cards in a set
    ///
    pub resource interface SetPrintRunner{
        /// this should create a number of NFTs depending on the number of packs createds
        //pub fun printRun(set: {SetInfo}, printedCardsCollectionPublic: &{NonFungibleToken.CollectionPublic})
    }


    /// Pack fulfiler
    ///
    /// The interface that enforces the requirements for opening Packs
    ///
    pub resource interface PackFulfiler{
        /// openPacks takes a Vault and destroys it returning the number of opened packs
        pub fun fulfilPacks(set: {SetInfo}, amount: UFix64, packsOwnerCardCollectionPublic: &{NonFungibleToken.CollectionPublic})
    }   


}