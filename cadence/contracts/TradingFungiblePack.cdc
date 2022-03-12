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

The admin only access resource that can accept TFP to call TNFCG.fulfilPacks()
and asign the user NFTs to be lately distributed

*/

/// TradingFungiblePack
///
/// The interface that fungible Pack contracts implement.
///
pub contract interface TradingFungiblePack {

    // -----------------------------------------------------------------------
    // TradingFungiblePack contract interface Events
    // -----------------------------------------------------------------------
    
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

     // -----------------------------------------------------------------------
    // TFP contract-level fields.
    // These contain actual values that are stored in the smart contract.
    // -----------------------------------------------------------------------   
    
    // Total supply of Packs in existence
    pub var totalSupply: UFix64
    // Amount of packs remaining for selling
    pub var packsToSell: UInt64
    // Amount of packs selled that hasn't been opened
    pub var packsToOpen: UInt64

    // Id from the set the packs belongs to
    pub let setID: UInt32

    // Info of the pack
    pub let TFPackInfo: {PackInfo}

    // -----------------------------------------------------------------------
    // Trading Fungible Card interface contract-level Composite Type definitions
    // -----------------------------------------------------------------------

    // PackInfo
    // When the TradingFungiblePack contract is initialized and the PackInfo is 
    // created, printingPacksAmount and printingRaritiesSheetsQuantities should
    // be calculated in fuction of the pack's set's raritiesDistribution
    pub struct interface PackInfo {
        pub let packID: UInt8
        pub let packRaritiesDistribution: {UInt8: UFix64}
        // Indicates how many packs includes each printing
        pub let printingPacksAmount: UInt64
        // A sheet represents 1 TNFC of each card in a set at a certain rarity
        // this stores how many sheets peer rarity need to be printed for each
        // printing
        pub let printingRaritiesSheetsQuantities: {UInt8: UInt64}
        pub let price: UFix64
    }


    // -----------------------------------------------------------------------
    // TradingFungiblePack contract admin resources
    // -----------------------------------------------------------------------

    /// PackPrinter
    // The interface to allow minting packs and calling the TNFCG to create the 
    // needed NFTs
    pub resource interface PackPrinter{
        // The remaining amount of Packs that the PackPrinterr is allowed to mint
        pub var allowedAmount: UInt64
        // printRun() calls the TNFCG set.printRun() and keeps in check the 
        // distributed amount of packs
        //
        // Post-Conditions:
        // The total amount of packs, determined by the quantity of printings
        // and the amount of packs per printing, should be less than the remaining
        // amount of packs to distribute. The allowedAmount should be recuced
        // accordly
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
        // sellPacks() through a public capability allow users to get packs in 
        // exchange for a payment made with a FungibleToken Vault
        //
        // Pre-Conditions:
        // The amount of packs buyed should be 1 or greater and should be an 
        // integer amount of packs despite packs beeing also Fungible Tokens
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
    pub resource interface PackOpener{
        // openPacks() through a public capability allow users to send back their
        // packs to get TNFCs. Originally this function will take a public capability
        // to a TNFC Collection and pass it to fulfilPacks todeposit the opened TNFCs. 
        // To avoid malicius users getting to check which cards they open and beeing 
        // able to abort the transaction, the actual transfer of TNFCs is done by
        // retrieveTNFCs in the TNFCG.
        //
        // Pre-Conditions:
        // The amount of packs buyed should be 1 or greater and should be an 
        // integer amount of packs despite packs beeing also Fungible Tokens
        pub fun openPacks(packsToOpen: @FungibleToken.Vault, owner: Address){
                pre{
                    packsToOpen.balance > 0.0: "Amount opened must be greater than zero"
                    packsToOpen.balance % 1.0 == 0.0: "You cannot open fractions of packs"
                }
            }
    }

}   
 