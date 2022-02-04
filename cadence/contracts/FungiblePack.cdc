/**

# The Flow Fungible Pack standard

## `FungiblePack` contract interface

The interface that all fungible Pack contracts would have to conform to.
If a users wants to deploy a new Pack contract, their contract
would need to implement the FungiblePack interface.

Their contract would have to follow all the rules and naming
that the interface specifies.

## `Vault` resource

Each account that owns Packs would need to have an instance
of the Vault resource stored in their account storage.

The Vault resource has methods that the owner and other users can call.

## `Provider`, `Receiver`, and `Balance` resource interfaces

These interfaces declare pre-conditions and post-conditions that restrict
the execution of the functions in the Vault.

They are separate because it gives the user the ability to share
a reference to their Vault that only exposes the fields functions
in one or more of the interfaces.

It also gives users the ability to make custom resources that implement
these interfaces to do various things with the Packs.
For example, a faucet can be implemented by conforming
to the Provider interface.

By using resources and interfaces, users of FungiblePack contracts
can send and receive Packs peer-to-peer, without having to interact
with a central ledger smart contract. To send Packs to another user,
a user would simply withdraw the Packs from their Vault, then call
the deposit function on another user's Vault to complete the transfer.

*/

/// FungiblePack
///
/// The interface that fungible Pack contracts implement.
///
pub contract interface FungiblePack {

    /// The total number of Packs in existence.
    /// It is up to the implementer to ensure that the total supply
    /// stays accurate and up to date
    ///
    pub var totalSupply: UInt256

    /// PacksInitialized
    ///
    /// The event that is emitted when the contract is created
    ///
    pub event PacksInitialized(initialSupply: UInt256)

    /// PacksWithdrawn
    ///
    /// The event that is emitted when Packs are withdrawn from a Vault
    ///
    pub event PacksWithdrawn(amount: UInt256, from: Address?)

    /// PacksDeposited
    ///
    /// The event that is emitted when Packs are deposited into a Vault
    ///
    pub event PacksDeposited(amount: UInt256, to: Address?)


    /// Provider
    ///
    /// The interface that enforces the requirements for withdrawing
    /// Packs from the implementing type.
    ///
    /// It does not enforce requirements on `balance` here,
    /// because it leaves open the possibility of creating custom providers
    /// that do not necessarily need their own balance.
    ///
    pub resource interface Provider {

        /// withdraw subtracts Packs from the owner's Vault
        /// and returns a Vault with the removed Packs.
        ///
        /// The function's access level is public, but this is not a problem
        /// because only the owner storing the resource in their account
        /// can initially call this function.
        ///
        /// The owner may grant other accounts access by creating a private
        /// capability that allows specific other users to access
        /// the provider resource through a reference.
        ///
        /// The owner may also grant all accounts access by creating a public
        /// capability that allows all users to access the provider
        /// resource through a reference.
        ///
        pub fun withdraw(amount: UInt256): @Vault {
            post {
                // `result` refers to the return value
                result.balance == amount:
                    "Withdrawal amount must be the same as the balance of the withdrawn Vault"
            }
        }
    }

    /// Receiver
    ///
    /// The interface that enforces the requirements for depositing
    /// Packs into the implementing type.
    ///
    /// We do not include a condition that checks the balance because
    /// we want to give users the ability to make custom receivers that
    /// can do custom things with the Packs, like split them up and
    /// send them to different places.
    ///
    pub resource interface Receiver {
        /// deposit takes a Vault and deposits it into the implementing resource type
        ///
        pub fun deposit(from: @Vault)
    }

    /// Balance
    ///
    /// The interface that contains the `balance` field of the Vault
    /// and enforces that when new Vaults are created, the balance
    /// is initialized correctly.
    ///
    pub resource interface Balance {

        /// The total balance of a vault
        ///
        pub var balance: UInt256

        init(balance: UInt256) {
            post {
                self.balance == balance:
                    "Balance must be initialized to the initial balance"
            }
        }
    }

    /// Vault
    ///
    /// The resource that contains the functions to send and receive Packs.
    ///
    pub resource Vault: Provider, Receiver, Balance {

        // The declaration of a concrete type in a contract interface means that
        // every Fungible Pack contract that implements the FungiblePack interface
        // must define a concrete `Vault` resource that conforms to the `Provider`, `Receiver`,
        // and `Balance` interfaces, and declares their required fields and functions

        /// The total balance of the vault
        ///
        pub var balance: UInt256

        // The conforming type must declare an initializer
        // that allows prioviding the initial balance of the Vault
        //
        init(balance: UInt256)

        /// withdraw subtracts `amount` from the Vault's balance
        /// and returns a new Vault with the subtracted balance
        ///
        pub fun withdraw(amount: UInt256): @Vault {
            pre {
                self.balance >= amount:
                    "Amount withdrawn must be less than or equal than the balance of the Vault"
            }
            post {
                // use the special function `before` to get the value of the `balance` field
                // at the beginning of the function execution
                //
                self.balance == before(self.balance) - amount:
                    "New Vault balance must be the difference of the previous balance and the withdrawn Vault"
            }
        }

        /// deposit takes a Vault and adds its balance to the balance of this Vault
        ///
        pub fun deposit(from: @Vault) {
            post {
                self.balance == before(self.balance) + before(from.balance):
                    "New Vault balance must be the sum of the previous balance and the deposited Vault"
            }
        }
    }

    /// createEmptyVault allows any user to create a new Vault that has a zero balance
    ///
    pub fun createEmptyVault(): @Vault {
        post {
            result.balance == 0: "The newly created Vault must have zero balance"
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
        /// openPacks takes a Vault and destroys it returning the number of opened packs
        ///
        pub fun openPacks(packsToOpen: @Vault, packOwner: Address): {Address: UInt256}
    }  
}   
 