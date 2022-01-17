import FungibleToken from "../../contracts/FungibleToken.cdc"
import TNFCGPacks from "../../contracts/TNFCGPacks.cdc"

transaction(recipient: Address, amount: UFix64) {
    let tokenAdmin: &TNFCGPacks.Administrator
    let tokenReceiver: &{FungibleToken.Receiver}

    prepare(signer: AuthAccount) {
        //esto es para comprobar que el que esta minteando packs es el admin de los packs, o k
        self.tokenAdmin = signer
        .borrow<&TNFCGPacks.Administrator>(from: TNFCGPacks.AdminStoragePath)
        ?? panic("Signer is not the token admin")

        //y con esto sacamos el recibidor de sobres del q los compra, o k
        self.tokenReceiver = getAccount(recipient)
        .getCapability(TNFCGPacks.ReceiverPublicPath)!
        .borrow<&{FungibleToken.Receiver}>()
        ?? panic("Unable to borrow receiver reference")
    }

    execute {
        //y aqui ya se crea el minter
        let minter <- self.tokenAdmin.createNewMinter(allowedAmount: amount)
        //con que el que se crea una Vault con N tokens (esto lo vamos a renombrar a packs a la de ya)
        let mintedVault <- minter.mintTokens(amount: amount)

        self.tokenReceiver.deposit(from: <-mintedVault)

        destroy minter
    }
}
