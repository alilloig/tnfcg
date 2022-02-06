import FungibleToken from "./FungibleToken.cdc"

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
    
    // PacksMinted
    //
    // The event that is emitted when new Packs are minted
    pub event PacksMinted(amount: UFix64)

    // PacksBurned
    //
    // The event that is emitted when Packs are destroyed
    pub event PacksBurned(amount: UFix64)

    // PackMinterCreated
    //
    // The event that is emitted when a new PackMinter resource is created
    pub event PackMinterCreated(allowedAmount: UFix64)

    // PackOpenerCreated
    //
    // The event that is emitted when a new opener resource is created
    pub event PackOpenerCreated(allowedAmount: UFix64)

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
        /// openPacks takes a Vault and destroys it returning the number of opened packs
        ///
        pub fun openPacks(packsToOpen: @FungibleToken.Vault, packOwner: Address): {Address: UFix64}
    }  
}   
 