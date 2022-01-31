import FungibleToken from "../../contracts/FungibleToken.cdc"
import TNFCGAlphaPacks from "../../contracts/TNFCGAlphaPacks.cdc"
import TNFCGCards from "../../contracts/TNFCGCards.cdc"

transaction(recipient: Address, amount: UFix64) {
    let packsAdmin: &TNFCGAlphaPacks.Administrator
    let cardsAdmin: &TNFCGCards.Administrator
    let packsReceiver: &{FungibleToken.Receiver}
    // local variable for storing the minter reference
    let minter: &TNFCGCards.NFTMinter

    prepare(signer: AuthAccount) {
        
        //mete en tokenAdmin de la tx una capability de admin que este en signer, esta capability solo la tiene la cuenta que inicializo el contrato asi q si no panic
        self.packsAdmin = signer.borrow<&TNFCGAlphaPacks.Administrator>(from: TNFCGAlphaPacks.AdminStoragePath)
            ?? panic("Signer is not the packs admin")

        
        //mete en tokenAdmin de la tx una capability de admin que este en signer, esta capability solo la tiene la cuenta que inicializo el contrato asi q si no panic
        self.cardsAdmin = signer.borrow<&TNFCGCards.Administrator>(from: TNFCGCards.AdminStoragePath)
            ?? panic("Signer is not the cards admin")

        // borrow a reference to the NFTMinter resource in storage
        self.minter = signer.borrow<&TNFCGCards.NFTMinter>(from: TNFCGCards.MinterStoragePath)
            ?? panic("Could not borrow a reference to the NFT minter")

        //y con esto sacamos el recibidor de sobres del q los compra, o k
        //y aqui mete en tokenReceiver de la tx lacapability de recibir sobres del recipient
        self.packsReceiver = getAccount(recipient)
        .getCapability(TNFCGAlphaPacks.ReceiverPublicPath)!
        .borrow<&{FungibleToken.Receiver}>()
        ?? panic("Unable to borrow receiver reference")
    }

    execute {
        //y aqui ya se crea el minter
        let minter <- self.packsAdmin.createNewMinter(allowedAmount: amount)
        //con que el que se crea una Vault con N tokens (esto lo vamos a renombrar a packs a la de ya)
        let mintedVault <- minter.mintTokens(amount: amount)

        self.packsReceiver.deposit(from: <-mintedVault)

        destroy minter
    }
}
 