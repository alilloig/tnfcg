//import FungiblePack from "../../contracts/FungiblePack.cdc"
//import TNFCGAlphaPacks from "../../contracts/TNFCGAlphaPacks.cdc"
import TNFCGAlphaPacks from 0xf8d6e0586b0a20c7
import FungiblePack from 0xf8d6e0586b0a20c7

transaction(amount: UInt256, AdminAddress: Address) {
        
    // The Vault resource that holds the tokens that are being transferred
    let packsToOpenVault: @FungiblePack.Vault
    // The pack's owner account address
    let packsOwnerAccount: Address

    prepare(signer: AuthAccount){
        // Reference to the pack's owner vault
        let packsOwnerVaultRef = signer.borrow<&TNFCGAlphaPacks.Vault>(from: TNFCGAlphaPacks.VaultStoragePath)
			?? panic("Could not borrow reference to the owner's Vault!")
        // Withdraw packs from the signer's stored vault
        self.packsToOpenVault <- packsOwnerVaultRef.withdraw(amount: amount)
        // Stores the pack's owner address
        self.packsOwnerAccount = signer.address
    }

    execute {
        // Get the packs admin account's public account object
        let packAdminAccount = getAccount(AdminAddress)
        // Get a reference to the recipient's PackOpener
        let packOpenerRef = packAdminAccount.getCapability(TNFCGAlphaPacks.PackOpenerPublicPath)!.borrow<&{FungiblePack.PackOpener}>()
		?? panic("Could not borrow PackOpener reference to the recipient's Vault")
        // Deposit the withdrawn tokens in the recipient's PackOpener
        packOpenerRef.openPacks(packsToOpen: <-self.packsToOpenVault, packOwner: self.packsOwnerAccount)
    }
}
 