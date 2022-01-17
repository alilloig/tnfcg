import FungibleToken from "../../contracts/FungibleToken.cdc"
import TNFCGPacks from "../../contracts/TNFCGPacks.cdc"

// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the Kibble

transaction {

    prepare(signer: AuthAccount) {

        if signer.borrow<&TNFCGPacks.Vault>(from: TNFCGPacks.VaultStoragePath) == nil {
            // Create a new Kibble Vault and put it in storage
            signer.save(<-TNFCGPacks.createEmptyVault(), to: TNFCGPacks.VaultStoragePath)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            signer.link<&TNFCGPacks.Vault{FungibleToken.Receiver}>(
                TNFCGPacks.ReceiverPublicPath,
                target: TNFCGPacks.VaultStoragePath
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            signer.link<&TNFCGPacks.Vault{FungibleToken.Balance}>(
                TNFCGPacks.BalancePublicPath,
                target: TNFCGPacks.VaultStoragePath
            )
        }
    }
}
