import NonFungibleToken from "./NonFungibleToken.cdc"
import FungibleToken from "./FungibleToken.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import FungibleToken from 0xf8d6e0586b0a20c7
//import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7

/**

# The Flow Trading Fungible Pack standard

## `TradingFungiblePack` contract interface

The interface that all fungible Pack contracts would have to conform to.
If a users wants to deploy a new Pack contract, their contract
would need to implement the TradingFungiblePack interface.

Their contract would have to follow all the rules and naming
that the interface specifies.

## Set Data?
## Pack Opener



*/

/// TradingFungiblePack
///
/// The interface that fungible Pack contracts implement.
///
pub contract interface TradingFungiblePack {
    
    // PacksSelled
    //
    // The event that is emitted when Packs are destroyed
    pub event PacksSelled(amount: UFix64)

    // PacksDestroyedgit
    //
    // The event that is emitted when Packs are destroyed
    pub event PacksDestroyedgit(amount: UFix64)

    // PackMinterCreated
    //
    // The event that is emitted when a new PackMinter resource is created
    pub event PackSellerCreated(allowedAmount: UFix64)

    // PackOpenerCreated
    //
    // The event that is emitted when a new opener resource is created
    pub event PackOpenerCreated(allowedAmount: UFix64)

    // Id from the set the packs belongs to
    pub let setID: UInt32

    pub let TFPackInfo: {PackInfo}

    pub struct interface PackInfo {
        pub let packID: UInt8
        pub let packRaritiesDistribution: {UInt8: UInt}
        pub let packPrintingSize: UInt
        pub let raritiesSheetsPrintingSize: {UInt8: UInt}
    }

    /// Pack Setter
    ///
    /// The interface that enforces the requirements for opening Packs
    ///
    /// We do not include a condition that checks the balance because
    /// we want to give users the ability to make custom receivers that
    /// can do custom things with the Packs, like split them up and
    /// send them to different places.
    ///
    pub resource interface PackSetter{
        pub fun createPackInfo(): {PackInfo}
    }

    /// Pack Seller
    ///
    /// The interface that enforces the requirements for opening Packs
    ///
    /// We do not include a condition that checks the balance because
    /// we want to give users the ability to make custom receivers that
    /// can do custom things with the Packs, like split them up and
    /// send them to different places.
    ///
    pub resource interface PackSeller{
        // The amount of Packs that the PackMinter is allowed to mint
        pub var allowedAmount: UFix64
        /// sellPacks takes a Vault with Flow currency and returns a Vault of TFP
        pub fun sellPacks(
            payment: &FungibleToken.Vault,
            packsPayerPackReceiver: &{FungibleToken.Receiver},
            amount: UFix64){
                pre{
                    amount > 0.0: "Amount selled must be greater than zero"
                    amount % 1.0 == 0.0: "You cannot buy fractions of packs"
                }
            }
    }

    /// Pack Opener
    ///
    /// The interface that enforces the requirements for opening Packs
    ///
    /// We do not include a condition that checks the balance because
    /// we want to give users the ability to make custom receivers that
    /// can do custom things with the Packs, like split them up and
    /// send them to different places.
    ///
    pub resource interface PackOpener{
        // The amount of Packs that the PackMinter is allowed to mint
        pub var allowedAmount: UFix64
        /// openPacks takes a Vault and destroys it returning the collection containing the opened cards
        ///
        pub fun openPacks(
            packsToOpen: &FungibleToken.Vault,
            packsOwnerCardCollectionPublic: &{NonFungibleToken.CollectionPublic}){
                pre{
                    packsToOpen.balance > 0.0: "Amount opened must be greater than zero"
                    packsToOpen.balance % 1.0 == 0.0: "You cannot open fractions of packs"
                }
            }
    }

}   
 