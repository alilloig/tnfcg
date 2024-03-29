//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import WnW from 0xf8d6e0586b0a20c7
import TradingFungiblePack from 0xf8d6e0586b0a20c7

// This scripts returns the number of TNFCGCards currently in existence.
 
pub fun main(setID: UInt32): {UInt8: [UInt64]} {    
    let setData = WnW.getSetData(setID: setID) ?? panic ("Set does not exists")
    let mintedTNFCsIDsByRarity = setData.getMintedTNFCsIDsByRarity() ?? panic ("Set does not have any packs")
    return mintedTNFCsIDsByRarity
}
 