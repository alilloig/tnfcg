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
    
    // CardsMinted
    //
    // The event that is emitted when new Packs are minted
    pub event CardMinted(id: UInt64)

    //No, no?
    // PacksBurned
    //
    // The event that is emitted when Packs are destroyed
    pub event CardBurned(id: UInt64)

    /// Pack fullfiller
    ///
    /// The interface that enforces the requirements for opening Packs
    ///
    /// We do not include a condition that checks the balance because
    /// we want to give users the ability to make custom receivers that
    /// can do custom things with the Packs, like split them up and
    /// send them to different places.
    ///
    pub resource interface PackFullfiller{
        /// openPacks takes a Vault and destroys it returning the number of opened packs
        ////*packsToOpen: @FungibleToken.Vault,*/
        pub fun fullfilPacks(packOwner: Address): {Address: UFix64}
    }   


}