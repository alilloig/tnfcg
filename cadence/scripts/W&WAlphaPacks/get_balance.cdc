import FungiblePack from 0xf8d6e0586b0a20c7//"../../contracts/FungiblePack.cdc"
import TNFCGAlphaPacks from 0xf8d6e0586b0a20c7 //"../../contracts/TNFCGAlphaPacks.cdc"

// This script returns an account's TNFCGAlphaPacks balance.

pub fun main(address: Address): UInt256 {
    let account = getAccount(address)
    
    let vaultRef = account.getCapability(TNFCGAlphaPacks.BalancePublicPath)!.borrow<&TNFCGAlphaPacks.Vault{FungiblePack.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}
