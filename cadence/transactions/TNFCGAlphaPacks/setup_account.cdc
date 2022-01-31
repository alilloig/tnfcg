import FungibleToken from "../../contracts/FungibleToken.cdc"
import TNFCGAlphaPacks from "../../contracts/TNFCGAlphaPacks.cdc"

// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the Kibble

transaction {

    prepare(signer: AuthAccount) {

        if signer.borrow<&TNFCGAlphaPacks.Vault>(from: TNFCGAlphaPacks.VaultStoragePath) == nil {
            // Create a new Kibble Vault and put it in storage
            signer.save(<-TNFCGAlphaPacks.createEmptyVault(), to: TNFCGAlphaPacks.VaultStoragePath)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            signer.link<&TNFCGAlphaPacks.Vault{FungibleToken.Receiver}>(
                TNFCGAlphaPacks.ReceiverPublicPath,
                target: TNFCGAlphaPacks.VaultStoragePath
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            signer.link<&TNFCGAlphaPacks.Vault{FungibleToken.Balance}>(
                TNFCGAlphaPacks.BalancePublicPath,
                target: TNFCGAlphaPacks.VaultStoragePath
            )
        }
    }
}
