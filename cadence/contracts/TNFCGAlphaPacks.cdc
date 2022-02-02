import FungiblePack from "./FungiblePack.cdc"

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

// This will be a nice interface for any TNFCG Packs to implement
// when an interface is able to ""implement"" another one
//
pub contract TNFCGAlphaPacks: FungiblePack{
    // PacksInitialized
    //
    // The event that is emitted when the contract is created
    pub event PacksInitialized(initialSupply: UInt256)

    // PacksWithdrawn
    //
    // The event that is emitted when Packs are withdrawn from a Vault
    pub event PacksWithdrawn(amount: UInt256, from: Address?)

    // PacksDeposited
    //
    // The event that is emitted when Packs are deposited to a Vault
    pub event PacksDeposited(amount: UInt256, to: Address?)

    // PacksMinted
    //
    // The event that is emitted when new Packs are minted
    pub event PacksMinted(amount: UInt256)

    // PacksBurned
    //
    // The event that is emitted when Packs are destroyed
    pub event PacksBurned(amount: UInt256)

    // MinterCreated
    //
    // The event that is emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UInt256)

    // Named paths
    //
    pub let VaultStoragePath: StoragePath
    pub let ReceiverPublicPath: PublicPath
    pub let BalancePublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    // Total supply of Packs in existence
    pub var totalSupply: UInt256

    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungiblePack when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new Packs.
    //
    pub resource Vault: FungiblePack.Provider, FungiblePack.Receiver, FungiblePack.Balance {

        // The total balance of this vault
        pub var balance: UInt256

        // initialize the balance at resource creation time
        init(balance: UInt256) {
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
        pub fun withdraw(amount: UInt256): @FungiblePack.Vault {
            self.balance = self.balance - amount
            emit PacksWithdrawn(amount: amount, from: self.owner?.address)
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
        pub fun deposit(from: @FungiblePack.Vault) {
            let vault <- from as! @TNFCGAlphaPacks.Vault
            self.balance = self.balance + vault.balance
            emit PacksDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0
            destroy vault
        }

        destroy() {
            TNFCGAlphaPacks.totalSupply = TNFCGAlphaPacks.totalSupply - self.balance
            if(self.balance > 0) {
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
        return <-create Vault(balance: 0)
    }

    pub resource Administrator {

        // createNewMinter
        //
        // Function that creates and returns a new minter resource
        //
        pub fun createNewMinter(allowedAmount: UInt256): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }

        pub fun createNewPackOpener(allowedAmount: UInt256): @PackOpener {
            //emit??
            return <- create PackOpener(allowedAmount: allowedAmount)
        }
    }

    //PAckOpener
    //
    // ReResource object that Pack admin accounts can hold to receive packs and burn them
    // Los UFix hay que cambiarlos a enteros, no se valen decimales
    pub resource PackOpener {

        pub var allowedAmount: UInt256
        // openPacks
        //
        // Function that mints new Packs, adds them to the total supply,
        // and returns them to the calling context.
        //
        pub fun openPacks(amount: UInt256): @TNFCGAlphaPacks.Vault {
            pre {
                amount > 0: "Amount opened must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            TNFCGAlphaPacks.totalSupply = TNFCGAlphaPacks.totalSupply - amount
            self.allowedAmount = self.allowedAmount - amount
            emit PacksBurned(amount: amount)
            //como se queman los FT? pos en vez de ese return eso
            //y como se usa esto pa que se minteen X? pues creo q simplemente Cards tiene una funcion que llama N veces a minter
            return <-create Vault(balance: amount)
        }
        init(allowedAmount: UInt256) {
            self.allowedAmount = allowedAmount
        }

    }

    // Minter
    //
    // Resource object that Pack admin accounts can hold to mint new Packs.
    //
    pub resource Minter {

        // The amount of Packs that the minter is allowed to mint
        pub var allowedAmount: UInt256

        // mintPacks
        //
        // Function that mints new Packs, adds them to the total supply,
        // and returns them to the calling context.
        //
        pub fun mintPacks(amount: UInt256): @TNFCGAlphaPacks.Vault {
            pre {
                amount > 0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            TNFCGAlphaPacks.totalSupply = TNFCGAlphaPacks.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit PacksMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        init(allowedAmount: UInt256) {
            self.allowedAmount = allowedAmount
        }
    }

    init() {
        // path para guardar el recurso vault (se guarda en setup account)
        self.VaultStoragePath = /storage/TNFCGAlphaPacksVault
        // path para guardar el recurso Admin (se guarda aqui en init)
        self.AdminStoragePath = /storage/TNFCGAlphaPacksAdmin
        // paths para guardar las capabilities publicas (se guarda en setup)
        self.ReceiverPublicPath = /public/TNFCGAlphaPacksReceiver
        self.BalancePublicPath = /public/TNFCGAlphaPacksBalance
        
        // Initialize contract state.
        self.totalSupply = 0

        // Create the one true Admin object and deposit it into the conttract account.
        // es peor esto que crear una variable con el recurso y luego
        // mover el recurso al almacenamiento????
        self.account.save(<-create Administrator(), to: self.AdminStoragePath)

        // Emit an event that shows that the contract was initialized.
        emit PacksInitialized(initialSupply: self.totalSupply)
    }
}