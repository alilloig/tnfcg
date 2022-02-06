//import FungibleToken from 0xf8d6e0586b0a20c7
//import TradingFungiblePack from 0xf8d6e0586b0a20c7
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
//import WnW from 0xf8d6e0586b0a20c7
import FungibleToken from "./FungibleToken.cdc"
import TradingFungiblePack from "./TradingFungiblePack.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import TradingNonFungibleCardGame from "./TradingNonFungibleCardGame.cdc"
import WnW from "./Witchcraft&Wizardry.cdc"


/**

## The Flow Trading Non-Fungible Card Pack standard

## `Pack` resource

The core resource type that represents a Pack in the smart contract.

## `Vault` resource

Each account that owns set packs would need to have an instance
of the Vault resource stored in their account storage.

The Vault resource has methods that the owner and other users can call.

## `PacksProvider`, `PacksReceiver`, and `PacksBalance` resource interfaces

These interfaces declare pre-conditions and post-conditions that restrict
the execution of the functions in the Vault.

They are separate because it gives the user the ability to share
a reference to their Vault that only exposes the fields functions
in one or more of the interfaces.

It also gives users the ability to make custom resources that implement
these interfaces to do various things with the packs.
For example, a faucet can be implemented by conforming
to the Provider interface.

By using resources and interfaces, users of TnFCG contracts
can send and receive packs peer-to-peer, without having to interact
with a central ledger smart contract. To send packs to another user,
a user would simply withdraw the packs from their Vault, then call
the deposit function on another user's Vault to complete the transfer.

*/

pub contract WnWAlphaPacks: FungibleToken, TradingFungiblePack{

    // Total supply of Packs in existence
    pub var totalSupply: UFix64

    // TokensInitialized
    //
    // The event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    // TokensWithdrawn
    //
    // The event that is emitted when Packs are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    // TokensDeposited
    //
    // The event that is emitted when Packs are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

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

    // Named paths
    //
    pub let VaultStoragePath: StoragePath
    pub let ReceiverPublicPath: PublicPath
    pub let BalancePublicPath: PublicPath
    pub let AdminStoragePath: StoragePath
    pub let PackOpenerPublicPath: PublicPath

    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special PackMinter resource needs to be defined to mint
    // new Packs.
    //
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        // The total balance of this vault
        pub var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        // withdraw
        //
        // Function that takes an amount as an argument
        // and withdraws that amount from the Vault.
        //
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        //
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the Packs. The Vault's balance has
        // been consumed and therefore can be destroyed.
        //
        pub fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @WnWAlphaPacks.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
            WnWAlphaPacks.totalSupply = WnWAlphaPacks.totalSupply - self.balance
            if(self.balance > 0.0) {
                emit PacksBurned(amount: self.balance)
            }
        }
    }

    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this Pack type.
    //
    pub fun createEmptyVault(): @Vault {
        return <-create Vault(balance: 0.0)
    }





    pub resource SetAdministrator: TradingFungiblePack.PackOpener{
        // openPacks
        //
        // Function for destroying packs
        //
        pub fun openPacks(packsToOpen: @FungibleToken.Vault, packOwner: Address): @NonFungibleToken.Collection{
            pre {
                packsToOpen.balance > 0.0: "Amount opened must be greater than zero"
            }
            let amountOpenedPacks: UFix64 = packsToOpen.balance
            destroy packsToOpen
            emit PacksBurned(amount: amountOpenedPacks)
            return <- WnW.createEmptyCollection()
        }

        // createNewPackMinter
        //
        // Function that creates and returns a new PackMinter resource
        //
        pub fun createNewPackMinter(allowedAmount: UFix64): @PackMinter {
            emit PackMinterCreated(allowedAmount: allowedAmount)
            return <-create PackMinter(allowedAmount: allowedAmount)
        }
    }

    // PackMinter
    //
    // Resource object that Pack admin accounts can hold to mint new Packs.
    //
    pub resource PackMinter {

        // The amount of Packs that the PackMinter is allowed to mint
        pub var allowedAmount: UFix64

        // mintPacks
        //
        // Function that mints new Packs, adds them to the total supply,
        // and returns them to the calling context.
        //
        pub fun mintPacks(amount: UFix64): @WnWAlphaPacks.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            WnWAlphaPacks.totalSupply = WnWAlphaPacks.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit PacksMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }


    init() {
        // path para guardar el recurso vault (se guarda en setup account)
        self.VaultStoragePath = /storage/WnWAlphaPacksVault
        // path para guardar el recurso Admin (se guarda aqui en init)
        self.AdminStoragePath = /storage/WnWAlphaPacksAdmin
        // paths para guardar las capabilities publicas (se guarda en setup)
        self.ReceiverPublicPath = /public/WnWAlphaPacksReceiver
        self.BalancePublicPath = /public/WnWAlphaPacksBalance
        // path pa la capability del opener
        self.PackOpenerPublicPath = /public/WnWAlphaPacksPackOpener
        
        // Initialize contract state.
        self.totalSupply = 0.0

        // Create the one true Admin object and deposit it into the conttract account.
        // es peor esto que crear una variable con el recurso y luego
        // mover el recurso al almacenamiento????
        self.account.save(<-create SetAdministrator(), to: self.AdminStoragePath)

        // Emit an event that shows that the contract was initialized.
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
 