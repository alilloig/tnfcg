//import NonFungibleToken from "./NonFungibleToken.cdc"
//import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xf8d6e0586b0a20c7

/**

# The Flow Trading Fungible Pack standard

## `TradingFungiblePack` contract interface

The interface that all fungible Pack contracts would have to conform to.
If a users wants to deploy a new Pack contract, their contract
would need to implement the TradingFungiblePack and FungibleToken interfaces.

Their contract would have to follow all the rules and naming
that the interface specifies.

## PackPrinter

The admin only access resource that can allow packs to be minted and is 
responsible for calling the set print run function in the TNFCG 

## PackSeller

The admin only access resource that can mint packs into users vaults

## Pack Opener

The admin only access resource that can accept TFP to return the TNFCs provided 
by the TNFCG fulfilPacks function.

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

    // PacksDestroyed
    //
    // The event that is emitted when Packs are destroyed
    pub event PacksDestroyed(amount: UFix64)

    // PackManagerCreated
    //
    // The event that is emitted when a new PackSeller resource is created
    pub event PackManagerCreated()

    // PackSellerCreated
    //
    // The event that is emitted when a new PackSeller resource is created
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

    // Info of the pack
    pub let TFPackInfo: {PackInfo}

    // PackInfo
    pub struct interface PackInfo {
        pub let packID: UInt8
        pub let packRaritiesDistribution: {UInt8: UFix64}
        pub let printingPacksAmount: UInt64
        pub let printingRaritiesSheetsQuantities: {UInt8: UInt64}
        pub let price: UFix64
    }


    /// PackPrinter
    // The interface to allow minting packs and calling the TNFCG to create the 
    // needed NFTs
    pub resource interface PackPrinter{
        // The remaining amount of Packs that the PackPrinterr is allowed to mint
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
    /// We define a very specific provider requesting a payment in the form of
    /// some sort of FungibleToken vault. Pre conditions assure that packs are 
    /// sold in units but not fractions
    ///
    pub resource interface PackSeller{
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
    /// We define a very specific receiver that asks for a Fungible Token vault
    /// that will contain the TFP and a NFT collection for depositing the obtained
    /// NFTs
    ///
    pub resource interface PackOpener{
        pub fun openPacks(
            packsToOpen: @FungibleToken.Vault,
            packsOwnerCardCollectionPublic: &{NonFungibleToken.CollectionPublic}){
                pre{
                    packsToOpen.balance > 0.0: "Amount opened must be greater than zero"
                    packsToOpen.balance % 1.0 == 0.0: "You cannot open fractions of packs"
                }
            }
    }

}   
 