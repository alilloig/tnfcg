import FungibleToken from "../../contracts/FungibleToken.cdc"
import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
import WnWAlphaPacks from "../../contracts/WnWAlphaPacks.cdc"
import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
//import FungiblePack from 0xf8d6e0586b0a20c7
//import TNFCGAlphaPacks from 0xf8d6e0586b0a20c7

// This script returns an account's TNFCGAlphaPacks balance.

pub fun main(address: Address): UFix64 {
    let account = getAccount(address)
    
    let vaultRef = account.getCapability(WnWAlphaPacks.BalancePublicPath)!.borrow<&WnWAlphaPacks.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}
