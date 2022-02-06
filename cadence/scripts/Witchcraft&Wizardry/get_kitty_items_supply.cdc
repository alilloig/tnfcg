import TNFCGCards from "../../contracts/TNFCGCards.cdc"

// This scripts returns the number of TNFCGCards currently in existence.

pub fun main(): UInt64 {    
    return TNFCGCards.totalSupply
}
