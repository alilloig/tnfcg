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
    pub event PacksDestroyed(amount: UFix64)

    // PackSellerCreated
    //
    // The event that is emitted when a new PackSeller resource is created
    pub event PackManagerCreated()

    // PackMinterCreated
    //
    // The event that is emitted when a new PackMinter resource is created
    pub event PackSellerCreated()

    // PackOpenerCreated
    //
    // The event that is emitted when a new opener resource is created
    pub event PackOpenerCreated()

    // PackPrinterCreated
    //
    // The event that is emitted when a new opener resource is created
    pub event PackPrinterCreated(allowedAmount: UInt64)

    // Id from the set the packs belongs to
    pub let setID: UInt32

    pub let TFPackInfo: {PackInfo}

    pub struct interface PackInfo {
        pub let packID: UInt8
        pub let packRaritiesDistribution: {UInt8: UFix64}
        pub let printingPacksAmount: UInt64
        pub let printingRaritiesSheetsQuantities: {UInt8: UInt64}
        pub let price: UFix64
    }


    /// PackCreator
    // The interface pa crear packs en el set y que se impriman los nfts
    pub resource interface PackPrinter{
        // The remaining amount of Packs that the PackCrafter is allowed to mint
        pub var allowedAmount: UInt64
        // printRun creates in the TNFCG contract the necessary amount of NFTs
        // to fulfil the pack amount equal to the printRun times the printed print quantity quantity
        pub fun printRun(quantity: UInt64): UInt64{
            post{
                result <= before(self.allowedAmount): "The sum of the desired prints exceeds the allowed amount"
                self.allowedAmount == before(self.allowedAmount) - result: "The printer's allowed amount must be reduced"
            }
        }
        
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
        /// sellPacks takes a Vault with Flow currency and returns a Vault of TFP
        pub fun sellPacks(
            payment: @FungibleToken.Vault,
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
 