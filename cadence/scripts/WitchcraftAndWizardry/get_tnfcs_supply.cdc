//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import WnW from 0xf8d6e0586b0a20c7

// This scripts returns the number of TNFCGCards currently in existence.

pub fun main(): UInt64 {    
    return WnW.totalSupply
}
