//import FungiblePack from "../../contracts/FungiblePack.cdc"
import FungiblePack from 0xf8d6e0586b0a20c7
//import TNFCGAlphaPacks from "../../contracts/TNFCGAlphaPacks.cdc"
import TNFCGAlphaPacks from 0xf8d6e0586b0a20c7

// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the Alpha Packs

transaction {
    let packsAdmin: &TNFCGAlphaPacks.Administrator

    prepare(signer: AuthAccount) {

        //Te quedas loco que esta es toda la autenticación
        self.packsAdmin = signer.borrow<&TNFCGAlphaPacks.Administrator>(from: TNFCGAlphaPacks.AdminStoragePath)
            ?? panic("Signer is not the packs admin")

        if signer.borrow<&TNFCGAlphaPacks.Vault>(from: TNFCGAlphaPacks.VaultStoragePath) == nil {
            // Create a new Pack Vault and put it in storage
            signer.save(<-TNFCGAlphaPacks.createEmptyVault(), to: TNFCGAlphaPacks.VaultStoragePath)
            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            signer.link<&TNFCGAlphaPacks.Vault{FungiblePack.Receiver}>(
                TNFCGAlphaPacks.ReceiverPublicPath,
                target: TNFCGAlphaPacks.VaultStoragePath
            )
            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            signer.link<&TNFCGAlphaPacks.Vault{FungiblePack.Balance}>(
                TNFCGAlphaPacks.BalancePublicPath,
                target: TNFCGAlphaPacks.VaultStoragePath
            )
        }
        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&TNFCGAlphaPacks.Administrator{FungiblePack.PackOpener}>(
                TNFCGAlphaPacks.PackOpenerPublicPath, 
                target: TNFCGAlphaPacks.AdminStoragePath)
    }
}